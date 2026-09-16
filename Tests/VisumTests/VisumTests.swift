//
//  VisumTests.swift
//  VisumTests
//
//  Created by Kevin Launay on 01/10/2025.
//

import Testing
import UIKit
import CoreGraphics
@testable import Visum

@Suite("Visum Tests")
struct VisumTests {

    @Test("DetectionResult properties and Equatable conformance")
    func testDetectionResult() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 150)
        let result = DetectionResult(boundingBox: rect, confidence: 0.95, label: "person")

        #expect(result.boundingBox == rect)
        #expect(result.confidence == 0.95)
        #expect(result.label == "person")

        let duplicate = DetectionResult(boundingBox: rect, confidence: 0.95, label: "person")
        #expect(result == duplicate)
    }

    @Test("UIImage resizing and CVPixelBuffer conversion")
    func testPixelBufferConversion() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        }

        let resized = image.resized(to: CGSize(width: 32, height: 32))
        #expect(resized != nil)
        #expect(resized?.size.width == 32)
        #expect(resized?.size.height == 32)

        let pixelBuffer = image.toCVPixelBuffer(targetSize: CGSize(width: 32, height: 32))
        #expect(pixelBuffer != nil)
    }

    @Test("Contour detection on drawn shape")
    func testContourDetection() async throws {
        let visum = Visum.shared
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let testImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 25, y: 25, width: 50, height: 50))
        }

        let paths = try await visum.contour(image: testImage)
        #expect(!paths.isEmpty)
    }
}
