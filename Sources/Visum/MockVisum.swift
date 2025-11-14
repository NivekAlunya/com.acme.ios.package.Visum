//
//  MockVisum.swift
//  Visum
//
//  Created by Kevin Launay on 17/10/2025.
//

import UIKit
import CoreGraphics
import Vision

public actor MockVisum: VisumProtocol {
    
    public var analyzeResult: [String] = []
    public var detectResult: [CGRect] = []
    public var contourResult: [CGPath] = []
    public var detectAreaResult: UIImage?
    public var detectSemanticAreaResult: [UIImage] = []
    public var fastDetectResult: [String] = []
    public var classifyResult: [String] = []
    public var scanResult: [String] = []
    public var scanBarcodeResult: [String] = []
    
    public var shouldThrowError = false
    public var errorToThrow: Error = Visum.VisumError.failed
    
    public init() {}
    
    public func analyze(image: UIImage) async throws -> [String] {
        if shouldThrowError { throw errorToThrow }
        return analyzeResult
    }
    
    public func detect(image: UIImage) async throws -> [CGRect] {
        if shouldThrowError { throw errorToThrow }
        return detectResult
    }
    
    nonisolated public func contour(image: UIImage) async throws -> [CGPath] {
        return [CGPath]()
    }
    
    public func detectArea(image: UIImage) async throws -> UIImage? {
        if shouldThrowError { throw errorToThrow }
        return detectAreaResult
    }
    
    public func detectSemanticArea(image: UIImage) async throws -> [UIImage] {
        if shouldThrowError { throw errorToThrow }
        return detectSemanticAreaResult
    }
    
    public func fastDetect(image: UIImage) async throws -> [String] {
        if shouldThrowError { throw errorToThrow }
        return fastDetectResult
    }
    
    public func classify(image: UIImage) async throws -> [String] {
        if shouldThrowError { throw errorToThrow }
        return classifyResult
    }
    
    public func scanText(image: UIImage) async throws -> [String] {
        if shouldThrowError { throw errorToThrow }
        return scanResult
    }
    public func scanCode<T>(image: T, symbologies: [VNBarcodeSymbology]) async throws -> [String] where T : BarcodeScannableImage {
        if shouldThrowError { throw errorToThrow }
        return scanBarcodeResult
    }
}
