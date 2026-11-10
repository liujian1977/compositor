// ImageExporter.swift — CoreIO
/// Write CGImage to PNG/JPEG/PDF files. No AppKit/SwiftUI imports.

import Foundation
import CoreGraphics
import ImageIO

public enum ImageExporter {
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

    /// Write straight (non-premultiplied) RGBA8 pixels to a PNG.
    ///
    /// `rgba` is row-major R, G, B, A and `rgba.count` must be `width * height * 4`.
    /// Alpha is stored as given — callers that want a mask cutout pass the mask in A
    /// and the original color in RGB. The CGImage uses `CGImageAlphaInfo.last`
    /// (component order R, G, B, A). This path is CoreGraphics and is not exercised
    /// by the Linux C tests.
    public static func writeStraightRGBAPNG(_ rgba: [UInt8], width: Int, height: Int, to url: URL) throws {
        guard width > 0, height > 0 else { throw CoreError.invalidData }
        let count = width * height
        guard count / width == height, rgba.count == count * 4 else { throw CoreError.invalidData }

        let data = Data(rgba) as CFData
        guard let provider = CGDataProvider(data: data) else {
            throw CoreError.renderFailed(reason: "CGDataProvider failed for straight RGBA")
        }
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
        guard let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw CoreError.renderFailed(reason: "CGImage creation failed for straight RGBA")
        }
        try writePNG(image, to: url)
    }
}
