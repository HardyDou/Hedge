import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    private var canShowSettings = true

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)

        // Setup MethodChannel with delay to ensure Flutter engine is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.setupMethodChannel()
            self?.setupPreferencesMenuItem()
        }
    }

    private func setupMethodChannel() {
        if let controller = NSApplication.shared.windows.first?.contentViewController as? FlutterViewController {
            methodChannel = FlutterMethodChannel(
                name: "app.menu",
                binaryMessenger: controller.engine.binaryMessenger
            )

            // Listen for lock/unlock events from Flutter
            methodChannel?.setMethodCallHandler { [weak self] (call, result) in
                if call.method == "setMenuEnabled" {
                    if let enabled = call.arguments as? Bool {
                        self?.canShowSettings = enabled
                        // Force menu to revalidate
                        DispatchQueue.main.async {
                            NSApp.mainMenu?.update()
                        }
                    }
                    result(nil)
                }
            }
        }
    }

    private func setupPreferencesMenuItem() {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }

        // Find existing "Preferences..." menu item (keyEquivalent = ",")
        if let prefsItem = appMenu.items.first(where: { $0.keyEquivalent == "," }) {
            prefsItem.target = self
            prefsItem.action = #selector(showPreferencesWindow(_:))
        } else {
            // If not found, create one
            let prefsItem = NSMenuItem(title: "设置...", action: #selector(showPreferencesWindow(_:)), keyEquivalent: ",")
            prefsItem.target = self
            let index = min(2, appMenu.items.count)
            appMenu.insertItem(prefsItem, at: index)
        }
    }

    // MARK: - Menu Actions

    @objc func showPreferencesWindow(_ sender: Any?) {
        if methodChannel == nil {
            setupMethodChannel()
        }
        methodChannel?.invokeMethod("openSettings", arguments: nil)
    }

}

// MARK: - Menu Validation
extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(showPreferencesWindow(_:)) {
            return canShowSettings
        }
        return true
    }
}
