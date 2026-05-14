import AppKit
import Foundation

struct Slide {
    let sourcePath: String
    let fileName: String
    let kicker: String
    let title: String
    let subtitle: String
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputDirectory = root
    .appendingPathComponent("app_store_assets")
    .appendingPathComponent("ios")
    .appendingPathComponent("screenshots_6_9")

try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

let slides = [
    Slide(
        sourcePath: "app_store_assets/ios/source_frames/frame_01.png",
        fileName: "01_pixel_level_redaction.png",
        kicker: "REDACT",
        title: "Pixel-level redaction",
        subtitle: "Cover sensitive areas with real solid pixels, then export a clean copy."
    ),
    Slide(
        sourcePath: "/Users/ziyan/Desktop/Simulator Screenshot - iPhone 17 - 2026-05-13 at 16.38.36.png",
        fileName: "02_remove_private_metadata.png",
        kicker: "METADATA",
        title: "Remove private metadata",
        subtitle: "Clean EXIF, GPS, IPTC, XMP, thumbnails, and comments from images."
    ),
    Slide(
        sourcePath: "/Users/ziyan/Desktop/Simulator Screenshot - iPhone 17 - 2026-05-13 at 16.38.33.png",
        fileName: "03_local_by_design.png",
        kicker: "LOCAL",
        title: "Local by design",
        subtitle: "Open from Files or Photos. Images stay on device unless you share them."
    ),
    Slide(
        sourcePath: "/Users/ziyan/Desktop/Simulator Screenshot - iPhone 17 - 2026-05-13 at 16.40.14.png",
        fileName: "04_export_clean_copies.png",
        kicker: "EXPORT",
        title: "Export clean copies",
        subtitle: "Save to Files, Photos, or Share with PNG and JPEG options."
    ),
    Slide(
        sourcePath: "/Users/ziyan/Desktop/Simulator Screenshot - iPhone 17 - 2026-05-13 at 17.18.56.png",
        fileName: "05_cover_multiple_areas.png",
        kicker: "COVER",
        title: "Cover multiple areas",
        subtitle: "Use black or white solid blocks to match the image and hide sensitive details."
    ),
    Slide(
        sourcePath: "/Users/ziyan/Desktop/Simulator Screenshot - iPhone 17 - 2026-05-13 at 16.38.36.png",
        fileName: "06_two_privacy_tools.png",
        kicker: "WORKFLOW",
        title: "Two privacy tools",
        subtitle: "Switch between pixel redaction and metadata cleaning in one focused app."
    ),
]

let canvasSize = NSSize(width: 1290, height: 2796)
let accent = NSColor(hex: 0x0D7C68)
let ink = NSColor(hex: 0x17211D)
let secondary = NSColor(hex: 0x5F6D66)
let background = NSColor(hex: 0xF6F7F4)
let card = NSColor.white
let stroke = NSColor(hex: 0xDCE2DC)

for slide in slides {
    guard let source = NSImage(contentsOfFile: absolutePath(slide.sourcePath)) else {
        throw NSError(
            domain: "AppStoreAssetGeneration",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not load \(slide.sourcePath)"]
        )
    }

    let image = NSImage(size: canvasSize)
    image.lockFocus()

    background.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

    drawSoftCircle(x: 940, y: 80, radius: 220, color: NSColor(hex: 0xD7ECE5).withAlphaComponent(0.55))
    drawSoftCircle(x: -70, y: 2320, radius: 280, color: NSColor(hex: 0xE5EFEB).withAlphaComponent(0.85))

    drawPill(text: slide.kicker, x: 86, y: 92, width: 196, height: 50)

    drawText(
        slide.title,
        x: 86,
        y: 166,
        width: 1120,
        font: .systemFont(ofSize: 78, weight: .heavy),
        color: ink,
        lineHeight: 1.02
    )

    drawText(
        slide.subtitle,
        x: 88,
        y: 350,
        width: 1050,
        font: .systemFont(ofSize: 34, weight: .semibold),
        color: secondary,
        lineHeight: 1.22
    )

    let phoneWidth: CGFloat = 940
    let phoneHeight = phoneWidth * source.size.height / source.size.width
    let phoneX = (canvasSize.width - phoneWidth) / 2
    let phoneY: CGFloat = 612
    let phoneRect = topRect(x: phoneX, y: phoneY, width: phoneWidth, height: phoneHeight)
    let phonePath = NSBezierPath(roundedRect: phoneRect, xRadius: 48, yRadius: 48)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.shadowBlurRadius = 34
    shadow.set()
    card.setFill()
    phonePath.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    phonePath.addClip()
    source.draw(
        in: phoneRect,
        from: NSRect(origin: .zero, size: source.size),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    stroke.setStroke()
    phonePath.lineWidth = 2
    phonePath.stroke()

    image.unlockFocus()

    let outputURL = outputDirectory.appendingPathComponent(slide.fileName)
    try writePNG(image, to: outputURL)
    print("Wrote \(outputURL.path)")
}

func absolutePath(_ path: String) -> String {
    if path.hasPrefix("/") {
        return path
    }
    return root.appendingPathComponent(path).path
}

func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasSize.height - y - height, width: width, height: height)
}

func drawSoftCircle(x: CGFloat, y: CGFloat, radius: CGFloat, color: NSColor) {
    let rect = topRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
    color.setFill()
    NSBezierPath(ovalIn: rect).fill()
}

func drawPill(text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
    let rect = topRect(x: x, y: y, width: width, height: height)
    NSColor(hex: 0xEAF1ED).setFill()
    let path = NSBezierPath(roundedRect: rect, xRadius: 16, yRadius: 16)
    path.fill()
    stroke.setStroke()
    path.lineWidth = 2
    path.stroke()

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 20, weight: .bold),
        .foregroundColor: accent,
        .kern: 1.4,
    ]
    let attributed = NSAttributedString(string: text, attributes: attrs)
    let textSize = attributed.size()
    attributed.draw(
        at: NSPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )
    )
}

func drawText(
    _ text: String,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    font: NSFont,
    color: NSColor,
    lineHeight: CGFloat
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.minimumLineHeight = font.pointSize * lineHeight
    paragraph.maximumLineHeight = font.pointSize * lineHeight

    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
    let attributed = NSAttributedString(string: text, attributes: attrs)
    let height = attributed.boundingRect(
        with: NSSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    ).height + 8

    attributed.draw(in: topRect(x: x, y: y, width: width, height: height))
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "AppStoreAssetGeneration",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"]
        )
    }
    try png.write(to: url)
}

extension NSColor {
    convenience init(hex: Int) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
