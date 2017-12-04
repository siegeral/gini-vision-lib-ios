import XCTest
@testable import GiniVision

class CameraViewControllerTests: XCTestCase {
    
    var vc: CameraViewController!
    
    func testInitialization() {
        vc = CameraViewController(successBlock: { _ in }, failureBlock: { _ in })
        XCTAssertNotNil(vc, "view controller should not be nil")
    }
    
    func testTooltipWhenFileImportDisabled() {
        ToolTipView.shouldShowFileImportToolTip = true
        GiniConfiguration.sharedConfiguration.fileImportSupportedTypes = .none
        
        vc = CameraViewController(successBlock: { _ in }, failureBlock: { _ in })
        _ = vc.view
        
        XCTAssertNil(vc.toolTipView, "ToolTipView should not be created when file import is disabled.")
        
    }
    
    func testCaptureButtonDisabledWhenToolTipIsShown() {
        ToolTipView.shouldShowFileImportToolTip = true
        GiniConfiguration.sharedConfiguration.fileImportSupportedTypes = .pdf_and_images
        
        // Disable onboarding on launch
        GiniConfiguration.sharedConfiguration.onboardingShowAtLaunch = false
        GiniConfiguration.sharedConfiguration.onboardingShowAtFirstLaunch = false
        
        vc = CameraViewController(successBlock: { _ in }, failureBlock: { _ in })
        _ = vc.view
        
        XCTAssertFalse(vc.captureButton.isEnabled, "capture button should be disaled when tooltip is shown")
        
    }
    
    func testCaptureImage() {
        let expect = expectation(description: "image is captured")
        vc = CameraViewController(successBlock: { document in
            XCTAssertTrue(document.type == .image, "document should be an image")
            expect.fulfill()
        }, failureBlock: { _ in
            XCTFail()
            expect.fulfill()
        })
        
        _ = vc.view
        vc.viewWillAppear(true)
        vc.captureButton.sendActions(for: .touchUpInside)
        
        waitForExpectations(timeout: 5.0) { error in
            if let error = error {
                XCTFail("An error ocurried when capturing image: \(error)")
            }
        }
    }
}

