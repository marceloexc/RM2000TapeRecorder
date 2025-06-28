import Foundation
import KeyboardShortcuts
import OSLog
import StoreKit
import SwiftUI

@MainActor final class AppState: ObservableObject {
  static let shared = AppState()
  @AppStorage("completedOnboarding") var hasCompletedOnboarding: Bool = false {
    didSet {
      if !hasCompletedOnboarding {
        openWindowAction?(id: "onboarding")
      }
    }
  }

  @AppStorage("sample_directory") var sampleDirectoryPath: String = ""
  @AppStorage("sample_directory_bookmark") private var sampleDirectoryBookmark:
    Data?
  @Published var sampleDirectory: URL? {
    didSet {

      oldValue?.stopAccessingSecurityScopedResource()

      if let directory = sampleDirectory {
        // setup security scoped bookmarks

        guard directory.startAccessingSecurityScopedResource() else {
          return
        }
        sampleDirectoryPath = sampleDirectory?.path ?? ""
        saveBookmarkData(for: directory)
      } else {
        sampleDirectoryPath = ""
        sampleDirectoryBookmark = nil
      }
    }
  }

  @Published var storekitManager = StoreManager.shared

  // opening swiftui windows from an AppKit perspective
  private var openWindowAction: OpenWindowAction?

  var hasPurchasedApp: Bool {
    storekitManager.hasPurchasedApp
  }
  
  weak var appDelegate: AppKitWindowManagerDelegate?

  init() {
    KeyboardShortcuts.onKeyUp(for: .recordGlobalShortcut) { [self] in
      Task {
        await startQuickSampleRecordAndShowHUD()
      }
    }

    if let bookmarkData = sampleDirectoryBookmark {
      restoreBookmarkAccess(with: bookmarkData)
    }

    if sampleDirectory == nil && hasCompletedOnboarding {
      // Fallback to ~/Music/Samples if sampleDirectory doesnt exist
      // we only do this if they have completed onboarding,
      // because I wouldnt want to pollute a user's files if they dont complete onboarding and decide
      // not to use the app
      let fallbackPath = FileManager.default.urls(
        for: .musicDirectory, in: .userDomainMask
      ).first!.appendingPathComponent("RM2000 Tape Recorder")
      try? FileManager.default.createDirectory(
        at: fallbackPath, withIntermediateDirectories: true)

      if fallbackPath.startAccessingSecurityScopedResource() {
        sampleDirectory = fallbackPath
        saveBookmarkData(for: fallbackPath)
      } else {
        Logger.appState.error(
          "Failed to access fallback sample directory at \(fallbackPath)")
      }
    }

    Logger.appState.info(
      "\(String(describing: self.sampleDirectory)) as the user directory")
  }

  func setOpenWindowAction(_ action: OpenWindowAction) {
    self.openWindowAction = action
    if !hasCompletedOnboarding {
      openWindowAction?(id: "onboarding")
    }
  }

  func closeHUDWindow() {
    appDelegate?.closeHUDWindow()
  }

  private func startQuickSampleRecordAndShowHUD() async {
    if TapeRecorderState.shared.status == .idle {
      TapeRecorderState.shared.startRecording()
      appDelegate?.showHUDWindow()
    } else {
      TapeRecorderState.shared.stopRecording()
      appDelegate?.closeHUDWindow()

      // pop up window so that user can start editing
      NSApp.requestUserAttention(.criticalRequest)
      appDelegate?.showMainWindow()
    }
  }

  // security scoped bookmarks for app sandbox
  private func saveBookmarkData(for userDir: URL) {
    do {
      let bookmarkData = try userDir.bookmarkData(
        options: .withSecurityScope, includingResourceValuesForKeys: nil,
        relativeTo: nil)
      sampleDirectoryBookmark = bookmarkData
    } catch {
      Logger.appState.error(
        "Failed to save bookmark data for \(userDir): \(error)")
    }
  }

  private func restoreBookmarkAccess(with bookmarks: Data) {
    do {
      var isStale = false
      let resolvedURL = try URL(
        resolvingBookmarkData: bookmarks, options: .withSecurityScope,
        relativeTo: nil, bookmarkDataIsStale: &isStale)
      if isStale {
        Logger.appState.info("Recreating bookmark (is stale)")
      }

      guard resolvedURL.startAccessingSecurityScopedResource() else {
        Logger.appState.error(
          "AppState - failed to start access security scoped for directory \(resolvedURL)"
        )
        return
      }
      Logger.appState.info(
        "Set bookmarked access as \(String(describing: self.sampleDirectory)) : \(resolvedURL)"
      )
      sampleDirectory = resolvedURL
    } catch {
      Logger.appState.error(
        "Failed to restore bookmark access: \(error.localizedDescription)")
    }
  }
}
