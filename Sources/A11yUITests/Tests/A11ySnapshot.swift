//
//  Snapshot.swift
//  A11yUITests
//
//  Created by Rob Whitaker on 15/01/2022.
//

import Foundation
import XCTest

extension XCTestCase {
    public func a11ySnapshot(testName: StaticString = #function,
                             testsFile: StaticString = #file,
                             line: UInt = #line) {
        A11ySnapshot.shared.a11ySnapshot(from: self, testName: testName, testsFile: testsFile, line: line)
    }
}

final class A11ySnapshot {

    static let shared = A11ySnapshot()

    private struct SnapshotWrapper: Codable {
        private static let wrapperVersion = 1
        static let snapshotVersion = "\(SnapshotWrapper.wrapperVersion).\(A11yElement.CodableElement.version)"
        
        var filename: String
        var version: String
        var generated: Date
        let snapshot: [A11yElement.CodableElement]

        init(snapshots: [A11yElement.CodableElement], fileName: String) {
            filename = fileName
            snapshot = snapshots
            version = SnapshotWrapper.snapshotVersion
            generated = Date()
        }
    }

    private struct Screen {
        let snapshot: SnapshotWrapper
        let elements: [A11yElement]

        init(elements: [A11yElement], fileName: String) {
            self.elements = elements.filter { $0.codable != nil }
            self.snapshot = SnapshotWrapper(snapshots: elements.compactMap { $0.codable }, fileName: fileName)

        }
    }

    private let forbiddenCharacters: [Character] = ["(", ")",]

    private var calledInFunction = 0
    private var currentFunction = ""
    private var currentSuite = ""
    private var fileName: String {
        var fileName = "\(currentSuite)-\(currentFunction)-\(calledInFunction)"
        fileName.removeAll(where: { forbiddenCharacters.contains($0) })
        fileName = fileName.replacingOccurrences(of: "_", with: "-")
        fileName.append(".json")
        return fileName
    }

    private let fileManager = FileManager.default

    public init() {}

    public func a11ySnapshot(from test: XCTestCase,
                             testName: StaticString = #function,
                             testsFile: StaticString = #file,
                             line: UInt = #line) {
        let elements = XCUIApplication()
            .descendants(matching: .any)
            .allElementsBoundByAccessibilityElement
            .map { A11yElement($0) }

        makeSnapshot(screen: elements,
                     testName: String(testName),
                     testsFile: testsFile,
                     test: test,
                     line: line)
    }

    private func makeSnapshot(screen: [A11yElement],
                              testName: String,
                              testsFile: StaticString,
                              test: XCTestCase,
                              line: UInt) {

        let suite = ((String(testsFile) as NSString).lastPathComponent as NSString).deletingPathExtension
        if currentFunction == testName &&
            currentSuite == suite {
            calledInFunction += 1
        } else {
            calledInFunction = 0
            currentFunction = testName
            currentSuite = suite
        }

        let screen = Screen(elements: screen, fileName: fileName)

        let path = Bundle(for: type(of: test)).bundleURL.appendingPathComponent(fileName)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = try? Data(contentsOf: path),
           let referenceScreen = try? decoder.decode(SnapshotWrapper.self, from: data) {
            compareScreens(reference: referenceScreen, screen: screen, test: test, file: testsFile, line: line)

        } else {
            if let docPath = createNewSnapshot(screen.snapshot, test: test, file: testsFile, line: line) {
                A11yFail(message: "No reference snapshot. Generated new snapshot.\nCheck test report or \(docPath)", severity: .warning, file: testsFile, line: line)
                return
            }

            A11yFail(message: "No reference snapshot. Unable to create new reference", severity: .failure, file: testsFile, line: line)
        }
    }

    private func createNewSnapshot(_ snapshot: SnapshotWrapper,
                                   test: XCTestCase,
                                   file: StaticString,
                                   line: UInt) -> URL? {
        guard let documentDirectory = fileManager.urls(for: .documentDirectory,
                                                       in: .userDomainMask).first else {
            A11yFail(message: "Unable get documents directory", severity: .failure, file: file, line: line)
            return nil
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(snapshot)

            do {
                let documentPath = documentDirectory.appendingPathComponent(fileName)
                try jsonData.write(to: documentPath)

                let attachment = XCTAttachment(contentsOfFile: documentPath)
                test.add(attachment)

                return documentPath

            } catch {
                print("Unable to write snapshot to disk. \(error.localizedDescription)")
                return nil
            }

        } catch {
            print("Unable to encode snapshot. \(error.localizedDescription)")
            return nil
        }
    }

