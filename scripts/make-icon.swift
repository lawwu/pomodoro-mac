// Renders the tomato app icon and writes an .icns file.
// Usage: swift scripts/make-icon.swift <output.icns>
import AppKit

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icns"

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func drawIcon(_ ctx: CGContext, size s: CGFloat) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    ctx.scaleBy(x: s / 1024, y: s / 1024)

    // macOS icon grid: 824pt rounded square centered in a 1024 canvas.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    // Drop shadow + background.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
    ctx.addPath(tilePath)
    ctx.setFillColor(color(0xFFF4E6))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    let bg = CGGradient(colorsSpace: space, colors: [color(0xFFF8EE), color(0xFCE3CF)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    ctx.restoreGState()

    // Tomato body.
    let body = CGRect(x: 232, y: 196, width: 560, height: 520)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 24, color: color(0x7A1A10, 0.35))
    ctx.addEllipse(in: body)
    ctx.setFillColor(color(0xE0412F))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addEllipse(in: body)
    ctx.clip()
    let red = CGGradient(
        colorsSpace: space,
        colors: [color(0xFF7A5C), color(0xE8402D), color(0xB8261A)] as CFArray,
        locations: [0, 0.55, 1]
    )!
    ctx.drawRadialGradient(
        red,
        startCenter: CGPoint(x: 420, y: 560), startRadius: 10,
        endCenter: CGPoint(x: 512, y: 456), endRadius: 330,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    ctx.restoreGState()

    // Highlight.
    ctx.saveGState()
    ctx.translateBy(x: 365, y: 560)
    ctx.rotate(by: .pi / 5)
    ctx.addEllipse(in: CGRect(x: -70, y: -36, width: 140, height: 72))
    ctx.setFillColor(color(0xFFFFFF, 0.38))
    ctx.fillPath()
    ctx.restoreGState()

    // Sepals: a five-pointed green star sitting on top.
    let center = CGPoint(x: 512, y: 690)
    let star = CGMutablePath()
    let points = 5
    for i in 0..<(points * 2) {
        let angle = CGFloat(i) * .pi / CGFloat(points) + .pi / 2
        let r: CGFloat = i % 2 == 0 ? 150 : 42
        let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r * 0.5)
        i == 0 ? star.move(to: p) : star.addLine(to: p)
    }
    star.closeSubpath()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 8, color: color(0x1F4A12, 0.4))
    ctx.addPath(star)
    ctx.setFillColor(color(0x4CA53A))
    ctx.setStrokeColor(color(0x3A8A2B))
    ctx.setLineWidth(14)
    ctx.setLineJoin(.round)
    ctx.drawPath(using: .fillStroke)
    ctx.restoreGState()

    // Stem.
    let stem = CGMutablePath()
    stem.move(to: CGPoint(x: 498, y: 695))
    stem.addQuadCurve(to: CGPoint(x: 540, y: 800), control: CGPoint(x: 492, y: 770))
    ctx.addPath(stem)
    ctx.setStrokeColor(color(0x2F7A22))
    ctx.setLineWidth(30)
    ctx.setLineCap(.round)
    ctx.strokePath()
}

func png(size: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let gctx = NSGraphicsContext(bitmapImageRep: rep)!
    drawIcon(gctx.cgContext, size: CGFloat(size))
    gctx.flushGraphics()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try png(size: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try png(size: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", output]
try task.run()
task.waitUntilExit()
try? fm.removeItem(at: iconset)
guard task.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Wrote \(output)")
