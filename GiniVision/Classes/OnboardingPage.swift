//
//  OnboardingPage.swift
//  GiniVision
//
//  Created by Peter Pult on 24/06/16.
//  Copyright © 2016 Gini GmbH. All rights reserved.
//

import UIKit

/**
 Custom view to easily create onboarding pages which can then be used in `OnboardingViewController`. Simply pass an image and a name. Both will be beautifully aligned and displayed to the user.
 
 - note: The text length should not exceed 50 characters, depending on the font used, and should preferably stretch out over three lines.
 */
@objc public final class OnboardingPage: UIView {
    
    fileprivate var contentView = UIView()
    fileprivate var imageView = UIImageView()
    fileprivate var textLabel = UILabel()
    fileprivate var needsToRotateImageInLandscape: Bool = false
    
    /**
     Designated initializer for the `OnboardingPage` class which allows to create a custom onboarding page just by passing an image and a text. The text will be displayed underneath the image.
     
     - parameter image: The image to be displayed.
     - parameter text:  The text to be displayed underneath the image.
     
     - returns: A simple custom view to be displayed in the onboarding.
     */
    public init(image: UIImage, text: String, rotateImageInLandscape: Bool = false) {
        super.init(frame: CGRect.zero)
        
        // Set image and text
        imageView.image = image
        textLabel.text = text
        needsToRotateImageInLandscape = rotateImageInLandscape

        // Configure label
        textLabel.numberOfLines = 0
        textLabel.textColor = GiniConfiguration.sharedConfiguration.onboardingTextColor
        textLabel.textAlignment = .center
        textLabel.font = GiniConfiguration.sharedConfiguration.customFont == nil ?
            GiniConfiguration.sharedConfiguration.onboardingTextFont :
            GiniConfiguration.sharedConfiguration.font.thin.withSize(28)
        
        // Configure view hierachy
        addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(textLabel)
        
        // Add constraints
        addConstraints()
    }
    
    /**
     Convenience initializer for the `OnboardingPage` class which allows to create a custom onboarding page simply by passing an image name and a text. The text will be displayed underneath the image.
     
     - parameter imageName: The name of the image to be displayed.
     - parameter text:      The text to be displayed underneath the image.
     
     - returns: A simple custom view to be displayed in the onboarding or `nil` when no image with the given name could be found.
     */
    public convenience init?(imageNamed imageName: String, text: String, rotateImageInLandscape: Bool = false) {
        guard let image = UIImageNamedPreferred(named: imageName) else { return nil }
        self.init(image: image, text: text, rotateImageInLandscape: rotateImageInLandscape)
    }
    
    /**
     Returns an object initialized from data in a given unarchiver.
     
     - warning: Not implemented.
     */
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if needsToRotateImageInLandscape {
            let rotationAngle:CGFloat = frame.width > frame.height ? -.pi / 2 : 0.0
            imageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
    }
    
    // MARK: Constraints
    fileprivate func addConstraints() {
        let superview = self
            
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        Contraints.active(item: contentView, attr: .top, relatedBy: .greaterThanOrEqual, to: superview, attr: .top, constant: 30)
        Contraints.active(item: contentView, attr: .centerX, relatedBy: .equal, to: superview, attr: .centerX)
        Contraints.active(item: contentView, attr: .centerY, relatedBy: .equal, to: superview, attr: .centerY, constant: 5, priority: 999)
    
        // Image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        Contraints.active(item: imageView, attr: .top, relatedBy: .equal, to: contentView, attr: .top)
        Contraints.active(item: imageView, attr: .width, relatedBy: .lessThanOrEqual, to: nil, attr: .width, constant: 612)
        Contraints.active(item: imageView, attr: .width, relatedBy: .greaterThanOrEqual, to: nil, attr: .width, constant: 75)
        Contraints.active(item: imageView, attr: .height, relatedBy: .lessThanOrEqual, to: nil, attr: .height, constant: 360)
        Contraints.active(item: imageView, attr: .height, relatedBy: .greaterThanOrEqual, to: nil, attr: .height, constant: 100)
        Contraints.active(item: imageView, attr: .centerX, relatedBy: .equal, to: contentView, attr: .centerX)

        // Text label
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        Contraints.active(item: textLabel, attr: .top, relatedBy: .equal, to: imageView, attr: .bottom, constant: 35)
        Contraints.active(item: textLabel, attr: .trailing, relatedBy: .equal, to: contentView, attr: .trailing)
        Contraints.active(item: textLabel, attr: .bottom, relatedBy: .equal, to: contentView, attr: .bottom)
        Contraints.active(item: textLabel, attr: .leading, relatedBy: .equal, to: contentView, attr: .leading)
        Contraints.active(item: textLabel, attr: .width, relatedBy: .equal, to: superview, attr: .width, multiplier: 2/3)
        Contraints.active(item: textLabel, attr: .height, relatedBy: .greaterThanOrEqual, to: nil, attr: .height, constant: 70)
    }
    
}
