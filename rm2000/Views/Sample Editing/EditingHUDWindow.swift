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
//    self.isReleasedWhenClosed = true
  }
  
  override func close() {
    guard isVisible else {
      super.close()
      return
    }
    //fade-out
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.20
      self.animator().alphaValue = 0
    }, completionHandler: {
      super.close()
      self.alphaValue = 1.0
    })
  }
  
  deinit {
    print("denint")
  }
}
