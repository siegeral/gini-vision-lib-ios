//
//  ToolTipView.swift
//  GiniVision
//
//  Created by Enrique del Pozo Gómez on 9/21/17.
//

import Foundation
import UIKit

final class ToolTipView: UIView {
    
    enum ToolTipPosition {
        case above
        case below
        case left
        case right
    }
    
    fileprivate var arrowWidth:CGFloat = 20
    fileprivate var arrowHeight:CGFloat = 20
    fileprivate var closeButtonWidth:CGFloat = 20
    fileprivate var closeButtonHeight:CGFloat = 20
    fileprivate var closeButtonColor:UIColor = UIColor(red: 175 / 255, green: 178 / 255, blue: 179 / 255, alpha: 1)
    fileprivate var itemSeparation: CGFloat = 16
    fileprivate var margin:(top:CGFloat, left:CGFloat, right: CGFloat, bottom: CGFloat) = (20, 20, 20, 20)
    fileprivate var maxWidthOnIpad:CGFloat = 375
    fileprivate var padding:(top:CGFloat, left:CGFloat, right: CGFloat, bottom: CGFloat) = (16, 16, 16, 16)
    
    fileprivate var textWidth:CGFloat {
        guard let superview = superview else { return 0 }
        if UIDevice.current.isIpad {
            return maxWidthOnIpad - padding.left - padding.right - margin.left - margin.right - closeButtonWidth - itemSeparation
        } else {
            return superview.frame.width - padding.left - padding.right - margin.left - margin.right - closeButtonWidth - itemSeparation
        }
    }
    
    fileprivate var text:String
    fileprivate var toolTipPosition:ToolTipPosition
    fileprivate var textSize:CGSize = .zero
    
    fileprivate var arrowView:UIView
    fileprivate var closeButton:UIButton
    fileprivate let referenceView:UIView
    fileprivate var textLabel:UILabel
    fileprivate var tipContainer: UIView
    
    var beforeDismiss: (() -> ())?
    
    init(text:String, font:UIFont = UIFont.systemFont(ofSize: 14), backgroundColor: UIColor = .white, referenceView: UIView, superView:UIView, position: ToolTipPosition) {

        self.text = text
        self.referenceView = referenceView
        self.toolTipPosition = position
        self.textLabel = UILabel()
        self.closeButton = UIButton()
        self.tipContainer = UIView()
        self.arrowView = ToolTipView.arrow(withHeight: arrowHeight, width: arrowWidth, color: .white, position: position)
        
        super.init(frame: .zero)
        superView.addSubview(self)
        alpha = 0

        self.textSize = size(forText: text, withFont: font)
        self.addTipContainer(backgroundColor: backgroundColor)
        self.addTextLabel(withText: text, font: font)
        self.addCloseButton()
        self.addArrow()
        self.addShadow()
        
        self.arrangeFrame(withSuperView: superView)
        self.arrangeArrow(withSuperView: superView)
        self.setupConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.arrangeArrow(withSuperView: superview)
    }
    
    func arrangeViews() {
        self.arrangeFrame(withSuperView: superview)
        self.arrangeArrow(withSuperView: superview)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported. Use init(text) instead!")
    }
    
    // MARK: Add views
    fileprivate func addTipContainer(backgroundColor color:UIColor) {
        self.addSubview(tipContainer)
        self.tipContainer.backgroundColor = color
    }
    
    fileprivate func addTextLabel(withText text:String, font:UIFont) {
        textLabel.text = text
        textLabel.font = font
        textLabel.numberOfLines = 0
        tipContainer.addSubview(textLabel)
    }
    
    fileprivate func addArrow() {
        arrowView.frame.origin = CGPoint(x: 0, y: self.frame.height)
        self.addSubview(arrowView)
    }
    
    fileprivate func addCloseButton() {
        let image = UIImageNamedPreferred(named: "toolTipCloseButton")
        closeButton.setImage(image, for: .normal)
        closeButton.tintColor = closeButtonColor
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        tipContainer.addSubview(closeButton)
    }
    
