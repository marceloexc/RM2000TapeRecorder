import AppKit
import KeyboardShortcuts
import OSLog
import SwiftUI
import SettingsAccess

class WindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
  }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, ObservableObject {
  
  var mainWindowController: WindowController?
  let recordingState = TapeRecorderState.shared
  let storeKitManager = StoreManager.shared
  let mainWindowIdentifier = NSUserInterfaceItemIdentifier("mainWindow")

  private var onboardingWindowController: NSWindowController?
  private var editingWindowController: NSWindowController?
  private var hudHostingView: NSHostingView<AnyView>?
  @MainActor private var confirmOnQuit: Bool {
    AppState.shared.confirmOnQuit
  }
  @Published private var willTerminate = false

  private var hudWindow: NSWindow?
  private var mainWindow: NSWindow?
  private var editingWindow: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    AppState.shared.appDelegate = self
    registerCustomFonts()
    if AppState.shared.hasCompletedOnboarding {
      showMainWindow()
    } else {
      showOnboardingWindow()
    }
  }

  func showMainWindow() {
    Logger.appDelegate.info("'Show Main Window' called")
    // if window is already created, just show it, dont make another window
    if let window = mainWindow, window.isVisible {
      bringToFront()
      return
    }

    Logger.appDelegate.info(
      "Main Window does not exist - creating NSWindow.....")
    // else, create the window
    let window = SkeuromorphicWindow(
      contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    let contentView = ContentView()
      .environmentObject(self.recordingState)
      .environmentObject(self.storeKitManager)
      .openSettingsAccess()
    
    self.mainWindow = window

    self.mainWindow?.contentView = NSHostingView(rootView: contentView)
    self.mainWindow?.delegate = self  // track window closure

    self.mainWindow?.isReleasedWhenClosed = false
    self.mainWindow?.identifier = mainWindowIdentifier
    self.mainWindowController = WindowController(window: window)
    self.mainWindowController?.window?.center()
    self.mainWindowController?.showWindow(nil)
  }
  
  func bringToFront() {
    self.mainWindow?.deminiaturize(nil)
    self.mainWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  
  func showEditingWindow(sample: Sample) {
    let window = EditingHUDWindow(contentRect: NSRect(x: 100, y: 100, width: 500 , height: 400))
    
    let newRecording = sample
    let contentView = EditSampleView(recording: newRecording) { FileRepresentable, SampleMetadata, SampleEditConfiguration in
    }
    let hostingView = NSHostingView(rootView: AnyView(contentView))
    
    let effectView = NSVisualEffectView()
    effectView.material = .toolTip
    effectView.blendingMode = .withinWindow
    effectView.state = .active
    
    effectView.addSubview(hostingView)
    
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
      hostingView.topAnchor.constraint(equalTo: effectView.topAnchor),
      hostingView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor)
    ])
    
    window.contentView = effectView
    editingWindowController = NSWindowController(window: window)
    editingWindowController?.showWindow(nil)
  }

  func showHUDWindow() {
    Logger.appDelegate.info("Showing HUD Window")
    closeHUDWindow()

    // wait a bit for window destruction
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      let window = GlobalRecordingPreviewWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
        backing: .buffered,
        defer: false
      )

      window.isReleasedWhenClosed = false  // Keep window alive

      let contentView = GlobalRecordingPreviewView()
        .environmentObject(self.recordingState)

      let hostingView = NSHostingView(rootView: AnyView(contentView))
      window.contentView = hostingView

      if let screenSize = NSScreen.main?.visibleFrame.size {
        window.setFrameOrigin(
          NSPoint(x: screenSize.width - 415, y: screenSize.height / 15))
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
    bringToFront()
  }

  @MainActor private func showOnboardingWindow() {
    let hostingController = NSHostingController(
      rootView: OnboardingView(pages: OnboardingStep.fullOnboarding)
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
    if confirmOnQuit {
      self.willTerminate = true
      self.promptQuitConfirmation()
      return .terminateLater
    }
    return .terminateNow
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
    alert.informativeText = "You will not be able to use your Global Recording Hotkey to record."
    alert.alertStyle = .critical
    alert.addButton(withTitle: "Yes")
    alert.addButton(withTitle: "No")
    
    DispatchQueue.main.async {
      let response = alert.runModal()
      if response == .alertFirstButtonReturn {
        self.close()
      } else {
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
    let fonts = Bundle.main.urls(
      forResourcesWithExtension: "otf", subdirectory: nil)
    fonts?.forEach { url in
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    let fonts_ttf = Bundle.main.urls(
      forResourcesWithExtension: "ttf", subdirectory: nil)
    fonts_ttf?.forEach { url in
      CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
  }
}

extension AppDelegate {
  @objc func windowWillClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      window === mainWindowController?.window
    {
      mainWindowController = nil
    }
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
        for window in sender.windows {
          if window.identifier == mainWindowIdentifier {
            window.makeKeyAndOrderFront(self)
          }
        }
    }

    return true
  }
}
