import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var fileChannelHandler: RedactKitFileChannelHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let handler = RedactKitFileChannelHandler()
    handler.register(binaryMessenger: engineBridge.applicationRegistrar.messenger())
    fileChannelHandler = handler
  }
}

final class RedactKitFileChannelHandler: NSObject, UIDocumentPickerDelegate {
  private let fileManager = FileManager.default
  private var pendingResult: FlutterResult?

  func register(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "app.redactkit/files",
      binaryMessenger: binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "chooseMetadataFilesOrFolder" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.chooseMetadataFilesOrFolder(result: result)
    }
  }

  private func chooseMetadataFilesOrFolder(result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(
        code: "picker_busy",
        message: "A file picker is already open.",
        details: nil
      ))
      return
    }

    guard let presenter = UIApplication.shared.redactKitTopViewController else {
      result(FlutterError(
        code: "no_presenter",
        message: "Could not open the file picker.",
        details: nil
      ))
      return
    }

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [.image, .pdf, .folder],
        asCopy: false
      )
    } else {
      picker = UIDocumentPickerViewController(
        documentTypes: ["public.image", "com.adobe.pdf", "public.folder"],
        in: .open
      )
    }
    picker.allowsMultipleSelection = true
    picker.delegate = self
    pendingResult = result
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    do {
      pendingResult?(try copyPickedUrlsIntoSandbox(urls))
    } catch {
      pendingResult?(FlutterError(
        code: "copy_failed",
        message: "Could not prepare selected files.",
        details: error.localizedDescription
      ))
    }
    pendingResult = nil
  }

  private func copyPickedUrlsIntoSandbox(_ urls: [URL]) throws -> [String] {
    try validateSingleFolderSelection(urls)

    let root = fileManager.temporaryDirectory
      .appendingPathComponent("redact-kit-metadata-inputs", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try fileManager.createDirectory(at: root, withIntermediateDirectories: true)

    var copiedPaths = [String]()
    for url in urls {
      let scoped = url.startAccessingSecurityScopedResource()
      defer {
        if scoped {
          url.stopAccessingSecurityScopedResource()
        }
      }

      if let copiedUrl = try copySupportedItem(from: url, into: root) {
        copiedPaths.append(copiedUrl.path)
      }
    }

    return copiedPaths
  }

  private func validateSingleFolderSelection(_ urls: [URL]) throws {
    var folderCount = 0
    for url in urls {
      let scoped = url.startAccessingSecurityScopedResource()
      defer {
        if scoped {
          url.stopAccessingSecurityScopedResource()
        }
      }

      var isDirectory: ObjCBool = false
      if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
         isDirectory.boolValue {
        folderCount += 1
      }
    }

    if folderCount > 0 && urls.count != 1 {
      throw RedactKitPickerError.oneFolderOnly
    }
  }

  private func copySupportedItem(from url: URL, into directory: URL) throws -> URL? {
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      return nil
    }

    if isDirectory.boolValue {
      return try copySupportedDirectory(from: url, into: directory)
    }

    guard isSupportedFile(url) else {
      return nil
    }

    return try copyFile(from: url, into: directory)
  }

  private func copySupportedDirectory(from url: URL, into directory: URL) throws -> URL? {
    let destination = uniqueDestination(
      in: directory,
      preferredName: url.lastPathComponent.isEmpty ? "Folder" : url.lastPathComponent
    )
    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

    let children = try fileManager.contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    )

    var copiedAny = false
    for child in children where isSupportedFile(child) {
      _ = try copyFile(from: child, into: destination)
      copiedAny = true
    }

    return copiedAny ? destination : nil
  }

  private func copyFile(from url: URL, into directory: URL) throws -> URL {
    let destination = uniqueDestination(in: directory, preferredName: url.lastPathComponent)
    try fileManager.copyItem(at: url, to: destination)
    return destination
  }

  private func uniqueDestination(in directory: URL, preferredName: String) -> URL {
    let fallbackName = preferredName.isEmpty ? "file" : preferredName
    let baseUrl = directory.appendingPathComponent(fallbackName)
    if !fileManager.fileExists(atPath: baseUrl.path) {
      return baseUrl
    }

    let name = (fallbackName as NSString).deletingPathExtension
    let ext = (fallbackName as NSString).pathExtension
    var index = 2
    while true {
      let nextName = ext.isEmpty ? "\(name)-\(index)" : "\(name)-\(index).\(ext)"
      let candidate = directory.appendingPathComponent(nextName)
      if !fileManager.fileExists(atPath: candidate.path) {
        return candidate
      }
      index += 1
    }
  }

  private func isSupportedFile(_ url: URL) -> Bool {
    switch url.pathExtension.lowercased() {
    case "png", "jpg", "jpeg", "webp", "bmp", "pdf":
      return true
    default:
      return false
    }
  }
}

enum RedactKitPickerError: LocalizedError {
  case oneFolderOnly

  var errorDescription: String? {
    switch self {
    case .oneFolderOnly:
      return "Choose one folder at a time, or choose image/PDF files without a folder."
    }
  }
}

private extension UIApplication {
  var redactKitTopViewController: UIViewController? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)?
      .rootViewController?
      .redactKitTopMostViewController
  }
}

private extension UIViewController {
  var redactKitTopMostViewController: UIViewController {
    if let presentedViewController {
      return presentedViewController.redactKitTopMostViewController
    }
    if let navigationController = self as? UINavigationController,
       let visibleViewController = navigationController.visibleViewController {
      return visibleViewController.redactKitTopMostViewController
    }
    if let tabBarController = self as? UITabBarController,
       let selectedViewController = tabBarController.selectedViewController {
      return selectedViewController.redactKitTopMostViewController
    }
    return self
  }
}
