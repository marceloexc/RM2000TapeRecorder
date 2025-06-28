import Foundation
import OSLog

@MainActor final class LogStore: ObservableObject {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: LogStore.self)
  )
  
  @Published private(set) var entries: [String] = []
  
  func export() -> [String] {
    do {
      let store = try OSLogStore(scope: .currentProcessIdentifier)
      let position = store.position(timeIntervalSinceLatestBoot: 1)
      entries = try store
        .getEntries(at: position)
        .compactMap { $0 as? OSLogEntryLog }
        .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
        .map { "[\($0.date.formatted())] [\($0.category)] \($0.composedMessage)" }
      return entries
    } catch {
      Self.logger.warning("\(error.localizedDescription, privacy: .public)")
      return []
    }
  }
}

extension Logger {
	private static var subsystem = Bundle.main.bundleIdentifier!
	
	// logger object for taperecorder
	static let streamProcess = Logger(subsystem: subsystem, category: "taperecorder")
	
	static let sharedStreamState = Logger(subsystem: subsystem, category: "sharedstreamstate")
	
	static let viewModels = Logger(subsystem: subsystem, category: "viewmodels")
	
	static let appState = Logger(subsystem: subsystem, category: "appState")
  
  static let sampleStorage = Logger(subsystem: subsystem, category: "SampleStorage")
  
  static let encoder = Logger(subsystem: subsystem, category: "encoder")
  
  static let appDelegate = Logger(subsystem: subsystem, category: "AppDelegate")
}
