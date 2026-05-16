import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Target {
    let directory: String
    let width: Int
    let height: Int
    let mode: DrawMode
}

enum DrawMode {
    case fill
    case fit(background: NSColor)
}

struct SourceImage {
    let url: URL
    let image: NSImage
    let width: CGFloat
    let height: CGFloat
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
let baseOutputRoot = root.appendingPathComponent("app_store_assets/app_store_connect_screenshots")
let isChineseImport = CommandLine.arguments.contains("--zh-Hans")
let outputRoot = isChineseImport
    ? baseOutputRoot.appendingPathComponent("zh-Hans")
    : baseOutputRoot

let phoneSources = try desktopImages(containing: "Simulator Screenshot - iPhone")
let ipadSources = try desktopImages(containing: "Simulator Screenshot - iPad")
let macSources = try desktopImages(containing: "Screenshot ")
    .filter { !$0.lastPathComponent.contains("Simulator Screenshot") }

guard phoneSources.count >= 3 else {
    throw error("Need at least 3 iPhone screenshots on Desktop.")
}
guard ipadSources.count >= 3 else {
    throw error("Need at least 3 iPad screenshots on Desktop.")
}
if !isChineseImport && macSources.count < 3 {
    throw error("Need at least 3 macOS screenshots on Desktop.")
}

var targetSets: [(sources: [URL], targets: [Target])] = [
    (
        sources: Array(phoneSources.prefix(3)),
        targets: [
            Target(directory: "iphone_6_9_1320x2868", width: 1320, height: 2868, mode: .fill),
            Target(directory: "iphone_6_5_1242x2688", width: 1242, height: 2688, mode: .fill),
        ]
    ),
    (
        sources: Array(ipadSources.prefix(3)),
        targets: [
            Target(directory: "ipad_13_2752x2064", width: 2752, height: 2064, mode: .fill),
        ]
    ),
]

if !isChineseImport {
    targetSets.append(
        (
        sources: Array(macSources.prefix(3)),
        targets: [
            Target(directory: "macos_2880x1800", width: 2880, height: 1800, mode: .fit(background: NSColor.black)),
        ]
        )
    )
}

for set in targetSets {
    for target in set.targets {
        let outputDirectory = outputRoot.appendingPathComponent(target.directory)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        for (index, sourceURL) in set.sources.enumerated() {
            let loadedSource = try loadSource(sourceURL)
            let source = target.directory.hasPrefix("macos")
                ? trimBlackBorder(loadedSource, tolerance: 12, padding: 28)
                : loadedSource
            let rendered = render(source: source, target: target)
            let outputURL = outputDirectory.appendingPathComponent(String(format: "%02d.png", index + 1))
            try writePNG(rendered, to: outputURL)
            print("Wrote \(outputURL.path)")
        }
    }
}

func desktopImages(containing token: String) throws -> [URL] {
    let urls = try FileManager.default.contentsOfDirectory(
        at: desktop,
        includingPropertiesForKeys: [.contentModificationDateKey],
        options: [.skipsHiddenFiles]
    )
    return urls
        .filter { url in
            let name = url.lastPathComponent
            return name.contains(token) && name.lowercased().hasSuffix(".png")
        }
        .sorted { left, right in
            left.lastPathComponent.localizedStandardCompare(right.lastPathComponent) == .orderedAscending
        }
}

func render(source: SourceImage, target: Target) -> CGImage {
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
        fatalError("Could not create bitmap context.")
    }

    let context = NSGraphicsContext(cgContext: bitmapContext, flipped: false)
    context.imageInterpolation = .high

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    let destination = NSRect(x: 0, y: 0, width: width, height: height)
    let sourceRect: NSRect
    switch target.mode {
    case .fill:
        NSColor.white.setFill()
        NSBezierPath(rect: destination).fill()
        sourceRect = aspectFillSourceRect(source: source, targetWidth: width, targetHeight: height)
        source.image.draw(in: destination, from: sourceRect, operation: .sourceOver, fraction: 1)
    case .fit(let background):
        background.setFill()
        NSBezierPath(rect: destination).fill()
        let fitRect = aspectFitDestinationRect(source: source, targetWidth: width, targetHeight: height)
        source.image.draw(
            in: fitRect,
            from: NSRect(x: 0, y: 0, width: source.width, height: source.height),
            operation: .sourceOver,
            fraction: 1
        )
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let image = bitmapContext.makeImage() else {
        fatalError("Could not create rendered image.")
    }
    return image
}

func aspectFillSourceRect(source: SourceImage, targetWidth: CGFloat, targetHeight: CGFloat) -> NSRect {
    let sourceRatio = source.width / source.height
    let targetRatio = targetWidth / targetHeight
    if sourceRatio > targetRatio {
        let cropWidth = source.height * targetRatio
        return NSRect(x: (source.width - cropWidth) / 2, y: 0, width: cropWidth, height: source.height)
    }
    let cropHeight = source.width / targetRatio
    return NSRect(x: 0, y: (source.height - cropHeight) / 2, width: source.width, height: cropHeight)
}

func aspectFitDestinationRect(source: SourceImage, targetWidth: CGFloat, targetHeight: CGFloat) -> NSRect {
    let scale = min(targetWidth / source.width, targetHeight / source.height)
    let width = source.width * scale
    let height = source.height * scale
    return NSRect(x: (targetWidth - width) / 2, y: (targetHeight - height) / 2, width: width, height: height)
}

func loadSource(_ url: URL) throws -> SourceImage {
    let data = try Data(contentsOf: url)
    guard let bitmap = NSBitmapImageRep(data: data) else {
        throw error("Could not decode \(url.path)")
    }
    let size = NSSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
    let image = NSImage(size: size)
    image.addRepresentation(bitmap)
    return SourceImage(url: url, image: image, width: CGFloat(bitmap.pixelsWide), height: CGFloat(bitmap.pixelsHigh))
}

func trimBlackBorder(_ source: SourceImage, tolerance: CGFloat, padding: Int) -> SourceImage {
    guard let rep = source.image.representations.compactMap({ $0 as? NSBitmapImageRep }).first,
          let cgImage = rep.cgImage else {
        return source
    }

    var minX = rep.pixelsWide
    var minY = rep.pixelsHigh
    var maxX = 0
    var maxY = 0

    for y in 0..<rep.pixelsHigh {
        for x in 0..<rep.pixelsWide {
            guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                continue
            }
            let brightness = max(color.redComponent, color.greenComponent, color.blueComponent) * 255
            if brightness > tolerance {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    guard minX < maxX, minY < maxY else {
        return source
    }

    minX = max(0, minX - padding)
    minY = max(0, minY - padding)
    maxX = min(rep.pixelsWide - 1, maxX + padding)
    maxY = min(rep.pixelsHigh - 1, maxY + padding)

    let crop = CGRect(
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1
    )
    guard let cropped = cgImage.cropping(to: crop) else {
        return source
    }

    let size = NSSize(width: cropped.width, height: cropped.height)
    return SourceImage(
        url: source.url,
        image: NSImage(cgImage: cropped, size: size),
        width: CGFloat(cropped.width),
        height: CGFloat(cropped.height)
    )
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw error("Could not create PNG destination \(url.path)")
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw error("Could not encode \(url.path)")
    }
}

func error(_ message: String) -> NSError {
    NSError(
        domain: "ImportDesktopAppStoreScreenshots",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: message]
    )
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
