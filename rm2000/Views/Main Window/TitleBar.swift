import Foundation
import SwiftUI
import AppKit

class SkeuromorphicWindow: NSWindow {
	override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
		super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
		
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
		
		//omg skeuromorphism.
		
		let isDarkMode = self.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
		
		let imageName = isDarkMode ? "MicGrilleDark" : "MicGrilleTemp"
		let imageView = NSImageView(frame: NSRect(x: -70, y: -14, width: 140, height: 28))
		
		if let image = NSImage(named: imageName) {
			image.size = NSSize(width: 130, height: 19)
			imageView.image = image
			imageView.setAccessibilityElement(false)
			imageView.setAccessibilityHidden(true)
		}
		
		let customView = NSView(frame: NSRect(x: 0, y: 30, width: 30, height: 20))
		customView.addSubview(imageView)
		customView.setAccessibilityElement(false)
		customView.setAccessibilityHidden(true)
		
		if let titlebarController = self.standardWindowButton(.closeButton)?.superview?.superview {
			titlebarController.addSubview(customView)
			
			customView.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				customView.centerYAnchor.constraint(equalTo: titlebarController.centerYAnchor),
				customView.centerXAnchor.constraint(equalTo: titlebarController.centerXAnchor)
			])
		}
	}
}
