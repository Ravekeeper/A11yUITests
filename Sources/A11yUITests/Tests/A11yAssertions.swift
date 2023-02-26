//
//  A11yAssertions.swift
//  A11yUITests
//
//  Created by Rob Whitaker on 28/03/2021.
//

import XCTest

final class A11yAssertions {

    private var hasHeader = false
    private var duplicatedItems = [String: Set<A11yElement>]()
    private var closeControls = [Int: Set<A11yElement>]()
    private var overlappedControls = [Int: Set<A11yElement>]()

    func setupTests() {
        hasHeader = false
    }

    func validSizeFor(_ element: A11yElement,
                      _ minSize: Int,
                      _ file: StaticString,
                      _ line: UInt) {

        guard !element.shouldIgnore else { return }

        let minFloatSize = CGFloat(minSize)

        let heightDifference = element.frame.size.height - minFloatSize

        A11yAssertGreaterThanOrEqual(heightDifference,
                                     -A11yTestValues.floatComparisonTolerance,
                                     message: "Element may not be tall enough.",
                                     elements: [element],
                                     reason: "Minimum height: \(minSize). Current height: \(element.frame.size.height.printable)",
                                     severity: .warning,
                                     file: file,
                                     line: line)

        let widthDifference = element.frame.size.width - minFloatSize
        A11yAssertGreaterThanOrEqual(widthDifference,
                                     -A11yTestValues.floatComparisonTolerance,
                                     message: "Element may not be wide enough.",
                                     elements: [element],
                                     reason: "Minimum width: \(minSize). Current width: \(element.frame.size.width.printable)",
                                     severity: .warning,
                                     file: file,
                                     line: line)
    }

    func validLabelFor(_ element: A11yElement,
                       _ length: Int,
                       _ file: StaticString,
                       _ line: UInt) {

        guard !element.shouldIgnore,
              element.type != .cell else { return }

        if let placeholder = element.placeholder,
           placeholder.count > 0,
           element.label.count == 0 {

            A11yFail(message: "No label for element with placeholder \"\(placeholder)\".", elements: [element], severity: .failure, file: file, line: line)
        } else {

            A11yAssertGreaterThan(element.label.count,
                                  length,
                                  message: "Label may not be meaningful.",
                                  elements: [element],
                                  reason: "Minimum length: \(length)",
                                  severity: .warning,
                                  file: file,
                                  line: line)
        }

        let notLetters = CharacterSet.uppercaseLetters.inverted
        let capitalised = element.label.uppercased()

        if capitalised.trimmingCharacters(in: notLetters).count > 0 {
            A11yAssertNotEqual(capitalised,
                               element.label,
                               message: "Label is uppercased.",
                               elements: [element],
                               severity: .warning,
                               file: file,
                               line: line)
        }
    }

    func validLabelFor(interactiveElement element: A11yElement,
                       _ length: Int,
                       _ file: StaticString,
                       _ line: UInt) {

        guard element.isControl else { return }

        // TODO: Localise this check
        let nondescriptiveLabels = ["click here", "tap here", "more"]
        let contained = element.label.containsWords(nondescriptiveLabels)
        contained.forEach {
            A11yFail(message: "Button label may not be descriptive.",
                     elements: [element],
                     reason: "Offending word: \($0)",
                     severity: .failure,
                     file: file,
                     line: line)
        }

        // TODO: Localise this check
        A11yAssertFalse(element.label.containsCaseInsensitive("button"),
                        message: "Button should not contain the word 'button' in the accessibility label.",
                        elements: [element],
                        severity: .failure,
                        file: file,
                        line: line)

        if let first = element.label.first {
            A11yAssert(first.isUppercase,
                       message: "Buttons should begin with a capital letter.",
                       elements: [element],
                       severity: .failure,
                       file: file,
                       line: line)
        }

        A11yAssertNil(element.label.range(of: "."),
                      message: "Button accessibility labels shouldn't contain punctuation.",
                      elements: [element],
                      severity: .failure,
                      file: file,
                      line: line)

        if element.type == .textView || element.type == .textField || element.type == .searchField || element.type == .secureTextField {
            A11yAssertFalse(element.label.containsCaseInsensitive("field"),
                            message: "Text fields should not include their type in the label.",
                            elements: [element],
                            severity: .failure,
                            file: file,
                            line: line)
        }

        if element.traits?.contains(.link) ?? false || element.type == .link {
            A11yAssertFalse(element.label.containsCaseInsensitive("link"),
                            message: "Links should not include their type in the label.",
                            elements: [element],
                            severity: .failure,
                            file: file,
                            line: line)
        }

        if element.traits?.contains(.adjustable) ?? false || element.type == .slider {
            A11yAssertFalse(element.label.containsCaseInsensitive("adjustable"),
                            message: "Links should not include their type in the label.",
                            elements: [element],
                            severity: .failure,
                            file: file,
                            line: line)

            A11yAssertFalse(element.label.containsCaseInsensitive("slider"),
                            message: "Links should not include their type in the label.",
                            elements: [element],
                            severity: .failure,
                            file: file,
                            line: line)
        }
    }

