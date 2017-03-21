//
//  SwiftColorPickerViewController.swift
//  iOSColorPicker
//
//  Created by Christian Zimmermann on 02.03.15.
//  Copyright (c) 2015 Christian Zimmermann. All rights reserved.
//

// Note: The 'public' infront of the classe and property declaration is needed, 
//       because the ViewController and the View is part of an framework.

import UIKit

public protocol SwiftColorPickerDelegate
{
    func colorSelectionChanged(selectedColor color: UIColor)
}

/// Color Picker ViewController. Let the user pick a color from a 2D color palette.
/// The delegate (SwiftColorPickerDelegate) will be notified about the color selection change.
/// The user can simply tap a color or pan over the palette. When panning over the palette a round preview
/// view will appear and show the current selected colot.
open class SwiftColorPickerViewController: UIViewController
{
    /// Delegate of the SwiftColorPickerViewController
    open var delegate: SwiftColorPickerDelegate?
    
    /// Width of the edge around the color palette.
    /// The border change the color with the selection by the user. 
    /// Default is 10
    open var coloredBorderWidth:Int = 10 {
        didSet {
            colorPaletteView.coloredBorderWidth = coloredBorderWidth
        }
    }
    
    /// Diameter of the circular view, which preview the color selection.
    /// The preview will apear at the fimnger tip of the users touch and show se current selected color.
    open var colorPreviewDiameter:Int = 35 {
        didSet {
            setConstraintsForColorPreView()
        }
    }
    
    /// Number of color blocks in x-direction.
    /// Color palette size is numberColorsInXDirection * numberColorsInYDirection
    open var numberColorsInXDirection: Int = 10 {
        didSet {
            colorPaletteView.numColorsX = numberColorsInXDirection
        }
    }
    
    /// Number of color blocks in x-direction.
    /// Color palette size is numberColorsInXDirection * numberColorsInYDirection
    open var numberColorsInYDirection: Int = 18 {
        didSet {
            colorPaletteView.numColorsY = numberColorsInYDirection
        }
    }
    
    fileprivate var colorPaletteView: SwiftColorView = SwiftColorView() // is the self.view property
    fileprivate var colorSelectionView: UIView = UIView()
    
    fileprivate var selectionViewConstraintX: NSLayoutConstraint = NSLayoutConstraint()
    fileprivate var selectionViewConstraintY: NSLayoutConstraint = NSLayoutConstraint()
    
    
    public required override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func loadView()
    {
        super.loadView()
        if ( !(self.view is SwiftColorView) ) // used if the view controller ist instanciated without interface builder
        {
            let s = colorPaletteView
            s.translatesAutoresizingMaskIntoConstraints = false
            s.contentMode = UIViewContentMode.redraw
            s.isUserInteractionEnabled = true
            self.view = s
        }
        else // used if in intervacebuilder the view property is set to the SwiftColorView
        {
            colorPaletteView = self.view as! SwiftColorView
        }
        coloredBorderWidth = colorPaletteView.coloredBorderWidth
        numberColorsInXDirection = colorPaletteView.numColorsX
        numberColorsInYDirection = colorPaletteView.numColorsY
        
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // needed when using auto layout
        colorSelectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // add subviews
        colorPaletteView.addSubview(colorSelectionView)
        // set autolayout constraints
        setConstraintsForColorPreView()
        
        // setup preview
        colorSelectionView.layer.masksToBounds = true
        colorSelectionView.layer.borderWidth = 0.5
        colorSelectionView.layer.borderColor = UIColor.gray.cgColor
        colorSelectionView.alpha = 0.0
        
        
        // adding gesture regocnizer
        let tapGr = UITapGestureRecognizer(target: self, action: #selector(SwiftColorPickerViewController.handleGestureRecognizer(_:)))
        let panGr = UIPanGestureRecognizer(target: self, action: #selector(SwiftColorPickerViewController.handleGestureRecognizer(_:)))
        panGr.maximumNumberOfTouches = 1
        colorPaletteView.addGestureRecognizer(tapGr)
        colorPaletteView.addGestureRecognizer(panGr)
    }
    
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches as Set<UITouch>, with: event)
        
        if let touch = touches.first
        {
            let t = touch
            let point = t.location(in: colorPaletteView)
            positionSelectorViewWithPoint(point)
            colorSelectionView.alpha = 1.0
        }
        
    }
    
    func handleGestureRecognizer(_ recognizer: UIGestureRecognizer)
    {
        let point = recognizer.location(in: self.colorPaletteView)
        positionSelectorViewWithPoint(point)
        if (recognizer.state == UIGestureRecognizerState.began)
        {
            colorSelectionView.alpha = 1.0
        }
        else if (recognizer.state == UIGestureRecognizerState.ended)
        {
            startHidingSelectionView()
        }
    }

