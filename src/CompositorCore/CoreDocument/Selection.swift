// Selection.swift — CoreDocument
// Pure data types for document-space selection outlines. No AppKit/SwiftUI imports.

import Foundation
@preconcurrency import CoreGraphics

#if canImport(CoreImage)
import CoreImage
#endif

/// A document-space selection outline, clipped to the canvas.
struct DocumentSelection: Sendable {
    let path: CGPath
    var antialiased = true
    /// How far the edge fades, in document pixels. 0 is a hard edge.
    var feather: CGFloat = 0

    var isEmpty: Bool {
        path.isEmpty || path.boundingBoxOfPath.isNull || path.boundingBoxOfPath.isEmpty
    }

    /// Grayscale coverage at document resolution (white = selected), top-left origin.
    func coverage(width: Int, height: Int) throws -> CGImage {
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { throw RenderError.render }

        // Fill background black (not selected)
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw selection path white (selected)
        context.setShouldAntialias(antialiased || feather > 0)
        context.setFillColor(gray: 1, alpha: 1)
        context.addPath(path)
        context.fillPath(using: .evenOdd)

        guard let image = context.makeImage() else { throw RenderError.render }
        guard feather > 0 else { return image }

        // Feather the edge with a Gaussian blur
        #if canImport(CoreImage)
        let extent = CGRect(x: 0, y: 0, width: width, height: height)
        let soft = CIImage(cgImage: image).clampedToExtent()
            .applyingGaussianBlur(sigma: feather / 2).cropped(to: extent)
        return try Self.render(ciImage: soft, width: width, height: height)
        #else
        // Fallback without CoreImage: return un-feathered mask
        return image
        #endif
    }

    /// Render a CIImage to CGImage. Only available when CoreImage is linked.
    #if canImport(CoreImage)
    private static func render(ciImage: CIImage, width: Int, height: Int) throws -> CGImage {
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw RenderError.render
        }
        return cgImage
    }
    #endif
}

/// Selection coverage for one region of the document. Applied as a clip mask.
struct SelectionClip: Sendable {
    let rect: CGRect
    let coverage: CGImage?

    var isEmpty: Bool { coverage == nil || rect.isEmpty }
}

enum RenderError: LocalizedError {
    case render
    var errorDescription: String? { "Failed to create or render image context" }
}
