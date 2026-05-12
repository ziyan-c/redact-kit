import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 980, height: 640)
    self.title = "Redact Kit"
    setInitialWindowFrame()

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerFileChannel(with: flutterViewController)

    super.awakeFromNib()

    self.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func setInitialWindowFrame() {
    let preferredSize = NSSize(width: 1120, height: 760)
    let targetSize = NSSize(
      width: max(self.frame.width, preferredSize.width),
      height: max(self.frame.height, preferredSize.height)
    )

    guard let screenFrame = self.screen?.visibleFrame ?? NSScreen.main?.visibleFrame else {
      self.setContentSize(targetSize)
      return
    }

    let origin = NSPoint(
      x: screenFrame.midX - targetSize.width / 2,
      y: screenFrame.midY - targetSize.height / 2
    )
    self.setFrame(NSRect(origin: origin, size: targetSize), display: true)
  }

  private func registerFileChannel(with flutterViewController: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "app.redactkit/files",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "window_unavailable", message: "Window is unavailable.", details: nil))
        return
      }

      switch call.method {
      case "openImage":
        self.openImage(result: result)
      case "saveImage":
        self.saveImage(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func openImage(result: FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.resolvesAliases = true

    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = ["png", "jpg", "jpeg", "webp", "bmp"].compactMap {
        UTType(filenameExtension: $0)
      }
    } else {
      panel.allowedFileTypes = ["png", "jpg", "jpeg", "webp", "bmp"]
    }

    guard panel.runModal() == .OK, let url = panel.url else {
      result(nil)
      return
    }

    do {
      let data = try Data(contentsOf: url)
      result([
        "name": url.lastPathComponent,
        "bytes": FlutterStandardTypedData(bytes: data),
      ])
    } catch {
      result(FlutterError(code: "open_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func saveImage(call: FlutterMethodCall, result: FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let name = arguments["name"] as? String,
      let bytes = arguments["bytes"] as? FlutterStandardTypedData,
      let fileExtension = arguments["extension"] as? String
    else {
      result(FlutterError(code: "bad_arguments", message: "Missing image export arguments.", details: nil))
      return
    }

    let normalizedExtension = fileExtension.lowercased() == "jpeg" ? "jpg" : fileExtension.lowercased()
    guard ["png", "jpg"].contains(normalizedExtension) else {
      result(FlutterError(code: "bad_format", message: "Unsupported image export format.", details: nil))
      return
    }

    let panel = NSSavePanel()
    panel.nameFieldStringValue = name
    panel.canCreateDirectories = true

    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = [normalizedExtension == "png" ? UTType.png : UTType.jpeg]
    } else {
      panel.allowedFileTypes = [normalizedExtension]
    }

    guard panel.runModal() == .OK, let url = panel.url else {
      result(nil)
      return
    }

    do {
      try bytes.data.write(to: url, options: .atomic)
      result(url.path)
    } catch {
      result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
    }
  }
}
