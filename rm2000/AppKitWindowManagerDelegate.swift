import AppKit
import KeyboardShortcuts
import OSLog
import SwiftUI

class WindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
  }
}

class AppKitWindowManagerDelegate: NSObject, NSApplicationDelegate,
  NSWindowDelegate
{

  @Published var willTerminate = false
  var mainWindowController: WindowController?
  let recordingState = TapeRecorderState.shared
  let storeKitManager = StoreManager.shared
  private var onboardingWindowController: NSWindowController?
  private var hudHostingView: NSHostingView<AnyView>?

  private var hudWindow: NSWindow?
  private var mainWindow: NSWindow?
  private var whatsNewDrawer: NSDrawer?

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
    if let windowController = mainWindowController,
      let window = windowController.window
    {
      Logger.appDelegate.info("Main Window already exists!")
      // If window is visible, just bring it to front
      if !window.isVisible || window.isMiniaturized {
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
      } else {
        // If window exists but isn't visible, it might be minimized - show it
        window.makeKeyAndOrderFront(nil)
      }
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

    window.center()
    window.contentView = NSHostingView(rootView: contentView)
    window.delegate = self  // track window closure

    window.isReleasedWhenClosed = false
    
    mainWindow = window

//    setupDrawer()
    
    mainWindowController = WindowController(window: window)
    mainWindowController?.showWindow(nil)
  }

  func showHUDWindow() {
    Logger.appDelegate.info("Showing HUD Window")
    closeHUDWindow()

    // wait a bit for window destruction
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      let window = FloatingWindow(
        contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
        backing: .buffered,
        defer: false
      )

      window.isReleasedWhenClosed = false  // Keep window alive

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
  }
  
  private func setupDrawer() {
    let contentSize = NSSize(width: 300, height: 270)
    whatsNewDrawer = NSDrawer(contentSize: contentSize, preferredEdge: .maxX)
    whatsNewDrawer?.parentWindow = mainWindow
    whatsNewDrawer?.leadingOffset = 50
    
    let hostedView = NSHostingView(rootView: WhatsNewView())
    hostedView.sizingOptions = .minSize
    whatsNewDrawer?.contentView = hostedView
    whatsNewDrawer?.open(on: .maxX)
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

extension AppKitWindowManagerDelegate {
  @objc func windowWillClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      window === mainWindowController?.window
    {
      mainWindowController = nil
    }
  }
}
