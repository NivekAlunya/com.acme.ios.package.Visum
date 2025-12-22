//
//  BarcodeScannableImage.swift
//  Visum
//
//  Created by Kevin Launay on 17/10/2025.
//

import Vision

// Protocol to constrain acceptable image types and generate handlers
public protocol BarcodeScannableImage: Sendable {
    func createRequestHandler(orientation: CGImagePropertyOrientation?, options: [VNImageOption : Any]) throws -> VNImageRequestHandler
}
