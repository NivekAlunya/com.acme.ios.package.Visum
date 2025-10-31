// The Swift Programming Language
// https://docs.swift.org/swift-book

import CoreML
@preconcurrency import Vision
@preconcurrency import UIKit

public actor Visum: VisumProtocol {

    enum VisumError : Error {
        case noResults
        case failed
    }

    public static let shared = Visum()

    private init() {

    }

    public func analyze(image: UIImage) async throws -> [String] {

        return try await withCheckedThrowingContinuation { continuation in
            do {
                let confident: Float = 0.1
                var config = MLModelConfiguration()
                config.computeUnits = .all
                config.allowLowPrecisionAccumulationOnGPU = true

                let model = try VNCoreMLModel(for: MobileNetV2(configuration: config).model)
                // Create a handler to perform the request
                let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])

                let request = VNCoreMLRequest(model: model) { request, error in
                    guard let results = request.results as? [VNClassificationObservation] else {
                        continuation.resume(throwing: VisumError.noResults)
                        return
                    }
                    let values = results.compactMap { observation in
                        observation.confidence > confident ? "\(observation.identifier) \(observation.confidence)" : nil
                    }
                    continuation.resume(returning: values)
                }

                // Perform the request
                try handler.perform([request])

            } catch {
                continuation.resume(throwing: VisumError.failed)
            }
        }
    }

    public func detect(image: UIImage) async throws -> [CGRect] {

        return try await withCheckedThrowingContinuation { continuation in
            var config = MLModelConfiguration()
            config.computeUnits = .all
            config.allowLowPrecisionAccumulationOnGPU = true
            do {
                let model = try VNCoreMLModel(for: YOLOv3(configuration: config).model)
                // Create a handler to perform the request

                let handler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: getOrientation(from: image), options: [:])

                let request = VNCoreMLRequest(model: model) { request, error in
                    guard let results = request.results as? [VNRecognizedObjectObservation] else {
                        continuation.resume(throwing: VisumError.noResults)
                        return
                    }

                    let values = results.flatMap { result in
                        result.labels.compactMap { (observation) -> CGRect? in
                            print("\(observation.identifier) | \(observation.confidence)")
                            guard observation.confidence > 0.2 else {
                                return nil
                            }
                            let confidence = observation.confidence
                            let boundedBox = result.boundingBox
                            //return "\(observation.identifier) | \(confidence) | \(boundedBox)"
                            return boundedBox
                        }
                    }

                    print("Type of values: \(type(of: values))")  // This will show the actual type

                    continuation.resume(returning: values)
                }

                // Perform the request
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisumError.failed)
            }
        }
    }

    nonisolated public func contour(image: UIImage) async throws -> [CGPath] {
        guard var ciImage = CIImage(image: image)
        else {
            throw VisumError.failed
        }
        do {
            var request = DetectContoursRequest()
            request.contrastAdjustment = 2.0
            request.detectsDarkOnLight = false
            print(image.imageOrientation)

            let contours = try await request.perform(on: ciImage, orientation: getOrientation(from: image))
            return [contours.normalizedPath]
        } catch {
            throw VisumError.failed
        }
    }

    nonisolated public func detectArea(image: UIImage) async throws -> UIImage? {
        var config = MLModelConfiguration()
        config.computeUnits = .all
        config.allowLowPrecisionAccumulationOnGPU = true

        let model = try DETRResnet50SemanticSegmentationF16(configuration: config)

        var size = CGSize(width: 448, height: 448)

        guard let pixelBuffer = image.toCVPixelBuffer(targetSize: size) else {
            throw VisumError.failed
        }
        let palette = [UIColor.red, UIColor.yellow, UIColor.green, UIColor.blue, UIColor.systemPink, UIColor.cyan, UIColor.magenta, UIColor.gray]
        let output: DETRResnet50SemanticSegmentationF16Output = try model.prediction(image: pixelBuffer)
        let shapes = output.semanticPredictionsShapedArray

        let mask = await maskToUIImage(array: shapes, palette: palette)

        return mask?.resize(size: image.size)
    }

    nonisolated public func detectSemanticArea(image: UIImage) async throws -> [UIImage] {

        var config = MLModelConfiguration()
        config.computeUnits = .all
        config.allowLowPrecisionAccumulationOnGPU = true
        let model = try DETRResnet50SemanticSegmentationF16P8(configuration: config)


        let labels = if let metadata = model.model.modelDescription.metadata[.creatorDefinedKey] as? [String: Any],
           let params = metadata["com.apple.coreml.model.preview.params"] as? String,
           let data = params.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let labels = parsed["labels"] as? [String] {
           labels
        } else {
            []
        }

        let context = CIContext()

        var size = CGSize(width: 448, height: 448)

        guard let pixelBuffer = image.toCVPixelBuffer(targetSize: size) else {
            throw VisumError.failed
        }

        let palette = [UIColor.red, UIColor.yellow, UIColor.green, UIColor.blue, UIColor.systemPink, UIColor.cyan, UIColor.magenta, UIColor.gray, ]

        let input = DETRResnet50SemanticSegmentationF16P8Input(image: pixelBuffer)
        var options = MLPredictionOptions()
        let output: DETRResnet50SemanticSegmentationF16P8Output = try await model.prediction(input: input, options: options)
        print(options.outputBackings.debugDescription)
        let predictions = output.semanticPredictionsShapedArray

        let uniqueLabelIndices = Set(predictions.scalars).sorted()

        // Map the label indices to label names.
        let predictedLabels = uniqueLabelIndices.map({ labels[Int($0)] })

        let shapes = output.semanticPredictionsShapedArray

        var results = [UIImage]()
        let mask = await maskToUIImage(array: shapes, palette: palette)

        if let image = mask?.resize(size: image.size) {
            results.append(image)
        }

        for uniqueLabelIndex in uniqueLabelIndices {
            let mask = await maskToUIImage(array: shapes, palette: palette, selectedMask: Int(uniqueLabelIndex))
            if let image = mask?.resize(size: image.size) {
                results.append(image)
            }
            results.append(image)
        }

        return results
    }

    public func fastDetect(image: UIImage) async throws -> [String] {
        let confident = 0.1

        var config = MLModelConfiguration()
        config.computeUnits = .all
        config.allowLowPrecisionAccumulationOnGPU = true

        let model = try FastViTMA36F16(configuration: config)

        var size = CGSize(width: 256, height: 256)

        guard let pixelBuffer = image.toCVPixelBuffer(targetSize: size) else {
            throw VisumError.failed
        }

        let output = try model.prediction(image: pixelBuffer)

        let features = output.featureNames

        let labels = features.flatMap { (featureName: String) -> [String] in
            guard let value = output.featureValue(for: featureName) else {
                return [String]()
            }

            switch featureName {
            case "classLabel":
                return [value.stringValue]
            case  "classLabel_probs":
                var labels = [String]()
                for (k, v) in value.dictionaryValue {
                    if Double(v.floatValue) > confident {
                        guard let label = k as? String else {
                            continue
                        }
                        labels.append(label)
                    }
                }
                return labels
            default:
                return []
            }
        }

        return labels
    }

    public func classify(image: UIImage) async throws -> [String] {
        let confident = 0.1
        var config = MLModelConfiguration()
        config.computeUnits = .all
        config.allowLowPrecisionAccumulationOnGPU = true
        let model = try Resnet50(configuration: config)

        var size = CGSize(width: 224, height: 224)

        guard let pixelBuffer = image.toCVPixelBuffer(targetSize: size) else {
            throw VisumError.failed
        }

        let output = try model.prediction(image: pixelBuffer)
        let features = output.featureNames

        let labels = features.flatMap { (featureName: String) -> [String] in
            guard let value = output.featureValue(for: featureName) else {
                return [String]()
            }

            switch featureName {
            case "classLabel":
                return [value.stringValue]
            case  "classLabel_probs":
                var labels = [String]()
                for (k, v) in value.dictionaryValue {
                    if Double(v.floatValue) > confident {
                        guard let label = k as? String else {
                            continue
                        }
                        labels.append(label)
                    }
                }
                return labels
            default:
                return []
            }
        }

        return labels
    }

    func maskToUIImage(array: MLShapedArray<Int32>, palette: [UIColor], selectedMask: Int = -1) -> UIImage? {
        // Assumes 2D shaped array with shape [height, width]
        let height = array.shape[0]
        let width = array.shape[1]

        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let classIdx = Int(array[scalarAt: [y, x]])
                let color = if selectedMask < 0 {
                    palette[classIdx % palette.count]
                } else if classIdx == selectedMask {
                    UIColor.white
                } else {
                    UIColor.clear
                }
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)

                let idx = (y * width + x) * 4
                pixels[idx] = UInt8(r * 255)
                pixels[idx + 1] = UInt8(g * 255)
                pixels[idx + 2] = UInt8(b * 255)
                pixels[idx + 3] = UInt8(a * 255)
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let context = CGContext(data: &pixels,
                                   width: width,
                                   height: height,
                                   bitsPerComponent: 8,
                                   bytesPerRow: width * 4,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
           let cgImage = context.makeImage() {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }



    func getOrientation(from uiImage: UIImage) -> CGImagePropertyOrientation {
        switch uiImage.imageOrientation {
        case .up:
            return .downMirrored
        case .down:
            return .upMirrored
        case .left:
            return .leftMirrored
        case .right:
            return .rightMirrored
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }

    public func scan(image: UIImage) async throws -> [String] {

        return try await withCheckedThrowingContinuation { continuation in
            do {

                let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])

                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let results = request.results as? [VNRecognizedTextObservation] else {
                        continuation.resume(throwing: VisumError.noResults)
                        return
                    }

                    let values = results.compactMap { result in
                        result.topCandidates(1).first?.string
                    }
                    continuation.resume(returning: values)
                }
                request.recognitionLevel = .accurate
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisumError.failed)
            }
        }
    }

    public func scanBarcode<T: BarcodeScannableImage>(image: T) async throws -> [String] {

        return try await withCheckedThrowingContinuation { continuation in
            do {
                let handler = try image.createRequestHandler(options: [:])

                let request = VNDetectBarcodesRequest { request, error in
                    if let error {
                        continuation.resume(throwing: VisumError.noResults)
                        return
                    }
                    guard let results = request.results as? [VNBarcodeObservation] else {
                        continuation.resume(returning: [])
                        return
                    }

                    let values = results.compactMap { result in
                        result.payloadStringValue
                    }
                    continuation.resume(returning: values)
                }
                try handler.perform([request])
            } catch {
                print(error.localizedDescription)
                continuation.resume(throwing: VisumError.failed)
            }
        }
    }

}