    func validLabelFor(image: A11yElement,
                       _ length: Int,
                       _ file: StaticString,
                       _ line: UInt) {

        guard image.type == .image else { return }

        // TODO: Localise this test
        let avoidWords = ["image", "picture", "graphic", "icon", "photo"]

        let contained = image.label.containsWords(avoidWords)
        contained.forEach {
            A11yFail(message: "Images should not contain image words in the accessibility label.",
                     elements: [image],
                     reason: "Offending word: \($0)",
                     severity: .failure,
                     file: file,
                     line: line)
        }

        let possibleFilenames = ["_", "-", "png", "jpg", "jpeg", "pdf", "avci", "heic", "heif", "svg"]

        let containedFilenames = image.label.containsWords(possibleFilenames)
        containedFilenames.forEach {
            A11yFail(message: "Image file name is used as the accessibility label.",
                     elements: [image],
                     reason: "Offending word: \($0)",
                     severity: .failure,
                     file: file,
                     line: line)
        }
    }

    func validTraitFor(image: A11yElement,
                       _ file: StaticString,
                       _ line: UInt) {
        guard image.type == .image else { return }

        A11yAssert(image.traits?.contains(.image) ?? false,
                   message: "Image should have Image trait.",
                   elements: [image],
                   severity: .failure,
                   file: file,
                   line: line)
    }

    func validTraitFor(button: A11yElement,
                       _ file: StaticString,
                       _ line: UInt) {
        guard button.type == .button else { return }

        A11yAssert(button.traits?.contains(.button) ?? false ||
                   button.traits?.contains(.link) ?? false,
                   message: "Button should have Button or Link trait.",
                   elements: [button],
                   severity: .failure,
                   file: file,
                   line: line)
    }

    func conflictingTraits(_ element: A11yElement,
                           _ file: StaticString,
                           _ line: UInt) {
        guard let traits = element.traits else { return }

        A11yAssert(!traits.contains(.button) || !traits.contains(.link),
                   message: "Elements shouldn't have both Button and Link traits.",
                   elements: [element],
                   severity: .failure,
                   file: file,
                   line: line)

        A11yAssert(!traits.contains(.staticText) || !traits.contains(.updatesFrequently),
                   message: "Elements shouldn't have both Static Text and Updates Frequently traits.",
                   elements: [element],
                   severity: .failure,
                   file: file,
                   line: line)
    }

    func labelLength(_ element: A11yElement,
                     _ maxLength: Int,
                     _ file: StaticString,
                     _ line: UInt) {

        guard element.type != .staticText,
              element.type != .textView,
              !element.shouldIgnore else { return }

        A11yAssertLessThanOrEqual(element.label.count,
                                  maxLength,
                                  message: "Label may be too long.",
                                  elements: [element],
                                  reason: "Max length: \(maxLength)",
                                  severity: .warning,
                                  file: file,
                                  line: line)
    }