    fileprivate func addShadow() {
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 0.8
        self.layer.shadowOpacity = 0.2
        self.layer.shadowColor = UIColor.black.cgColor
    }
    
    // MARK: Arrange views
    fileprivate func arrangeFrame(withSuperView superView:UIView?) {
        guard let superview = superView, let referenceViewAbsoluteFrame = absoluteFrame(for: referenceView, inside: superView) else { return }
        let frameHeight = max(textSize.height, closeButtonHeight) + padding.top + padding.bottom + margin.top + margin.bottom
        let frameWidth = textSize.width + closeButtonWidth + padding.left + padding.right + itemSeparation + margin.left + margin.right
        let size = CGSize(width: frameWidth, height: frameHeight)
        
        var x:CGFloat = 0
        var y:CGFloat = 0
        switch toolTipPosition {
        case .above:
            if referenceViewAbsoluteFrame.origin.y - size.height < 0 {
                assertionFailure("The tip cannot be shown outside the parent view")
            } else {
                x = referenceViewAbsoluteFrame.origin.x + referenceViewAbsoluteFrame.size.width - size.width
                y = referenceViewAbsoluteFrame.origin.y - size.height
            }
        case .below:
            if referenceViewAbsoluteFrame.origin.y + referenceView.frame.height + size.height > superview.frame.height {
                assertionFailure("The tip cannot be shown outside the super view")
            } else {
                x = referenceViewAbsoluteFrame.origin.x + referenceViewAbsoluteFrame.size.width - size.width
                y = referenceViewAbsoluteFrame.origin.y + referenceView.frame.height
            }
        case .left:
            if referenceViewAbsoluteFrame.origin.x - size.width < 0 {
                assertionFailure("The tip cannot be shown outside the super view")
            } else {
                x = referenceViewAbsoluteFrame.origin.x - size.width
                y = referenceViewAbsoluteFrame.origin.y - margin.top
            }
        case .right:
            if referenceViewAbsoluteFrame.origin.x + referenceView.frame.width + size.width > superview.frame.width {
                assertionFailure("The tip cannot be shown outside the super view")
            } else {
                x = referenceViewAbsoluteFrame.origin.x  - size.width
                y = referenceViewAbsoluteFrame.origin.y - margin.top
            }
        }
        
        if x < 0 || superview.frame.width - x < size.width {
            x = superview.frame.width - size.width
        }
        
        if superview.frame.height - y < size.height {
            y = referenceViewAbsoluteFrame.origin.y + referenceViewAbsoluteFrame.height - size.height
        }
        
        self.frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
    
    fileprivate func arrangeArrow(withSuperView superView:UIView?) {
        guard let referenceViewAbsoluteFrame = absoluteFrame(for: referenceView, inside: superView) else { return }
        
        let x:CGFloat
        let y:CGFloat
        switch toolTipPosition {
        case .above:
            x = referenceViewAbsoluteFrame.origin.x + referenceView.frame.width / 2 - self.frame.origin.x - arrowView.frame.width / 2
            y = tipContainer.frame.height + tipContainer.frame.origin.y
        case .below:
            x = referenceViewAbsoluteFrame.origin.x + referenceView.frame.width / 2 - self.frame.origin.x - arrowView.frame.width / 2
            y = 0
        case .left:
            x = tipContainer.frame.width + tipContainer.frame.origin.x
            y = referenceViewAbsoluteFrame.origin.y + referenceView.frame.height / 2 - self.frame.origin.y - arrowView.frame.width / 2
        case .right:
            x = 0
            y = referenceViewAbsoluteFrame.origin.y + referenceView.frame.height / 2 - self.frame.origin.y - arrowView.frame.width / 2
        }
        arrowView.frame.origin = CGPoint(x: x, y: y)
    }
    
    // MARK: Actions
    @objc fileprivate func closeAction() {
        self.dismiss(withCompletion: nil)
    }
    
    // MARK: Frame and size calculations
    fileprivate func size(forText text: String, withFont font:UIFont) -> CGSize {
        let attributes = [NSFontAttributeName : font]
        
        var textSize = text.boundingRect(with: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil).size
        
        textSize.width = textWidth
        textSize.height = ceil(textSize.height)
        
        return textSize
    }
    
    fileprivate func absoluteFrame(for view:UIView, inside superView:UIView?) -> CGRect? {
        guard let superView = superView, let referenceViewParent = referenceView.superview else { return nil }
        
        return referenceViewParent.convert(referenceView.frame, to: superView)
    }
    
    // MARK: Constraints
    fileprivate func setupConstraints() {
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        tipContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // tipContainer
        self.addConstraints([
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: tipContainer, attribute: .top, multiplier: 1, constant: -margin.top),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: tipContainer, attribute: .bottom, multiplier: 1, constant: margin.bottom),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: tipContainer, attribute: .leading, multiplier: 1, constant: -margin.left),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: tipContainer, attribute: .trailing, multiplier: 1, constant: margin.right)
            ])
        
        // textLabel
        self.addConstraints([
            NSLayoutConstraint(item: tipContainer, attribute: .top, relatedBy: .equal, toItem: textLabel, attribute: .top, multiplier: 1, constant: -padding.top),
            NSLayoutConstraint(item: tipContainer, attribute: .bottom, relatedBy: .equal, toItem: textLabel, attribute: .bottom, multiplier: 1, constant: padding.bottom),
            NSLayoutConstraint(item: tipContainer, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .leading, multiplier: 1, constant: -padding.left)
            ])
        
        // closeButton
        self.addConstraints([
            NSLayoutConstraint(item: closeButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: closeButtonWidth),
            NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: closeButtonHeight),
            NSLayoutConstraint(item: closeButton, attribute: .centerY, relatedBy: .equal, toItem: tipContainer, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: closeButton, attribute: .leading, relatedBy: .equal, toItem: textLabel, attribute: .trailing, multiplier: 1, constant: itemSeparation),
            NSLayoutConstraint(item: tipContainer, attribute: .trailing, relatedBy: .equal, toItem: closeButton, attribute: .trailing, multiplier: 1, constant: padding.right)
            ])
        
        self.setNeedsLayout()
    }
    
    // MARK: Draw arrow
    class fileprivate func arrow(withHeight height:CGFloat, width:CGFloat, color:UIColor, position:ToolTipPosition) -> UIView {
        let arrowView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        arrowView.backgroundColor = color
        
        let bezierPath = UIBezierPath()
        
        switch position {
        case .above:
            bezierPath.move(to: CGPoint(x: 0, y: 0))
            bezierPath.addLine(to: CGPoint(x: width, y: 0))
            bezierPath.addLine(to: CGPoint(x: width / 2, y: height))
            bezierPath.addLine(to: CGPoint(x: 0, y: 0))
        case .below:
            bezierPath.move(to: CGPoint(x: 0, y: height))
            bezierPath.addLine(to: CGPoint(x: width, y: height))
            bezierPath.addLine(to: CGPoint(x: width / 2, y: 0))
            bezierPath.addLine(to: CGPoint(x: 0, y: height))
        case .left:
            bezierPath.move(to: CGPoint(x: 0, y: 0))
            bezierPath.addLine(to: CGPoint(x: height, y: width / 2))
            bezierPath.addLine(to: CGPoint(x: 0, y: width))
            bezierPath.addLine(to: CGPoint(x: 0, y: 0))
        case .right:
            bezierPath.move(to: CGPoint(x: height, y: 0))
            bezierPath.addLine(to: CGPoint(x: 0, y: width / 2))
            bezierPath.addLine(to: CGPoint(x: height, y: width))
            bezierPath.addLine(to: CGPoint(x: height, y: 0))
        }
        bezierPath.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        arrowView.layer.mask = shapeLayer
        return arrowView
    }
}

// MARK: Show and hide tip methods

extension ToolTipView {
    
    func show(animations:(() -> ())? = nil){
        UIView.animate(withDuration: 0.3){
            self.alpha = 1
            animations?()
        }
    }
    
    func dismiss(withCompletion completion: (() -> ())? = nil) {
        beforeDismiss?()
        self.removeFromSuperview()
        completion?()
    }
}


