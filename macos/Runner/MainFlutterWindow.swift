import Cocoa
import FlutterMacOS

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
}
