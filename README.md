# A11yUITests

[![Version](https://img.shields.io/cocoapods/v/A11yUITests.svg?style=flat)](https://cocoapods.org/pods/A11yUITests)
[![License](https://img.shields.io/cocoapods/l/A11yUITests.svg?style=flat)](https://cocoapods.org/pods/A11yUITests)
[![Platform](https://img.shields.io/cocoapods/p/A11yUITests.svg?style=flat)](https://cocoapods.org/pods/A11yUITests)
[![Twitter](https://img.shields.io/twitter/follow/MobileA11y?style=flat)](https://twitter.com/mobilea11y)

**⚠️ This library is no longer maintained and you probably shouldn't use it. ⚠️**

Instead consider using one or more of these tools that, tbh, do a better job.
* [AccessibilitySnapshot](https://github.com/cashapp/AccessibilitySnapshot) - An accessibility snapshot testing library that can cover more than this approach is able to.
* [Reveal](https://revealapp.com) - An inspector that can provide you a visual representation of your app's accessibility and more. 

A11yTests is an extension to `XCTestCase` that adds tests for common accessibility issues that can be run as part of an XCUI Test suite.

Tests can either be run separately or integrated into existing XCUI Tests.

## Using These Tests

Good accessibility is not about ticking boxes and conforming to regulations and guidelines, but about how your app is experienced. You will only ever know if your app is actually accessible by letting real people use it. Consider these tests as hints for where you might be able to do better, and use them to detect regressions.

Failures for these tests should be seen as warnings for further investigation, not strict failures. As such i'd recommend always having `continueAfterFailure = true` set.

The library has two types of tests - [assertions](#assertion-tests) and [snapshots](#snapshot-tests).
Assertion tests check each individual element for potential accessibility failures.
Snapshot tests creates a snapshot of your app's accessibility tree and stores this as a reference for future tests. If something changes in the accessibility tree in a future test, the test will fail signifying you should validate the change. No assertions are made against the accessibility tree, only a check for any changes since the last snapshot state.

Failures have two categories: Warning and Failure.
Failures are fails against WCAG or the HIG. Warnings may be acceptable, but require investigation.

add `import A11yUITests` to the top of your test file.


## Assertion tests

Assertion tests check each individual element for potential accessibility failures.

### Running Tests

Tests can be run individually or in suites.

#### Running All Tests on All Elements

```swift
func test_allTests() {
    XCUIApplication().launch()
    a11yCheckAllOnScreen()
}
```

#### Specifying Tests/Elements

To specify elements and tests use  `a11y(tests: [A11yTests], on elements: [XCUIElement])` passing an array of tests to run and an array of elements to run them on. To run all interactive element tests on all buttons:

```swift
func test_buttons() {
    let buttons = XCUIApplication().buttons.allElementsBoundByIndex
    a11y(tests: a11yTestSuiteInteractive, on: buttons)
}
```

To run a single test on a single element pass arrays with the test and element. To check if a button has a valid accessibility label:

```swift
func test_individualTest_individualButton() {
    let button = XCUIApplication().buttons["My Button"]
    a11y(tests: [.buttonLabel], on: [button])
}
```

#### Ignoring Elements

When running `a11yCheckAllOnScreen()` it is possible to ignore elements using their accessibility identifiers by passing any identifiers you wish to ignore with the `ignoringElementIdentifiers: [String]` argument.

### Test Suites

A11yUITests contains 4 pre-built test suites with tests suitable for different elements.

`a11yTestSuiteAll` Runs all tests.

`a11yTestSuiteImages` Runs tests suitable for images.

`a11yTestSuiteInteractive` runs tests suitable for interactive elements.

`a11yTestSuiteLabels` runs tests suitable for static text elements.


Alternatively you can create an array of `A11yTests` enum values for the tests you want to run.

### Tests

#### Minimum Size

`minimumSize` or checks an element is at least 14px x 14px.
To specify a minimum size set a value to `A11yTestValues.minSize`
Severity: Warning

Note: 14px is arbitrary.

#### Minimum Interactive Size

`minimumInteractiveSize` checks tappable elements are a minimum of 44px x 44px.
This satisfies [WCAG 2.1 Success Criteria 2.5.5 Target Size Level AAA](https://www.w3.org/TR/WCAG21/#target-size)
To specify a custom minimum interactive size set a value to `A11yTestValues.minInteractiveSize`. This is not recommended.
Severity: Error

Note: Many of Apple's controls fail this requirement. For this reason, when running a suite of tests with `minimumInteractiveSize` only buttons and cells are checked. This may still result in some failures for `UITabBarButton`s for example.
For full compliance, you should run `a11yCheckValidSizeFor(interactiveElement: XCUIElement)` on any element that your user might interact with, eg. sliders, steppers, switches, segmented controls. But you will need to make your own subclass as Apple's are not strictly adherent to WCAG.

#### Label Presence

`labelPresence` checks the element has an accessibility label that is a minimum of 2 characters long. 
Pass a `minMeaningfulLength` argument to `a11yCheckValidLabelFor(element: XCUIElement, minMeaningfulLength: Int )` to change the minimum length. Or to set a minimum length for all tests set a value to `A11yTestValues.minMeaningfulLength`
This counts towards [WCAG 2.1 Guideline 1.1 Text Alternatives](https://www.w3.org/TR/WCAG21/#text-alternatives) but does not guarantee compliance.
Severity: Warning

Additionally this tests checks for elements that have a placeholder but no label and that the label is not uppercased.
Severity: Failure

Note: A length of 2 is arbitrary

#### Button Label

`buttonLabel` checks labels for interactive elements begin with a capital letter and don't contain a period or the word button. Checks the label is a minimum of 2 characters long. Checks the button doesn't contain common non-descriptive titles. This also checks that other interactive elements don't include their type in their label. 
Pass a `minMeaningfulLength` argument to `a11yCheckValidLabelFor(interactiveElement: XCUIElement, minMeaningfulLength: Int )` to change the minimum length.  Or to set a minimum length for all tests set a value to `A11yTestValues.minMeaningfulLength`
This follows [Apple's guidance for writing accessibility labels](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/Making_Application_Accessible/Making_Application_Accessible.html).
This follows [WCAG 2.1 Success Criterion 2.4.9 Link Purpose](https://www.w3.org/WAI/WCAG21/Understanding/link-purpose-link-only)
Severity: Error

Note: This test is not localised.
Note: A length of 2 is arbitrary

#### Image Label

`imageLabel` checks accessible images don't contain the words image, picture, graphic, or icon, and checks that the label isn't reusing the image filename. Checks the label is a minimum of 2 characters long.
Pass a `minMeaningfulLength` argument to `a11yCheckValidLabelFor(image: XCUIElement, minMeaningfulLength: Int )` to change the minimum length. Or to set a minimum length for all tests set a value to `A11yTestValues.minMeaningfulLength`
This follows [Apple's guidelines for writing accessibility labels](https://developer.apple.com/videos/play/wwdc2019/254/). Care should be given when deciding whether to make images accessible to avoid creating unnecessary noise.
Severity: Error


Note: This test is not localised.
Note: A length of 2 is arbitrary

#### Label Length
`labelLength` checks accessibility labels are <= 40 characters.
To set a maiximum length for all tests set a value to `A11yTestValues.maxMeaningfulLength`
This follows [Apple's guidelines for writing accessibility labels](https://developer.apple.com/videos/play/wwdc2019/254/).
Ideally, labels should be as short as possible while retaining meaning. If you feel your element needs more context consider adding an accessibility hint.
Severity: Warning

Note: A length of 40 is arbitrary

#### Header
`header` checks the screen has at least one text element with a header trait.
Headers are used by VoiceOver users to orientate and quickly navigate content.
This follows [WCAG 2.1 Success Criterion 2.4.10](https://www.w3.org/WAI/WCAG21/Understanding/section-headings.html)
Severity: Error

#### Button Trait
`buttonTrait` checks that a button element has the Button or Link trait applied.
This follows [Apple's guide for using traits](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/Making_Application_Accessible/Making_Application_Accessible.html).
Severity: Error

#### Image Trait
`imageTrait` checks that an image element has the Image trait applied.
This follows [Apple's guide for using traits](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/Making_Application_Accessible/Making_Application_Accessible.html).
Severity: Error

#### Conflicting Traits
`conflictingTraits` checks elements don't have conflicting traits.
Elements can't be both a button and a link, or static text and updates frequently

#### Disabled Elements
`disabled` checks that elements aren't disabled.
Disabled elements can be confusing if it is not clear why the element is disabled. Ideally keep the element enabled and clearly message if your app is not ready to process the action.
Severity: Warning

#### Duplicated Labels
`duplicated` checks all elements provided for duplication of accessibility labels.
Duplicated accessibility labels can make your screen confusing to navigate with VoiceOver, and make Voice Control fail. Ideally you should avoid duplication if possible.
Severity: Warning

#### Control Spacing

`controlSpacing` checks that controls have minimum padding between them. This is 8px for iPhone and 12px for iPad.
12px minimum is recommended for iPad by the [HIG]( https://developer.apple.com/design/human-interface-guidelines/inputs/pointing-devices). 8px is set for iPhone and can be changed by setting a value to `A11yTestValues.iPhonePadding`.

Note: 8px on iPhone is arbitrary.

#### Control Overlap

`controlOverlap` checks that controls don't have overlapping frames.
Severity: Failure

## Snapshot tests

Snapshot creates a JSON representation of your screen's accessibility tree on the first run. On subsequent runs this initial snapshot is taken as a reference. The test fails if there are any differences between the reference snapshot and the current snapshot. No assertions are made that the accessibility tree is correct or valid, you must make these checks yourself and generate a known-good reference snapshot to protect against future regressions.

### Running tests

In your UI test call `a11ySnapshot()`.
On first run the test will fail because no snapshot has been created for this test. A reference snapshot is generated. Grab the reference snapshot from the URL provided in the failure message or find it attached in the test's XCResult. Add this file to your **UITest** target ensuring the filename matches the `filename` property of the generated json file.
Subsequent test runs will be compared against this snapshot, if you wish to generate a new snapshot, remove the reference from your UITest target, run the test, and a new reference will be generated.

### Tests

Snapshot testing checks for changes in the following:
* Accessibility label
* Frame
* Enabled status
* Control type
* Accessibility traits

### Test properties

Use `A11yTestValues` to set various default values for all tests.

Property | Default | Purpose
---|---|---
`minSize` | 14 | Minimum element size on screen for accessible elements. arbitrary.
`minInteractiveSize` | 44 | Minimum size on screen for interactive elements. 44 is specified by [WCAG](https://www.w3.org/TR/WCAG21/#target-size)
`minMeaningfulLength` | 2 | Minimum length of an accessible string. arbitrary.
`maxMeaningfulLength` | 40 | Maximum length of an accessible string. arbitrary.
`allInteractiveElements` | true | When false this skips the 44px size test on interactive elements. This is useful when relying heavily on standard iOS components that do not have valid sizes. Note: Using these elements is still a failure under WCAG, you should customise their appearance so they are large enough. 
`floatComparisonTolerance` | 0.1 | Float comparison threshold
`preferredItemLabel` | label | Failure messages prefer reporting the items label, accessibility Identifier, or both.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

`A11yUITests_ExampleUITests.swift` contains example tests that show a fail for each test above.

## Requirements

iOS 11

Swift 5

## Installation

### Swift Package Manager

This library support [Swift Package Manager](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app). Ensure the package is added as a dependancy to your UITests target, not your app's target.

### Cocoapods

A11yUITests is available through [CocoaPods](https://cocoapods.org). 
To install add the pod to your target's test target in your podfile. eg

```ruby
target 'My_Application' do
    target 'My_Application_UITests' do
    pod 'A11yUITests'
    end
end
```

## Note

* This library accesses a private property in the iOS SDK, so care should be taken when adding it to your project to ensure you are not shipping this code. If you submit this code to app review you will likely receive a rejection from Apple. If you do submit this code then you've installed it wrong, go take another look at [Installation](#installation).

## Known Issues

If two elements of the same type have the same identifier (eg, two buttons both labeled 'Next') this can cause the tests to crash on some iOS versions. This was an issue on iOS 13 and appears fixed as of iOS 15.

Elements that are hidden from accessibility are still assessed by these tests. This is due to how XCUI presents elements to the test runner, I'm not currently aware of a way to detect elements hidden from accessibility.

## Author

Rob Whitaker, rw@rwapp.co.uk\
https://mobilea11y.com

## License

A11yUITests is available under the MIT license. See the LICENSE file for more info.
