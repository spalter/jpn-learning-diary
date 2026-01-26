import Cocoa
import FlutterMacOS

/// Main application delegate for macOS.
///
/// Handles Flutter application lifecycle events.
@main
class AppDelegate: FlutterAppDelegate {
  /// Returns true to close the app when the last window is closed.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  /// Supports secure state restoration for macOS apps.
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
