#!/usr/bin/env swift

import AppKit

struct IconVariant {
    let size: CGFloat
    let filename: String
}

let outputDirectory = "Sources/Glimpse/Resources/Assets.xcassets/AppIcon.appiconset"

let variants: [IconVariant] = [
    .init(size: 16, filename: "GlimpseIcon-16.png"),
    .init(size: 32, filename: "GlimpseIcon-32.png"),
    .init(size: 64, filename: "GlimpseIcon-64.png"),
    .init(size: 128, filename: "GlimpseIcon-128.png"),
    .init(size: 256, filename: "GlimpseIcon-256.png"),
    .init(size: 512, filename: "GlimpseIcon-512.png"),
    .init(size: 1024, filename: "GlimpseIcon-1024.png")
]

extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation else { return nil }
        guard let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.225
    let backgroundPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient background (Warp-style)
    context.saveGState()
    context.addPath(backgroundPath)
    context.clip()

    if let bgGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(calibratedRed: 0.95, green: 0.68, blue: 0.56, alpha: 1.0).cgColor,
            NSColor(calibratedRed: 0.85, green: 0.47, blue: 0.34, alpha: 1.0).cgColor,
            NSColor(calibratedRed: 0.72, green: 0.35, blue: 0.22, alpha: 1.0).cgColor
        ] as CFArray,
        locations: [0.0, 0.5, 1.0]
    ) {
        context.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )
    }
    context.restoreGState()

    let centerX = rect.midX
    let centerY = rect.midY

    // Draw geometric symbol (Warp-style: simple chevron/forward arrow)
    let symbolSize = size * 0.45
    let chevronPath = NSBezierPath()

    // Right-pointing chevron (search/forward motion)
    let startX = centerX - symbolSize * 0.35
    let startY = centerY

    chevronPath.move(to: CGPoint(x: startX, y: startY - symbolSize * 0.5))
    chevronPath.line(to: CGPoint(x: startX + symbolSize * 0.7, y: startY))
    chevronPath.line(to: CGPoint(x: startX, y: startY + symbolSize * 0.5))

    NSColor.white.setStroke()
    chevronPath.lineWidth = size * 0.14
    chevronPath.lineCapStyle = .round
    chevronPath.lineJoinStyle = .round
    chevronPath.stroke()

    image.unlockFocus()
    return image
}

for variant in variants {
    let image = drawIcon(size: variant.size)
    guard let data = image.pngData() else {
        fputs("Failed to create PNG data for size \(variant.size)\n", stderr)
        continue
    }

    let url = URL(fileURLWithPath: outputDirectory).appendingPathComponent(variant.filename)
    do {
        try data.write(to: url, options: .atomic)
        print("Generated \(variant.filename)")
    } catch {
        fputs("Failed to write \(variant.filename): \(error)\n", stderr)
    }
}
