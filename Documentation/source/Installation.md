Installation
=============================

Gini Vision Library can either be installed by using CocoaPods or by manually dragging the required files to your project.

**Note**: Irrespective of the option you choose if you want to support **iOS 10** you need to specify the `NSCameraUsageDescription` key in your `Info.plist` file. This key is mandatory for all apps since iOS 10 when using the `Camera` framework. Also if you're using the [Gini iOS SDK](https://github.com/gini/gini-sdk-ios) you need to add support for "Keychain Sharing" in your entitlements by adding a `keychain-access-groups` value to your entitlements file. For more information see the [Integration Guide](http://developer.gini.net/gini-sdk-ios/docs/guides/getting-started.html#integrating-the-gini-sdk) of the Gini iOS SDK.

## Swift versions

The Gini Vision Library is entirely (re-)written in **Swift 3**. **Swift 2.3** support can be found in a separate branch or the `2.3.3-beta` release. Please keep in mind that these versions are deprecated and will not receive any new features or bug fixes.

The last **Swift 2.2** release is `2.0.3`.

If you use CocoaPods you can specify a branch with:

```ruby
pod 'GiniVision', :git => 'https://github.com/gini/gini-vision-lib-ios.git', :branch => 'swift-2.3' # or use 'swift3'
```

## CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build Gini Vision Library.


To integrate Gini Vision Library into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/gini/gini-podspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

pod "GiniVision"
```

**Note:** You need to add Gini's podspec repository as a source.

Then run the following command:

```bash
$ pod install
```

## Manually

If you prefer not to use a dependency management tool, you can integrate the Gini Vision Library into your project manually.
To do so drop the GiniVision (classes and assets) folder into your project and add the files to your target.

Xcode will automatically check your project for swift files and will create an autogenerated import header for you.
Use this header in an Objective-C project by adding

```Obj-C
#import "YourProjectName-Swift.h"
```

to your implementation or header files. Note that spaces in your project name result in underscores. So `Your Project` becomes `Your_Project-Swift.h`.
