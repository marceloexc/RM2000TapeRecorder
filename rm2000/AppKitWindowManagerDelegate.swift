import AppKit
import SwiftUI

class WindowController: NSWindowController {
	override func windowDidLoad() {
		super.windowDidLoad()
	}
}

class AppKitWindowManagerDelegate: NSObject, NSApplicationDelegate {
	
	@Published var willTerminate = false
	var mainWindowController: WindowController?
	let recordingState = TapeRecorderState.shared
	private var onboardingWindowController: NSWindowController?
	private var hudHostingView: NSHostingView<AnyView>?
	
	private var hudWindow: NSWindow?
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		registerCustomFonts()
		if AppState.shared.hasCompletedOnboarding {
			showMainWindow()
		} else {
			showOnboardingWindow()
		}
	}
	
	func showMainWindow() {
		
		// if window is already created, just show it, dont make another window
		if let window = mainWindowController?.window, window.isVisible {
			window.makeKeyAndOrderFront(nil)
			return
		}
		
		let window = SkeuromorphicWindow(
			contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
			styleMask: [.titled, .closable, .miniaturizable],
			backing: .buffered,
			defer: false
		)
		
		let contentView = ContentView()
			.environmentObject(self.recordingState)
			.openSettingsAccess()
		window.center()
		window.contentView = NSHostingView(rootView: contentView)
		mainWindowController = WindowController(window: window)
		mainWindowController?.showWindow(nil)
	}
	
	func showHUDWindow() {
		closeHUDWindow()
		
		// wait a bit for window destruction
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			
			let window = FloatingWindow(
				contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
				backing: .buffered,
				defer: false
			)
			
			window.isReleasedWhenClosed = false // Keep window alive
			
			let contentView = FloatingGradientView()
				.environmentObject(self.recordingState)
			
			let hostingView = NSHostingView(rootView: AnyView(contentView))
			self.hudHostingView = hostingView
			
			if let windowContentView = window.contentView {
				hostingView.autoresizingMask = [.width, .height]
				hostingView.frame = windowContentView.bounds
				windowContentView.addSubview(hostingView)
			}
			
			if let screenSize = NSScreen.main?.visibleFrame.size {
				window.setFrameOrigin(NSPoint(x: screenSize.width - 415, y: screenSize.height / 15))
			}
			
			window.makeKeyAndOrderFront(nil)
			self.hudWindow = window
		}
	}
	
	func closeHUDWindow() {
		guard let windowToClose = hudWindow else { return }
		hudHostingView?.removeFromSuperview()
		windowToClose.orderOut(nil)
		// clear references
		hudHostingView = nil
		hudWindow = nil
		
		// idk how to clean this up properly :V
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			NSApp.windows.forEach { window in
				if window === windowToClose {
					window.close()
				}
			}
		}
	}
	
	@MainActor private func showOnboardingWindow() {
		let hostingController = NSHostingController(
			rootView: OnboardingView(viewModel: OnboardingViewModel())
				.environmentObject(AppState.shared)
		)
		
		let window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)
		window.contentViewController = hostingController
		onboardingWindowController = NSWindowController(window: window)
		onboardingWindowController?.showWindow(nil)
		window.center()
	}
	
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		self.willTerminate = true
		self.promptQuitConfirmation()
		return .terminateLater
	}
	
	/// dont close (user canceled)
	func `continue`() {
		NSApplication.shared.reply(toApplicationShouldTerminate: false)
	}
	/// close
	func close() {
		NSApplication.shared.reply(toApplicationShouldTerminate: true)
	}
	
	func promptQuitConfirmation() {
		let alert = NSAlert()
		alert.messageText = "Really Quit?"
		alert.informativeText = "You will not be able to start Quick Recordings (⌘ + ⌥ + G) when the application is not running."
		alert.alertStyle = .critical
		alert.addButton(withTitle: "Yes, Quit")
		alert.addButton(withTitle: "No, Cancel")
		
		DispatchQueue.main.async {
			let response = alert.runModal()
			if response == .alertFirstButtonReturn {
				// "Quit" pressed
				self.close()
			} else {
				// "Cancel" pressed
				self.continue()
			}
		}
	}

	/*
	 A function like this should never exist.
	 However, even after I followed all of the tutorials,
	 Xcode simply wouldn't bundle my otf fonts.
	 */
	private func registerCustomFonts() {
		let fonts = Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil)
		fonts?.forEach { url in
			CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
		}
	}
}