    fileprivate func setConstraintsForColorPreView()
    {
        colorPaletteView.removeConstraints(colorPaletteView.constraints)
        colorSelectionView.layer.cornerRadius = CGFloat(colorPreviewDiameter/2)
        let views = ["paletteView": self.colorPaletteView, "selectionView": colorSelectionView]
        
        var pad = 10
        if (colorPreviewDiameter==10)
        {
            pad = 13
        }
        
        let metrics = ["diameter" : colorPreviewDiameter, "pad" : pad]
        
        let constH2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-pad-[selectionView(diameter)]", options: [], metrics: metrics, views: views)
        let constV2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-pad-[selectionView(diameter)]", options: [], metrics: metrics, views: views)
        colorPaletteView.addConstraints(constH2)
        colorPaletteView.addConstraints(constV2)
        
        for constraint in constH2
        {
            if constraint.constant == CGFloat(pad)
            {
                selectionViewConstraintX = constraint 
                break
            }
        }
        for constraint in constV2
        {
            if constraint.constant == CGFloat(pad)
            {
                selectionViewConstraintY = constraint 
                break
            }
        }
    }
    
    fileprivate func positionSelectorViewWithPoint(_ point: CGPoint)
    {
        let colorSelected = colorPaletteView.colorAtPoint(point)
        delegate?.colorSelectionChanged(selectedColor: colorSelected)
        self.view.backgroundColor = colorSelected
        colorSelectionView.backgroundColor = colorPaletteView.colorAtPoint(point)
        selectionViewConstraintX.constant = (point.x-colorSelectionView.bounds.size.width/2)
        selectionViewConstraintY.constant = (point.y-1.2*colorSelectionView.bounds.size.height)
    }
    
    fileprivate func startHidingSelectionView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.colorSelectionView.alpha = 0.0
        })
    }
}

@IBDesignable open class SwiftColorView: UIView
{
    /// Number of color blocks in x-direction.
    /// Color palette size is numColorsX * numColorsY
    @IBInspectable open var numColorsX:Int =  10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Number of color blocks in x-direction.
    /// Color palette size is numColorsX * numColorsY
    @IBInspectable open var numColorsY:Int = 18 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Width of the edge around the color palette.
    /// The border change the color with the selection by the user.
    /// Default is 10
    @IBInspectable open var coloredBorderWidth:Int = 10 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable open var showGridLines:Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    open override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        let lineColor = UIColor.gray
        let pS = patternSize()
        let w = pS.w
        let h = pS.h
        
        for y in 0..<numColorsY
        {
            for x in 0..<numColorsX
            {
                let path = UIBezierPath()
                let start = CGPoint(x: CGFloat(x)*w+CGFloat(coloredBorderWidth),y: CGFloat(y)*h+CGFloat(coloredBorderWidth))
                path.move(to: start);
                path.addLine(to: CGPoint(x: start.x+w, y: start.y))
                path.addLine(to: CGPoint(x: start.x+w, y: start.y+h))
                path.addLine(to: CGPoint(x: start.x, y: start.y+h))
                path.addLine(to: start)
                path.lineWidth = 0.25
                colorForRectAt(x,y:y).setFill();
                
                if (showGridLines)
                {
                    lineColor.setStroke()
                }
                else
                {
                    colorForRectAt(x,y:y).setStroke();
                }
                path.fill();
                path.stroke();
            }
        }
    }
    
    fileprivate func colorForRectAt(_ x: Int, y: Int) -> UIColor
    {
        var hue:CGFloat = CGFloat(x) / CGFloat(numColorsX)
        var fillColor = UIColor.white
        if (y==0)
        {
            if (x==(numColorsX-1))
            {
                hue = 1.0;
            }
            fillColor = UIColor(white: hue, alpha: 1.0);
        }
        else
        {
            let sat:CGFloat = CGFloat(1.0)-CGFloat(y-1) / CGFloat(numColorsY)
            fillColor = UIColor(hue: hue, saturation: sat, brightness: 1.0, alpha: 1.0)
        }
        return fillColor
    }
    
    func colorAtPoint(_ point: CGPoint) -> UIColor
    {
        let pS = patternSize()
        let w = pS.w
        let h = pS.h
        
        let x = (point.x-CGFloat(coloredBorderWidth))/w
        let y = (point.y-CGFloat(coloredBorderWidth))/h
        return colorForRectAt(Int(x), y:Int(y))
    }
    
    fileprivate func patternSize() -> (w: CGFloat, h:CGFloat)
    {
        let width = self.bounds.width-CGFloat(2*coloredBorderWidth)
        let height = self.bounds.height-CGFloat(2*coloredBorderWidth)
        
        let w = width/CGFloat(numColorsX)
        let h = height/CGFloat(numColorsY)
        return (w,h)
    }
    
    open override func prepareForInterfaceBuilder()
    {
        print("Compiled and run for IB")
    }
    
}

