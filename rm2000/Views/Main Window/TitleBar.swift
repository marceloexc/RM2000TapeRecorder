import AppKit
import Foundation
import SwiftUI

class SkeuromorphicWindow: NSWindow {
  override init(
    contentRect: NSRect, styleMask style: NSWindow.StyleMask,
    backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool
  ) {
    super.init(
      contentRect: contentRect, styleMask: style, backing: backingStoreType,
      defer: flag)

    // basic window customizations
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .visible

    self.backgroundColor = .windowBackgroundColor
    self.isMovableByWindowBackground = true

    let toolbar = NSToolbar(identifier: "MainToolbar")
    self.toolbar = toolbar
    self.toolbarStyle = .unified
    self.toolbar?.showsBaselineSeparator = false

    if let zoomButton = standardWindowButton(.zoomButton) {
      zoomButton.isHidden = true
    }

    drawMicrophoneGrille()
  }

  private func drawMicrophoneGrille() {
    let grilleView = MicrophoneGrilleView(
      frame: NSRect(x: 0, y: 30, width: 30, height: 20))

    if let titlebarContainer = self.standardWindowButton(.closeButton)?
      .superview?.superview
    {
      titlebarContainer.addSubview(grilleView)

      grilleView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        grilleView.centerXAnchor.constraint(
          equalTo: titlebarContainer.centerXAnchor),
        grilleView.centerYAnchor.constraint(
          equalTo: titlebarContainer.centerYAnchor),
      ])
    }
  }
}

class MicrophoneGrilleView: NSView {
  private let imageView = NSImageView()

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }

  private func setupView() {
    self.setAccessibilityElement(false)
    self.setAccessibilityHidden(true)

    imageView.frame = NSRect(x: -70, y: -14, width: 140, height: 28)
    imageView.setAccessibilityElement(false)
    imageView.setAccessibilityHidden(true)
    imageView.alphaValue = 0.85
    self.addSubview(imageView)

    updateAppearance()
  }

  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    updateAppearance()
  }

  private func updateAppearance() {
    let isDarkMode =
      effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

    if let image = NSImage(named: "MicGrilleBitmap") {
      image.size = NSSize(width: 130, height: 19)
      imageView.image = image
    }

    if isDarkMode {
      let shadow = NSShadow()
      shadow.shadowOffset = NSSize(width: 1, height: -2)
      shadow.shadowBlurRadius = 3.0
      shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
      imageView.shadow = shadow
    } else {
      imageView.shadow = nil
    }
  }
}
