import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Slide {
    let sourceName: String
    let fileName: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let accent: NSColor
}

struct TargetSet {
    let name: String
    let sourceDirectory: String
    let outputDirectory: String
    let width: Int
    let height: Int
    let layout: Layout
}

enum Layout {
    case phone
    case tablet
    case mac
}

struct SourceImage {
    let image: NSImage
    let width: CGFloat
    let height: CGFloat
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let sourceRoot = root.appendingPathComponent("app_store_assets/app_store_connect_screenshots")
let outputRoot = root.appendingPathComponent("app_store_assets/app_store_marketing_screenshots")

let slides = [
    Slide(
        sourceName: "01.png",
        fileName: "01_redact_private_details.png",
        eyebrow: "IMAGE REDACTION",
        title: "Redact private details",
        subtitle: "Cover sensitive areas with real pixels before sharing.",
        accent: NSColor(hex: 0x2E7D73)
    ),
    Slide(
        sourceName: "02.png",
        fileName: "02_flatten_clean_pdfs.png",
        eyebrow: "PDF REDACTION",
        title: "Flatten clean PDFs",
        subtitle: "Redact document pages and export a fresh flattened copy.",
        accent: NSColor(hex: 0x3F6F8F)
    ),
    Slide(
        sourceName: "03.png",
        fileName: "03_remove_hidden_metadata.png",
        eyebrow: "METADATA CLEANUP",
        title: "Remove hidden metadata",
        subtitle: "Clean images and PDFs locally, including batch folders.",
        accent: NSColor(hex: 0x5D7964)
    ),
]

let targetSets = [
    TargetSet(
        name: "iPhone 6.5",
        sourceDirectory: "iphone_6_5_1242x2688",
        outputDirectory: "iphone_6_5_1242x2688",
        width: 1242,
        height: 2688,
        layout: .phone
    ),
    TargetSet(
        name: "iPhone 6.9",
        sourceDirectory: "iphone_6_9_1320x2868",
        outputDirectory: "iphone_6_9_1320x2868",
        width: 1320,
        height: 2868,
        layout: .phone
    ),
    TargetSet(
        name: "iPad 13",
        sourceDirectory: "ipad_13_2752x2064",
        outputDirectory: "ipad_13_2752x2064",
        width: 2752,
        height: 2064,
        layout: .tablet
    ),
    TargetSet(
        name: "macOS",
        sourceDirectory: "macos_2880x1800",
        outputDirectory: "macos_2880x1800",
        width: 2880,
        height: 1800,
        layout: .mac
    ),
]

let ink = NSColor(hex: 0x161B18)
let secondary = NSColor(hex: 0x5C645F)
let paper = NSColor(hex: 0xF7F7F4)
let softPaper = NSColor(hex: 0xEEF4F0)
let border = NSColor(hex: 0xD9E1DC)
let white = NSColor.white

for target in targetSets {
    let outputDirectory = outputRoot.appendingPathComponent(target.outputDirectory)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    for slide in slides {
        let sourceURL = sourceRoot
            .appendingPathComponent(target.sourceDirectory)
            .appendingPathComponent(slide.sourceName)
        let source = try loadSource(sourceURL)
        let image = render(slide: slide, source: source, target: target)
        let outputURL = outputDirectory.appendingPathComponent(slide.fileName)
        try writePNG(image, to: outputURL)
        print("Wrote \(target.name): \(outputURL.path)")
    }
}

func render(slide: Slide, source: SourceImage, target: TargetSet) -> CGImage {
    let width = CGFloat(target.width)
    let height = CGFloat(target.height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let bitmapContext = CGContext(
        data: nil,
        width: target.width,
        height: target.height,
        bitsPerComponent: 8,
        bytesPerRow: target.width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        fatalError("Could not create bitmap context")
    }

    let context = NSGraphicsContext(cgContext: bitmapContext, flipped: false)
    context.imageInterpolation = .high

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    drawBackground(width: width, height: height)

    switch target.layout {
    case .phone:
        drawPhoneSlide(slide: slide, source: source, width: width, height: height)
    case .tablet:
        drawTabletSlide(slide: slide, source: source, width: width, height: height)
    case .mac:
        drawMacSlide(slide: slide, source: source, width: width, height: height)
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let image = bitmapContext.makeImage() else {
        fatalError("Could not create rendered image")
    }
    return image
}

func drawBackground(width: CGFloat, height: CGFloat) {
    paper.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

    softPaper.withAlphaComponent(0.78).setFill()
    NSBezierPath(
        roundedRect: topRect(x: width * 0.06, y: height * 0.30, width: width * 0.88, height: height * 0.64, canvasHeight: height),
        xRadius: 36,
        yRadius: 36
    ).fill()
}

func drawPhoneSlide(slide: Slide, source: SourceImage, width: CGFloat, height: CGFloat) {
    let margin = width * 0.075
    drawCopy(slide: slide, x: margin, y: 118, width: width - margin * 2, titleSize: width * 0.071, subtitleSize: width * 0.030, canvasHeight: height)

    let maxFrameWidth = width * 0.78
    let maxFrameHeight = height * 0.70
    var frameWidth = maxFrameWidth
    var frameHeight = frameWidth * source.height / source.width
    if frameHeight > maxFrameHeight {
        frameHeight = maxFrameHeight
        frameWidth = frameHeight * source.width / source.height
    }

    let rect = topRect(
        x: (width - frameWidth) / 2,
        y: height - frameHeight - 74,
        width: frameWidth,
        height: frameHeight,
        canvasHeight: height
    )
    drawFramedImage(source, in: rect, cornerRadius: width * 0.055, shadowBlur: 32, shadowY: -18)
}

func drawTabletSlide(slide: Slide, source: SourceImage, width: CGFloat, height: CGFloat) {
    let margin = width * 0.07
    drawCopy(slide: slide, x: margin, y: 86, width: width * 0.66, titleSize: width * 0.038, subtitleSize: width * 0.017, canvasHeight: height)

    let maxFrameWidth = width * 0.82
    let maxFrameHeight = height * 0.72
    var frameWidth = maxFrameWidth
    var frameHeight = frameWidth * source.height / source.width
    if frameHeight > maxFrameHeight {
        frameHeight = maxFrameHeight
        frameWidth = frameHeight * source.width / source.height
    }

    let rect = topRect(
        x: (width - frameWidth) / 2,
        y: height - frameHeight - 86,
        width: frameWidth,
        height: frameHeight,
        canvasHeight: height
    )
    drawFramedImage(source, in: rect, cornerRadius: 34, shadowBlur: 34, shadowY: -18)
}

func drawMacSlide(slide: Slide, source: SourceImage, width: CGFloat, height: CGFloat) {
    let margin = width * 0.065
    drawCopy(slide: slide, x: margin, y: 72, width: width * 0.62, titleSize: width * 0.032, subtitleSize: width * 0.014, canvasHeight: height)

    let maxFrameWidth = width * 0.82
    let maxFrameHeight = height * 0.70
    var frameWidth = maxFrameWidth
    var frameHeight = frameWidth * source.height / source.width
    if frameHeight > maxFrameHeight {
        frameHeight = maxFrameHeight
        frameWidth = frameHeight * source.width / source.height
    }

    let rect = topRect(
        x: (width - frameWidth) / 2,
        y: height - frameHeight - 70,
        width: frameWidth,
        height: frameHeight,
        canvasHeight: height
    )
    drawFramedImage(source, in: rect, cornerRadius: 28, shadowBlur: 34, shadowY: -20)
}

func drawCopy(
    slide: Slide,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    titleSize: CGFloat,
    subtitleSize: CGFloat,
    canvasHeight: CGFloat
) {
    let pillHeight = max(42, titleSize * 0.58)
    drawPill(
        text: slide.eyebrow,
        x: x,
        y: y,
        width: max(210, titleSize * 4.5),
        height: pillHeight,
        color: slide.accent,
        canvasHeight: canvasHeight
    )

    let titleY = y + pillHeight + titleSize * 0.34
    let titleHeight = drawText(
        slide.title,
        x: x,
        y: titleY,
        width: width,
        font: .systemFont(ofSize: titleSize, weight: .heavy),
        color: ink,
        lineHeight: 1.02,
        canvasHeight: canvasHeight
    )

    let subtitleY = titleY + titleHeight + titleSize * 0.18
    drawText(
        slide.subtitle,
        x: x,
        y: subtitleY,
        width: width,
        font: .systemFont(ofSize: subtitleSize, weight: .semibold),
        color: secondary,
        lineHeight: 1.18,
        canvasHeight: canvasHeight
    )
}

func drawPill(text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: NSColor, canvasHeight: CGFloat) {
    let rect = topRect(x: x, y: y, width: width, height: height, canvasHeight: canvasHeight)
    color.withAlphaComponent(0.10).setFill()
    let path = NSBezierPath(roundedRect: rect, xRadius: height / 2, yRadius: height / 2)
    path.fill()
    color.withAlphaComponent(0.18).setStroke()
    path.lineWidth = 1.5
    path.stroke()

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: height * 0.36, weight: .bold),
        .foregroundColor: color,
        .kern: 1.2,
    ]
    let attributed = NSAttributedString(string: text, attributes: attrs)
    let size = attributed.size()
    attributed.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
}

func drawFramedImage(_ source: SourceImage, in rect: NSRect, cornerRadius: CGFloat, shadowBlur: CGFloat, shadowY: CGFloat) {
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
    shadow.shadowOffset = NSSize(width: 0, height: shadowY)
    shadow.shadowBlurRadius = shadowBlur
    shadow.set()
    white.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    source.image.draw(
        in: rect,
        from: NSRect(x: 0, y: 0, width: source.width, height: source.height),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    border.setStroke()
    path.lineWidth = 2
    path.stroke()
}

@discardableResult
func drawText(
    _ text: String,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    font: NSFont,
    color: NSColor,
    lineHeight: CGFloat,
    canvasHeight: CGFloat
) -> CGFloat {
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
    ).height + 10

    attributed.draw(in: topRect(x: x, y: y, width: width, height: height, canvasHeight: canvasHeight))
    return height
}

func topRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, canvasHeight: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasHeight - y - height, width: width, height: height)
}

func loadSource(_ url: URL) throws -> SourceImage {
    let data = try Data(contentsOf: url)
    guard let bitmap = NSBitmapImageRep(data: data) else {
        throw NSError(
            domain: "AppStoreMarketingScreenshots",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not decode \(url.path)"]
        )
    }
    let size = NSSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
    let image = NSImage(size: size)
    image.addRepresentation(bitmap)
    return SourceImage(image: image, width: CGFloat(bitmap.pixelsWide), height: CGFloat(bitmap.pixelsHigh))
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(
            domain: "AppStoreMarketingScreenshots",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Could not create PNG destination \(url.path)"]
        )
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(
            domain: "AppStoreMarketingScreenshots",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Could not encode \(url.path)"]
        )
    }
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
