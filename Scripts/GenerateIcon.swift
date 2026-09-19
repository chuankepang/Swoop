import AppKit

let destination = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.icns"
let destURL = URL(fileURLWithPath: destination)
let destDir = destURL.deletingLastPathComponent()
try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

func drawSwoop(in rect: NSRect, color: NSColor) {
    color.setStroke()
    let path = NSBezierPath()
    path.move(to: NSPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.38))
    path.curve(
        to: NSPoint(x: rect.maxX - rect.width * 0.06, y: rect.maxY - rect.height * 0.22),
        controlPoint1: NSPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.02),
        controlPoint2: NSPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY - rect.height * 0.02)
    )
    path.lineWidth = max(2, rect.width * 0.18)
    path.lineCapStyle = .round
    path.stroke()

    let accent = NSBezierPath()
    accent.move(to: NSPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.58))
    accent.curve(
        to: NSPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.28),
        controlPoint1: NSPoint(x: rect.midX, y: rect.midY + rect.height * 0.18),
        controlPoint2: NSPoint(x: rect.midX + rect.width * 0.18, y: rect.minY + rect.height * 0.42)
    )
    accent.lineWidth = max(1.5, rect.width * 0.10)
    accent.lineCapStyle = .round
    accent.stroke()
}

let masterSize = 1024
let master = NSImage(size: NSSize(width: masterSize, height: masterSize))
master.lockFocus()
let square = NSRect(x: 80, y: 80, width: masterSize - 160, height: masterSize - 160)
NSColor(srgbRed: 0.16, green: 0.46, blue: 0.92, alpha: 1).setFill()
NSBezierPath(roundedRect: square, xRadius: 230, yRadius: 230).fill()
drawSwoop(in: square.insetBy(dx: 180, dy: 180), color: .white)
master.unlockFocus()

func png(from image: NSImage, size: Int) -> Data? {
    let scaled = NSImage(size: NSSize(width: size, height: size))
    scaled.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: .zero,
        operation: .copy,
        fraction: 1
    )
    scaled.unlockFocus()
    guard let tiff = scaled.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
    return bitmap.representation(using: .png, properties: [:])
}

let iconset = destDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
do {
    try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
} catch {
    fputs("Failed to create iconset: \(error)\n", stderr)
    exit(1)
}

let entries: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in entries {
    guard let data = png(from: master, size: size) else {
        fputs("Failed to rasterize \(name)\n", stderr)
        exit(1)
    }
    do {
        try data.write(to: iconset.appendingPathComponent(name))
    } catch {
        fputs("Failed to write \(name): \(error)\n", stderr)
        exit(1)
    }
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", destURL.path]
do {
    try process.run()
    process.waitUntilExit()
} catch {
    fputs("iconutil failed: \(error)\n", stderr)
    exit(1)
}
if process.terminationStatus != 0 {
    exit(Int32(process.terminationStatus))
}
try? FileManager.default.removeItem(at: iconset)