    private func compareScreens(reference: SnapshotWrapper,
                                screen: Screen,
                                test: XCTestCase,
                                file: StaticString,
                                line: UInt) {

        if reference.version < SnapshotWrapper.snapshotVersion {
            if let docPath = createNewSnapshot(screen.snapshot, test: test, file: file, line: line) {
                A11yFail(message: "Reference snapshot is outdated. Generated new snapshot. Check for regressions before replacing as reference.\nCheck test report or \(docPath)", severity: .warning, file: file, line: line)

                return
            }

            A11yFail(message: "Reference snapshot is outdated. Unable to create new reference", severity: .failure, file: file, line: line)
            return
        }

        A11yAssertEqual(reference.snapshot.count,
                        screen.snapshot.snapshot.count,
                        message: "Snapshots contain a different number of items. This screen has changed",
                        severity: .failure,
                        file: file,
                        line: line)

        for i in 0..<reference.snapshot.count {

            guard screen.snapshot.snapshot.count > i else { return }

            let snapshotElement = screen.elements[i]
            let referenceElement = reference.snapshot[i]
            let snapshotElementLabel = snapshotElement.label

            A11yAssertEqual(referenceElement.label,
                            snapshotElementLabel,
                            message: "Label does not match reference snapshot",
                            elements: [snapshotElement],
                            reason: "Reference: \(referenceElement.label). Snapshot: \(snapshotElementLabel)",
                            severity: .failure,
                            file: file,
                            line: line)

            A11yAssertEqual(referenceElement.type,
                            snapshotElement.type.name(),
                            message: "Type does not match reference snapshot",
                            elements: [snapshotElement],
                            reason: "Reference: \(referenceElement.type). Snapshot: \(snapshotElement.type)",
                            severity: .failure,
                            file: file,
                            line: line)

            A11yAssertEqual(referenceElement.traits,
                            snapshotElement.traits?.names() ?? [],
                            message: "Traits do not match reference snapshot",
                            elements: [snapshotElement],
                            reason: "Reference: \(referenceElement.traits.joined(separator: ", ")). Snapshot: \(snapshotElement.traits?.nameString() ?? "")",
                            severity: .failure,
                            file: file,
                            line: line)

            A11yAssertEqual(referenceElement.enabled,
                            snapshotElement.enabled,
                            message: "Enabled status does not match reference snapshot",
                            elements: [snapshotElement],
                            reason: "Reference: \(referenceElement.enabled). Snapshot: \(snapshotElement.enabled)",
                            severity: .failure,
                            file: file,
                            line: line)

            compareFrame(reference: referenceElement.frame, snapshot: snapshotElement, label: snapshotElementLabel, file: file, line: line)
        }
    }

    private func compareFrame(reference: CGRect, snapshot: A11yElement, label: String, file: StaticString, line: UInt) {

        let refX = reference.origin.x
        let refY = reference.origin.y
        let refWidth = reference.size.width
        let refHeight = reference.size.height

        let snapX = snapshot.frame.origin.x
        let snapY = snapshot.frame.origin.y
        let snapWidth = snapshot.frame.size.width
        let snapHeight = snapshot.frame.size.height

        A11yAssertEqual(refX, snapX, accuracy: A11yTestValues.floatComparisonTolerance,
                        message: "Frame does not match reference snapshot",
                        elements: [snapshot],
                        reason: "Reference x: \(refX.printable). Snapshot x: \(snapX.printable)",
                        severity: .failure, file: file, line: line)

        A11yAssertEqual(refY, snapY, accuracy: A11yTestValues.floatComparisonTolerance,
                        message: "Frame does not match reference snapshot",
                        elements: [snapshot],
                        reason: "Reference y: \(refY.printable). Snapshot y: \(snapY.printable)",
                        severity: .failure, file: file, line: line)

        A11yAssertEqual(refWidth, snapWidth, accuracy: A11yTestValues.floatComparisonTolerance,
                        message: "Frame does not match reference snapshot",
                        elements: [snapshot],
                        reason: "Reference width: \(refWidth.printable). Snapshot width: \(snapWidth.printable)",
                        severity: .failure, file: file, line: line)

        A11yAssertEqual(refHeight, snapHeight, accuracy: A11yTestValues.floatComparisonTolerance,
                        message: "Frame does not match reference snapshot",
                        elements: [snapshot],
                        reason: "Reference height: \(refHeight.printable). Snapshot height: \(snapHeight.printable)",
                        severity: .failure, file: file, line: line)
    }
}