    func validSizeFor(interactiveElement: A11yElement,
                      allElements:  Bool,
                      _ file: StaticString,
                      _ line: UInt) {

        if (!allElements && !interactiveElement.isInteractive) ||
            !interactiveElement.isControl { return }

        let heightDifference = interactiveElement.frame.size.height - A11yTestValues.minInteractiveSize

        A11yAssertGreaterThanOrEqual(heightDifference,
                                     -A11yTestValues.floatComparisonTolerance,
                                     message: "Interactive element not tall enough.",
                                     elements: [interactiveElement],
                                     reason: "Minimum height: \(A11yTestValues.minInteractiveSize). Current height: \(interactiveElement.frame.size.height.printable)",
                                     severity: .failure,
                                     file: file,
                                     line: line)

        let widthDifference = interactiveElement.frame.size.width - A11yTestValues.minInteractiveSize
        A11yAssertGreaterThanOrEqual(widthDifference,
                                     -A11yTestValues.floatComparisonTolerance,
                                     message: "Interactive element not wide enough.",
                                     elements: [interactiveElement],
                                     reason: "Minimum width: \(A11yTestValues.minInteractiveSize). Current width: \(interactiveElement.frame.size.width.printable)",
                                     severity: .failure,
                                     file: file,
                                     line: line)
    }

    func hasHeader(_ element: A11yElement) {
        guard !hasHeader,
              element.traits?.contains(.header) ?? false else { return }
        hasHeader = true
    }

    func checkHeader(_ file: StaticString, _ line: UInt) {
        A11yAssert(hasHeader,
                   message: "Screen has no element with a header trait.",
                   severity: .failure,
                   file: file,
                   line: line)
    }

    func disabled(_ element: A11yElement,
                  _ file: StaticString,
                  _ line: UInt) {

        guard element.isControl else { return }

        A11yAssert(element.enabled,
                   message: "Element disabled.",
                   elements: [element],
                   severity: .warning,
                   file: file,
                   line: line)
    }

    func duplicatedLabels(_ element1: A11yElement,
                          _ element2: A11yElement) {

        guard element1.isControl,
              element2.isControl,
              element1.id != element2.id,
              element1.label.count > 0,
              element2.label.count > 0 else { return }

        if element1.label == element2.label {
            var items = duplicatedItems[element1.label] ?? Set<A11yElement>()
            items.insert(element1)
            items.insert(element2)
            duplicatedItems[element1.label] = items
        }
    }

    func checkDuplicates(_ file: StaticString,
                         _ line: UInt) {
        for duplicatePair in duplicatedItems.enumerated() {
            let element = duplicatePair.element.value
            A11yFail(message: "Elements have duplicated labels.", elements: Array(element), severity: .warning, file: file, line: line)
        }
    }

    func controlSpacing(_ element1: A11yElement,
                        _ element2: A11yElement,
                        tests: [A11yTests] ) {
        guard element1.isControl,
              element2.isControl,
              element1.id != element2.id else { return }

        let hash = hashElements(element1, element2)

        guard overlappedControls[hash] == nil,
              closeControls[hash] == nil else { return }

        if element1.frame.intersects(element2.frame) {
            if tests.contains(.controlOverlap) {
                overlappedControls[hash] = [element1, element2]
            }

            return
        }

        let padding = UIDevice.current.userInterfaceIdiom == .pad ? 12 : A11yTestValues.iPhonePadding

        let expandedFrame1 = CGRect(x: element1.frame.origin.x - CGFloat(padding), y: element1.frame.origin.y - CGFloat(padding), width: element1.frame.size.width + CGFloat(padding * 2), height: element1.frame.size.height + CGFloat(padding * 2))

        if tests.contains(.controlSpacing) && expandedFrame1.intersects(element2.frame) {
            closeControls[hash] = [element1, element2]
        }
    }

    func checkControlSpacing(_ file: StaticString, _ line: UInt) {
        overlappedControls.values.forEach {
            A11yFail(message: "Controls are overlapping.",
                     elements: Array($0),
                     severity: .failure,
                     file: file,
                     line: line)
        }

        closeControls.values.forEach {
            A11yFail(message: "Controls are closely spaced.",
                     elements: Array($0),
                     severity: .warning,
                     file: file,
                     line: line)
        }
    }

    private func hashElements(_ element1: A11yElement, _ element2: A11yElement) -> Int {
        var hasher = Hasher()
        [element1.id.uuidString, element2.id.uuidString].sorted { $0 > $1 }
            .forEach {
                hasher.combine($0)
            }

        return hasher.finalize()
    }
}
