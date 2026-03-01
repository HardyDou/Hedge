import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Setup menu after Flutter is ready
    DispatchQueue.main.async {
      self.setupApplicationMenu()
    }
  }

  private func setupApplicationMenu() {
    guard let appDelegate = NSApp.delegate as? AppDelegate else { return }

    // Force enable the Preferences menu item
    if let appMenu = NSApp.mainMenu?.items.first?.submenu {
      for item in appMenu.items {
        if item.keyEquivalent == "," {
          item.target = appDelegate
          item.action = #selector(AppDelegate.showPreferencesWindow(_:))
          item.isEnabled = true
        }
      }
    }
  }
}
