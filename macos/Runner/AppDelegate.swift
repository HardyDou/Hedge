import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate, NSMenuItemValidation, NSUserInterfaceValidations {
    private var methodChannel: FlutterMethodChannel?
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)
        
        // Setup MethodChannel
        if let controller = NSApplication.shared.windows.first?.contentViewController as? FlutterViewController {
            methodChannel = FlutterMethodChannel(
                name: "app.menu",
                binaryMessenger: controller.engine.binaryMessenger
            )
        }
        
        // Try to patch menu
        DispatchQueue.main.async { [weak self] in
            self?.setupPreferencesMenuItem()
        }
    }
    
    private func setupPreferencesMenuItem() {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }
        
        // Try to find existing "Preferences..." (keyEquivalent = ",")
        if let prefsItem = appMenu.items.first(where: { $0.keyEquivalent == "," }) {
            prefsItem.target = self
            prefsItem.action = #selector(showPreferencesWindow(_:))
            prefsItem.isEnabled = true
        } else {
            let prefsItem = NSMenuItem(title: "设置...", action: #selector(showPreferencesWindow(_:)), keyEquivalent: ",")
            prefsItem.target = self
            prefsItem.isEnabled = true
            let index = min(2, appMenu.items.count)
            appMenu.insertItem(prefsItem, at: index)
        }
    }
    
    // MARK: - Menu Actions
    
    @IBAction func showPreferencesWindow(_ sender: Any?) {
        methodChannel?.invokeMethod("openSettings", arguments: nil)
    }
    
    // MARK: - Validation
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        return true
    }
}
