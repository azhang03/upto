// Renders the background art for the release DMG window.
//
// Run from the repo root:
//   swift Design/dmg/render-background.swift
//
// The script draws the art at 1x and 2x, writes the PNGs to build/dmg-art,
// and combines them into Design/dmg/background.tiff. Finder reads the TIFF
// and picks the correct resolution for the display.
//
// The colors below are the app theme tokens. Keep them in step with
// Sources/upto/Theme/Theme.swift if the palette ever changes.

import AppKit

// Window content size in points. The DMG window is created at this size,
// so the art and the window must agree.
let canvas = NSSize(width: 660, height: 420)

// Icon centers in Finder coordinates (top left origin). The authoring
// script places upto.app and the Applications link at these points.
let appIconCenter = NSPoint(x: 165, y: 195)
let applicationsIconCenter = NSPoint(x: 495, y: 195)

// Theme tokens.
func rgb(_ hex: UInt32, _ alpha: CGFloat = 1.0) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha)
}
let bgWindow = rgb(0x23262C)
let accent = rgb(0x6ED0B1)
let textPrimary = rgb(0xF2F3F4)
let watermarkInk = NSColor.white.withAlphaComponent(0.035)

// Flips a Finder y coordinate into the unflipped drawing space.
func flip(_ y: CGFloat) -> CGFloat { canvas.height - y }

// A rounded cross, the app's D-pad mark. Size is the tip to tip span.
func crossPath(center: NSPoint, size: CGFloat) -> NSBezierPath {
    let arm = size * 0.34
    let radius = arm * 0.28
    let path = NSBezierPath()
    path.append(NSBezierPath(roundedRect: NSRect(x: center.x - arm / 2, y: center.y - size / 2, width: arm, height: size),
                             xRadius: radius, yRadius: radius))
    path.append(NSBezierPath(roundedRect: NSRect(x: center.x - size / 2, y: center.y - arm / 2, width: size, height: arm),
                             xRadius: radius, yRadius: radius))
    return path
}

func draw() {
    // Ground.
    bgWindow.setFill()
    NSRect(origin: .zero, size: canvas).fill()

    // Watermark: an oversized faint cross behind everything, with the
    // open ring center the connected menu bar glyph uses.
    let watermarkCenter = NSPoint(x: canvas.width / 2, y: flip(210))
    watermarkInk.setFill()
    crossPath(center: watermarkCenter, size: 360).fill()
    bgWindow.setFill()
    NSBezierPath(ovalIn: NSRect(x: watermarkCenter.x - 58, y: watermarkCenter.y - 58, width: 116, height: 116)).fill()
    watermarkInk.setStroke()
    let ring = NSBezierPath(ovalIn: NSRect(x: watermarkCenter.x - 36, y: watermarkCenter.y - 36, width: 72, height: 72))
    ring.lineWidth = 12
    ring.stroke()

    // Arrow from the app icon slot to the Applications slot.
    let arrowY = flip(appIconCenter.y)
    let arrow = NSBezierPath()
    arrow.lineWidth = 5
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: 252, y: arrowY))
    arrow.line(to: NSPoint(x: 402, y: arrowY))
    arrow.move(to: NSPoint(x: 384, y: arrowY + 14))
    arrow.line(to: NSPoint(x: 402, y: arrowY))
    arrow.line(to: NSPoint(x: 384, y: arrowY - 14))
    accent.withAlphaComponent(0.85).setStroke()
    arrow.stroke()

    // Label pills under the icon slots. Finder draws file names in black
    // over a background picture, so each name gets an accent capsule to
    // sit on, the same pairing the app uses for its accent buttons.
    func labelPill(center: NSPoint, width: CGFloat) {
        let rect = NSRect(x: center.x - width / 2, y: flip(center.y) - 12, width: width, height: 24)
        accent.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12).fill()
    }
    labelPill(center: NSPoint(x: appIconCenter.x, y: 277), width: 64)
    labelPill(center: NSPoint(x: applicationsIconCenter.x, y: 277), width: 112)

    // Brand group top left: small mark plus the lowercase wordmark,
    // matching the app header.
    let markCenter = NSPoint(x: 38, y: flip(38))
    accent.setFill()
    crossPath(center: markCenter, size: 18).fill()
    let wordmark = NSAttributedString(string: "upto", attributes: [
        .font: NSFont.systemFont(ofSize: 20, weight: .bold),
        .foregroundColor: textPrimary,
    ])
    wordmark.draw(at: NSPoint(x: 54, y: flip(38) - wordmark.size().height / 2))
}

func render(scale: Int) -> Data {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: Int(canvas.width) * scale,
                                     pixelsHigh: Int(canvas.height) * scale,
                                     bitsPerSample: 8,
                                     samplesPerPixel: 4,
                                     hasAlpha: true,
                                     isPlanar: false,
                                     colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0,
                                     bitsPerPixel: 0) else {
        fatalError("Could not create a bitmap at scale \(scale)")
    }
    // Setting the point size before drawing makes the context scale
    // point coordinates to pixels on its own. Do not add a transform.
    rep.size = canvas
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode the PNG at scale \(scale)")
    }
    return png
}

// Resolve paths from the script location so the output always lands in the repo.
let dmgDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let repoRoot = dmgDir.deletingLastPathComponent().deletingLastPathComponent()
let artDir = repoRoot.appendingPathComponent("build/dmg-art")
try FileManager.default.createDirectory(at: artDir, withIntermediateDirectories: true)

let png1x = artDir.appendingPathComponent("background.png")
let png2x = artDir.appendingPathComponent("background@2x.png")
try render(scale: 1).write(to: png1x)
try render(scale: 2).write(to: png2x)

// Combine both scales into one TIFF that Finder treats as high resolution.
let tiff = dmgDir.appendingPathComponent("background.tiff")
let tiffutil = Process()
tiffutil.executableURL = URL(fileURLWithPath: "/usr/bin/tiffutil")
tiffutil.arguments = ["-cathidpicheck", png1x.path, png2x.path, "-out", tiff.path]
try tiffutil.run()
tiffutil.waitUntilExit()
guard tiffutil.terminationStatus == 0 else {
    fatalError("tiffutil failed with status \(tiffutil.terminationStatus)")
}

print("Wrote \(tiff.path)")
print("Preview at \(png2x.path)")
