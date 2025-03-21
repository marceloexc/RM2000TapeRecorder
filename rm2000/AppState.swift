import Foundation
import SwiftUI
import OSLog

@MainActor final class AppState: ObservableObject {
	static let shared = AppState()
	
	@AppStorage("completedOnboarding") var hasCompletedOnboarding: Bool = false {
		didSet {
			if !hasCompletedOnboarding {
				openOnboardingWindow()
			}
		}
	}
	
	@AppStorage("sample_directory") var sampleDirectoryPath: String = ""
	@AppStorage("sample_directory_bookmark") private var sampleDirectoryBookmark: Data?
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
	
	private var openWindowAction: OpenWindowAction?
	
	init() {
		if let bookmarkData = sampleDirectoryBookmark {
			restoreBookmarkAccess(with: bookmarkData)
		}
		Logger.appState.info("\(String(describing: sampleDirectory)) as the user directory")
	}
	
	func setOpenWindowAction(_ action: OpenWindowAction) {
		self.openWindowAction = action
		if !hasCompletedOnboarding {
			openOnboardingWindow()
		}
	}
	
	func openOnboardingWindow() {
		openWindowAction?(id: "onboarding")
	}
	
	// security scoped bookmarks for app sandbox
	private func saveBookmarkData(for userDir: URL) {
		do {
			let bookmarkData = try userDir.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
			sampleDirectoryBookmark = bookmarkData
		} catch {
			Logger().error("Failed to save bookmark data for \(userDir)", error)
		}
	}
	
	private func restoreBookmarkAccess(with bookmarks: Data) {
		do {
			var isStale = false
			let resolvedURL = try URL(resolvingBookmarkData: bookmarks, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
			if isStale {
				Logger.appState.info("Recreating bookmark (is stale)")
			}
			
			guard resolvedURL.startAccessingSecurityScopedResource() else {
				Logger.appState.error("AppState - failed to start access security scoped for directory \(resolvedURL)")
				return
			}
			Logger.appState.info("Set bookmarked access as \(String(describing: sampleDirectory)) : \(resolvedURL)")
			sampleDirectory = resolvedURL
		} catch {
			Logger.appState.error("Failed to restore bookmark access: \(error.localizedDescription)")
		}
	}
}
