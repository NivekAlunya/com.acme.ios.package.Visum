//
//  VisumProtocol.swift
//  Visum
//
//  Created by Kevin Launay on 17/10/2025.
//

import Foundation
import UIKit

public protocol VisumProtocol: Actor {
    func analyze(image: UIImage) async throws -> [String]
    func detect(image: UIImage) async throws -> [CGRect]
    nonisolated func contour(image: UIImage) async throws -> [CGPath]
    func detectArea(image: UIImage) async throws -> UIImage?
    func detectSemanticArea(image: UIImage) async throws -> [UIImage]
    func fastDetect(image: UIImage) async throws -> [String]
    func classify(image: UIImage) async throws -> [String]
    func scan(image: UIImage) async throws -> [String]
    func scanBarcode<T: BarcodeScannableImage>(image: T) async throws -> [String]
}
