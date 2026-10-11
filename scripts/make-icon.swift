import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Could not create icon bitmap") }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        let side = CGFloat(pixels)
        NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.13, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: side * 0.04, y: side * 0.04, width: side * 0.92, height: side * 0.92), xRadius: side * 0.20, yRadius: side * 0.20).fill()
        NSColor(calibratedRed: 0.61, green: 0.68, blue: 0.51, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: side * 0.23, y: side * 0.20, width: side * 0.55, height: side * 0.48), xRadius: side * 0.08, yRadius: side * 0.08).fill()
        NSColor(calibratedRed: 0.78, green: 0.84, blue: 0.69, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: side * 0.20, y: side * 0.31, width: side * 0.60, height: side * 0.43), xRadius: side * 0.08, yRadius: side * 0.08).fill()
        NSColor(calibratedRed: 0.20, green: 0.25, blue: 0.18, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: side * 0.45, y: side * 0.40, width: side * 0.10, height: side * 0.24)).fill()
        NSBezierPath(rect: NSRect(x: side * 0.38, y: side * 0.47, width: side * 0.24, height: side * 0.10)).fill()
        NSGraphicsContext.restoreGraphicsState()
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Could not render icon") }
        let suffix = scale == 2 ? "@2x" : ""
        try png.write(to: output.appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