public struct DetectionResult {
    let boundingBox: CGRect
    let confidence: Float
    let label: String
}


extension MLModel {
    /// The segmentation labels specified in the metadata.
    var segmentationLabels: [String] {
        if let metadata = modelDescription.metadata[.creatorDefinedKey] as? [String: Any],
           let params = metadata["com.apple.coreml.model.preview.params"] as? String,
           let data = params.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let labels = parsed["labels"] as? [String] {
            return labels
        } else {
            return []
        }
    }
}

extension MLShapedArray where Scalar: Hashable & Comparable {
    /// Returns a sorted list of all values in the shaped array, and removes duplicates.
    var uniqueValues: [Scalar] {
        Set(scalars).sorted()
    }
}


extension UIImage: BarcodeScannableImage {
    public func createRequestHandler(options: [VNImageOption : Any]) throws -> VNImageRequestHandler {
        guard let cgImage = self.cgImage else {
            throw Visum.VisumError.failed
        }
        return VNImageRequestHandler(cgImage: cgImage, options: options)
    }
}

extension CIImage: BarcodeScannableImage {
    public func createRequestHandler(options: [VNImageOption : Any]) throws -> VNImageRequestHandler {
        return VNImageRequestHandler(ciImage: self, options: options)
    }
}

extension CGImage: BarcodeScannableImage {
    public func createRequestHandler(options: [VNImageOption : Any]) throws -> VNImageRequestHandler {
        return VNImageRequestHandler(cgImage: self, options: options)
    }
}

extension CVPixelBuffer: BarcodeScannableImage {
    public func createRequestHandler(options: [VNImageOption : Any]) throws -> VNImageRequestHandler {
        return VNImageRequestHandler(cvPixelBuffer: self, options: options)
    }
}
