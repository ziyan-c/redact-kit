import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 1100, height: 700)
    self.title = "Redact Kit"
    setInitialWindowFrame()

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerFileChannel(binaryMessenger: flutterViewController.engine.binaryMessenger)

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

  private func registerFileChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "app.redactkit/files",
      binaryMessenger: binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      guard call.method == "openDirectory" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(FlutterError(
          code: "bad_args",
          message: "Missing output folder path.",
          details: nil
        ))
        return
      }

      let url = URL(fileURLWithPath: path, isDirectory: true)
      var isDirectory: ObjCBool = false
      guard
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
        isDirectory.boolValue
      else {
        result(FlutterError(
          code: "not_found",
          message: "Output folder does not exist yet.",
          details: path
        ))
        return
      }

      NSWorkspace.shared.open(url)
      result(nil)
    }
  }
}
