import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("usage: GenerateAppIcon.swift <output.iconset>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let iconFiles: [(name: String, pixels: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawIcon(pixels: CGFloat) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: size)

    image.lockFocus()
    defer { image.unlockFocus() }

    NSGraphicsContext.current?.imageInterpolation = .high
    NSGraphicsContext.current?.shouldAntialias = true

    let rect = NSRect(origin: .zero, size: size)
    let radius = pixels * 0.2
    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let background = NSGradient(colors: [
        NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.07, alpha: 1),
        NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.16, alpha: 1)
    ])
    background?.draw(in: backgroundPath, angle: 90)

    let innerRect = rect.insetBy(dx: pixels * 0.13, dy: pixels * 0.13)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: pixels * 0.12, yRadius: pixels * 0.12)
    NSColor(calibratedRed: 0.90, green: 0.96, blue: 0.86, alpha: 0.08).setFill()
    innerPath.fill()

    let waveColor = NSColor(calibratedRed: 0.57, green: 0.91, blue: 0.74, alpha: 1)
    waveColor.setStroke()

    let midY = pixels * 0.50
    let leftX = pixels * 0.22
    let rightX = pixels * 0.78
    let step = (rightX - leftX) / 8
    let amplitudes: [CGFloat] = [0.14, 0.28, 0.20, 0.35, 0.24, 0.39, 0.18, 0.29, 0.13]

    for (index, amplitude) in amplitudes.enumerated() {
        let x = leftX + CGFloat(index) * step
        let height = pixels * amplitude
        let path = NSBezierPath()
        path.lineWidth = max(2, pixels * 0.028)
        path.lineCapStyle = .round
        path.move(to: NSPoint(x: x, y: midY - height / 2))
        path.line(to: NSPoint(x: x, y: midY + height / 2))
        path.stroke()
    }

    let playPath = NSBezierPath()
    playPath.move(to: NSPoint(x: pixels * 0.44, y: pixels * 0.31))
    playPath.line(to: NSPoint(x: pixels * 0.44, y: pixels * 0.69))
    playPath.line(to: NSPoint(x: pixels * 0.68, y: pixels * 0.50))
    playPath.close()
    NSColor(calibratedWhite: 1, alpha: 0.88).setFill()
    playPath.fill()

    let highlight = NSBezierPath(
        roundedRect: rect.insetBy(dx: pixels * 0.055, dy: pixels * 0.055),
        xRadius: pixels * 0.15,
        yRadius: pixels * 0.15
    )
    NSColor(calibratedWhite: 1, alpha: 0.14).setStroke()
    highlight.lineWidth = max(1, pixels * 0.012)
    highlight.stroke()

    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "GenerateAppIcon", code: 1)
    }

    try data.write(to: url, options: .atomic)
}

for iconFile in iconFiles {
    let image = drawIcon(pixels: iconFile.pixels)
    try writePNG(image, to: outputURL.appendingPathComponent(iconFile.name))
}
