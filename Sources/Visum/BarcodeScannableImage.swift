// Protocol to constrain acceptable image types and generate handlers
public protocol BarcodeScannableImage {
    func createRequestHandler(options: [VNImageOption : Any]) throws -> VNImageRequestHandler
}
