import AppKit

class GlobalRecordingPreviewWindow: NSPanel {
  init(contentRect: NSRect, backing: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false) {
    super.init( contentRect: contentRect, styleMask: [.titled, .utilityWindow, .hudWindow], backing: backing, defer: flag)

    /// we're using an NSPanel, but really i just want the .hudWindow style mask.
    /// so, we're gonna make it behave like an NSWindow
    self.level = .floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    self.hasShadow = true
    self.title = "Recording..."
    self.titlebarAppearsTransparent = false
    self.isMovableByWindowBackground = true
    self.hidesOnDeactivate = false
  }

  override var canBecomeKey: Bool {
    return true
  }
  
  override var canBecomeMain: Bool {
    return true
  }
}
