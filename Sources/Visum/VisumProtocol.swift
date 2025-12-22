//
//  VisumProtocol.swift
//  Visum
//
//  Created by Kevin Launay on 17/10/2025.
//

import Foundation
import UIKit
import Vision

public protocol VisumProtocol: Sendable {
    func analyze(image: UIImage) async throws -> [String]
    func detect(image: UIImage) async throws -> [CGRect]
    func contour(image: UIImage) async throws -> [CGPath]
    func detectArea(image: UIImage) async throws -> UIImage?
    func detectSemanticArea(image: UIImage) async throws -> [UIImage]
    func fastDetect(image: UIImage) async throws -> [String]
    func classify(image: UIImage) async throws -> [String]
    func scanText<T: BarcodeScannableImage>(image: T) async throws -> [String]
    func scanCode<T: BarcodeScannableImage>(image: T, symbologies: [VNBarcodeSymbology]) async throws -> [String]
}
