import AppKit

class EditingHUDWindow: NSPanel {
  init(contentRect: NSRect, backing: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false) {
    super.init( contentRect: contentRect, styleMask: [.titled, .closable, .miniaturizable, .resizable, .utilityWindow, .hudWindow], backing: backing, defer: flag)
    self.title = "Editing Sample"
    self.titleVisibility = .visible
    self.titlebarAppearsTransparent = false
    self.level = .floating
    self.isOpaque = false
    self.backgroundColor = .clear
    self.animationBehavior = .documentWindow
  }
}
