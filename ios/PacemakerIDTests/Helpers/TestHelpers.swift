import CoreGraphics
import Foundation
@testable import PacerID
import UIKit
import XCTest

/// Utility functions for testing
enum TestHelpers {
    // MARK: - Image Creation

    /// Creates a test CGImage with the specified size and color
    static func createTestImage(
        size: CGSize = CGSize(width: 100, height: 100),
        color: UIColor = .blue
    ) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.cgImage
    }

    // MARK: - Classification Creation

    /// Creates test classifications with specified count and confidence values
    static func createClassifications(
        count: Int = 4,
        topConfidence: Double = 0.87
    ) -> [Classification] {
        let labels = [
            "Medtronic Azure XT DR",
            "Boston Scientific Accolade MRI",
            "Abbott Ellipse VR",
            "Biotronik Eluna 8 DR-T",
            "Medtronic Percepta CRT-D",
        ]

        var results: [Classification] = []
        var remainingProbability = 1.0

        for i in 0 ..< min(count, labels.count) {
            let confidence: Double = if i == 0 {
                topConfidence
            } else {
                remainingProbability * 0.3
            }

            results.append(Classification(
                label: labels[i],
                confidence: confidence
            ))

            remainingProbability -= confidence
        }

        return results
    }

    /// Creates a single test classification
    static func createClassification(
        label: String = "Medtronic Azure XT DR",
        confidence: Double = 0.87
    ) -> Classification {
        Classification(label: label, confidence: confidence)
    }

    // MARK: - Async Testing

    /// Waits for a published value to match a condition
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - getValue: Closure that retrieves the current value
    ///   - condition: Condition that must be satisfied
    /// - Returns: True if condition was met within timeout
    @MainActor
    static func waitForCondition(
        timeout: TimeInterval = 2.0,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        return false
    }

    /// Waits for a published value to equal an expected value
    @MainActor
    static func waitForValue<T: Equatable>(
        timeout: TimeInterval = 2.0,
        getValue: @escaping () -> T,
        toMatch expectedValue: T
    ) async -> Bool {
        await waitForCondition(timeout: timeout) {
            getValue() == expectedValue
        }
    }

    /// Waits for a published optional value to not be nil
    @MainActor
    static func waitForNonNil(
        timeout: TimeInterval = 2.0,
        getValue: @escaping () -> (some Any)?
    ) async -> Bool {
        await waitForCondition(timeout: timeout) {
            getValue() != nil
        }
    }
}
