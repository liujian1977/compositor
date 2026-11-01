// ImageExporter.swift — CoreIO
/// Write CGImage to PNG/JPEG/PDF files. No AppKit/SwiftUI imports.

import Foundation
import CoreGraphics
import ImageIO

enum ImageExporter {
    /// Write a CGImage to a PNG file at the given URL.
    static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, "public.png" as CFString, 1, nil
        ) else { throw CoreError.renderFailed(reason: "CGImageDestinationCreateWithURL failed") }

        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: 1.0
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw CoreError.renderFailed(reason: "CGImageDestinationFinalize failed for PNG")
        }
    }

    /// Write a CGImage to a JPEG file with the specified quality (0–1).
    static func writeJPEG(_ image: CGImage, to url: URL, quality: Float = 0.92) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, "public.jpeg" as CFString, 1, nil
        ) else { throw CoreError.renderFailed(reason: "CGImageDestinationCreateWithURL failed for JPEG") }

        let compressionQuality = min(1.0, max(0.0, Double(quality)))
        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw CoreError.renderFailed(reason: "CGImageDestinationFinalize failed for JPEG")
        }
    }

    /// Write a CGImage to a PDF file at print size. `resolution` is the target
    /// pixels-per-inch; the physical page size is derived so 1 px maps to
    /// 72/resolution points (72 pt/inch at 72 ppi, smaller at higher ppi).
    static func writePDF(_ image: CGImage, to url: URL, resolution: Double = 72) throws {
        let width = image.width, height = image.height
        let pointsPerPixel = 72.0 / max(resolution, 1.0)
        var mediaBox = CGRect(
            x: 0, y: 0,
            width: CGFloat(width) * CGFloat(pointsPerPixel),
            height: CGFloat(height) * CGFloat(pointsPerPixel)
        )

        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdf = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw CoreError.renderFailed(reason: "Cannot create PDF context at \(url.path)")
        }

        pdf.draw(image, in: mediaBox)
        pdf.closePDF()
    }
}
