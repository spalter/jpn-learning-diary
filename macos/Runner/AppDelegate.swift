import Cocoa
import FlutterMacOS

/// Main application delegate for macOS.
///
/// Handles:
/// - Flutter method channel setup for security-scoped bookmark management
/// - Application lifecycle events
/// - Security-scoped resource access management
///
/// ## Security-Scoped Bookmarks
/// This delegate implements native macOS bookmark APIs to provide persistent
/// file access across app restarts. This is required for accessing files outside
/// the app's sandbox, such as database files in Dropbox or other cloud storage.
///
/// ## Method Channel API
/// Channel name: `com.jpn_learning_diary/file_access`
///
/// Available methods:
/// - `createBookmark`: Creates a security-scoped bookmark for a file path
/// - `resolveBookmark`: Resolves a saved bookmark and grants access
/// - `stopAccessing`: Stops accessing a security-scoped resource
///
/// See FileAccessService.dart for the Dart implementation.
@main
class AppDelegate: FlutterAppDelegate {
  /// Currently accessed security-scoped URL.
  /// Stored to properly release access when done.
  private var accessedURL: URL?
  
  /// Sets up the Flutter method channel when the app finishes launching.
  ///
  /// This method:
  /// 1. Retrieves the FlutterViewController from the main window
  /// 2. Handles cases where the controller is wrapped (e.g., by macos_window_utils)
  /// 3. Creates a MethodChannel for communication with Dart code
  /// 4. Registers method call handler for security-scoped bookmark operations
  ///
  /// The channel enables Dart code to create and resolve security-scoped bookmarks
  /// for persistent file access across app restarts.
  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let window = mainFlutterWindow,
          let viewController = window.contentViewController else {
      return
    }
    
    // Get the FlutterViewController - handle both direct and wrapped cases
    // Some plugins (like macos_window_utils) wrap the FlutterViewController
    let flutterViewController: FlutterViewController
    if let controller = viewController as? FlutterViewController {
      // Direct case: viewController is FlutterViewController
      flutterViewController = controller
    } else {
      // Wrapped case: Find FlutterViewController in child controllers
      // This handles plugins like macos_window_utils that wrap the controller
      guard let childControllers = viewController.children.first(where: { $0 is FlutterViewController }),
            let controller = childControllers as? FlutterViewController else {
        return
      }
      flutterViewController = controller
    }
    
    // Create method channel for security-scoped bookmark operations
    let channel = FlutterMethodChannel(
      name: "com.jpn_learning_diary/file_access",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    
    // Register handler for method calls from Dart
    channel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call, result: result)
    }
  }
  
  /// Handles method calls from Dart via the Flutter method channel.
  ///
  /// Supported methods:
  /// - `createBookmark`: Creates a security-scoped bookmark for a file path
  /// - `resolveBookmark`: Resolves a saved bookmark and starts accessing the resource
  /// - `stopAccessing`: Stops accessing the current security-scoped resource
  ///
  /// - Parameters:
  ///   - call: The method call with method name and arguments
  ///   - result: Callback to return result or error to Dart
  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createBookmark":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      createBookmark(path: path, result: result)
      
    case "resolveBookmark":
      guard let args = call.arguments as? [String: Any],
            let bookmarkData = args["bookmarkData"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      resolveBookmark(bookmarkData: bookmarkData, result: result)
      
    case "stopAccessing":
      stopAccessing()
      result(nil)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  /// Creates a security-scoped bookmark for the specified file path.
  ///
  /// A security-scoped bookmark stores permission to access a file outside the app's
  /// sandbox. The bookmark can be saved and resolved later to regain access.
  ///
  /// - Parameters:
  ///   - path: Absolute file path to create bookmark for
  ///   - result: Returns base64-encoded bookmark data on success, or FlutterError on failure
  ///
  /// - Returns: Base64-encoded bookmark data string via result callback
  ///
  /// - Note: The file must be accessible when creating the bookmark (e.g., via file picker)
  private func createBookmark(path: String, result: @escaping FlutterResult) {
    let url = URL(fileURLWithPath: path)
    
    do {
      // Create security-scoped bookmark with read-write access
      let bookmarkData = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      // Encode as base64 for storage in Dart/Flutter (SharedPreferences)
      let base64String = bookmarkData.base64EncodedString()
      result(base64String)
    } catch {
      result(FlutterError(
        code: "BOOKMARK_ERROR",
        message: "Failed to create bookmark: \(error.localizedDescription)",
        details: nil
      ))
    }
  }
  
  /// Resolves a security-scoped bookmark and starts accessing the resource.
  ///
  /// Takes a previously created bookmark and resolves it to regain access to the file.
  /// The file becomes accessible until stopAccessingSecurityScopedResource() is called
  /// or the app terminates.
  ///
  /// - Parameters:
  ///   - bookmarkData: Base64-encoded bookmark data string
  ///   - result: Returns resolved file path on success, or FlutterError on failure
  ///
  /// - Returns: Absolute file path string via result callback
  ///
  /// - Note: Automatically calls startAccessingSecurityScopedResource() on the URL.
  ///         The URL is stored in `accessedURL` for cleanup later.
  private func resolveBookmark(bookmarkData: String, result: @escaping FlutterResult) {
    // Decode base64 bookmark data
    guard let data = Data(base64Encoded: bookmarkData) else {
      result(FlutterError(code: "INVALID_DATA", message: "Invalid bookmark data", details: nil))
      return
    }
    
    do {
      var isStale = false
      // Resolve the bookmark to get the URL
      let url = try URL(
        resolvingBookmarkData: data,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      
      // Start accessing the security-scoped resource
      // This is REQUIRED - without it, file access will fail with permission errors
      if url.startAccessingSecurityScopedResource() {
        // Store URL to properly release access later
        accessedURL = url
        result(url.path)
      } else {
        result(FlutterError(
          code: "ACCESS_DENIED",
          message: "Failed to access security-scoped resource",
          details: nil
        ))
      }
    } catch {
      result(FlutterError(
        code: "RESOLVE_ERROR",
        message: "Failed to resolve bookmark: \(error.localizedDescription)",
        details: nil
      ))
    }
  }
  
  /// Stops accessing the currently accessed security-scoped resource.
  ///
  /// Releases the access permission granted by resolveBookmark.
  /// Should be called when done using the file, though it's also called
  /// automatically on app termination.
  private func stopAccessing() {
    accessedURL?.stopAccessingSecurityScopedResource()
    accessedURL = nil
  }
  
  /// Returns true to close the app when the last window is closed.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  /// Supports secure state restoration for macOS apps.
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  /// Cleans up security-scoped resource access when app is terminating.
  ///
  /// This ensures proper cleanup of any active security-scoped resource access,
  /// preventing potential resource leaks.
  override func applicationWillTerminate(_ notification: Notification) {
    stopAccessing()
  }
}
