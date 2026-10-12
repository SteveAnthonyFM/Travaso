// Builds Travaso's app icon set from a source picture of the icon.
// Usage: swift Scripts/make-icon.swift <source image>
//
// The source shows the icon (a rounded square) on a plain background. This script finds the
// square where it differs from the background, crops inside its edge, fits it into the standard
// macOS icon size/corner shape without stretching, makes everything outside transparent, and
// writes all sizes into Travaso/Assets.xcassets.
import AppKit

let args = CommandLine.arguments
guard args.count > 1, let data = try? Data(contentsOf: URL(fileURLWithPath: args[1])),
      let source = NSBitmapImageRep(data: data), let sourceImage = source.cgImage else {
    print("Usage: swift Scripts/make-icon.swift <source image>"); exit(1)
}

func rgb(_ x: Int, _ y: Int) -> (CGFloat, CGFloat, CGFloat) {
    let c = source.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
    return (c.redComponent, c.greenComponent, c.blueComponent)
}

// Find the square: scan from the middle of each edge until the pixel differs from the background
// (the top-left corner pixel).
let background = rgb(0, 0)
func isIcon(_ x: Int, _ y: Int) -> Bool {
    let c = rgb(x, y)
    return max(abs(c.0 - background.0), abs(c.1 - background.1), abs(c.2 - background.2)) > 0.06
}
let w = source.pixelsWide, h = source.pixelsHigh
var left = 0;  while left < w / 2 && !isIcon(left, h / 2) { left += 1 }
var right = w - 1; while right > w / 2 && !isIcon(right, h / 2) { right -= 1 }
var top = 0;   while top < h / 2 && !isIcon(w / 2, top) { top += 1 }
var bottom = h - 1; while bottom > h / 2 && !isIcon(w / 2, bottom) { bottom -= 1 }

// Trim past the source's own beveled edge so only the icon's face is kept.
let inset = 12
let crop = CGRect(x: left + inset, y: top + inset,
                  width: right - left - 2 * inset, height: bottom - top - 2 * inset)
guard let cropped = sourceImage.cropping(to: crop) else { print("Crop failed"); exit(1) }
print("Icon found at \(crop)")

// The face color just inside the crop, used to fill any space left by a non-square source.
let fill: NSColor = {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, n: CGFloat = 0
    let x0 = Int(crop.minX), x1 = Int(crop.maxX) - 1, y0 = Int(crop.minY), y1 = Int(crop.maxY) - 1
    for y in stride(from: y0, through: y1, by: 4) {
        for x in [x0, x0 + 2, x1 - 2, x1] { let c = rgb(x, y); r += c.0; g += c.1; b += c.2; n += 1 }
    }
    return NSColor(deviceRed: r / n, green: g / n, blue: b / n, alpha: 1)
}()

// Corner radius (in source pixels) that hides the source square's own rounded corners.
let cornerTrim: CGFloat = 80

// macOS icon grid: 1024 canvas, 824 body, ~22.5% corner radius.
func render(size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    let scale = CGFloat(size) / 1024
    let body = CGRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale)
    let path = NSBezierPath(roundedRect: body, xRadius: 185 * scale, yRadius: 185 * scale)
    path.addClip()
    fill.setFill()
    body.fill()
    // Fit the face inside the body, keeping its proportions.
    let fit = min(body.width / crop.width, body.height / crop.height)
    let drawn = CGSize(width: crop.width * fit, height: crop.height * fit)
    let face = CGRect(x: body.midX - drawn.width / 2, y: body.midY - drawn.height / 2,
                      width: drawn.width, height: drawn.height)
    // Round the face's corners past the source's own, so its background never shows through.
    NSBezierPath(roundedRect: face, xRadius: cornerTrim * fit, yRadius: cornerTrim * fit).addClip()
    ctx.cgContext.draw(cropped, in: face)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let setDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Travaso/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: setDir, withIntermediateDirectories: true)

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try render(size: points * scale).write(to: setDir.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: setDir.appendingPathComponent("Contents.json"))
let catalog = setDir.deletingLastPathComponent().appendingPathComponent("Contents.json")
try #"{ "info" : { "author" : "xcode", "version" : 1 } }"#.write(to: catalog, atomically: true, encoding: .utf8)
print("Wrote \(images.count) icon sizes to \(setDir.path)")
