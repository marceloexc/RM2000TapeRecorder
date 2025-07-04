import Foundation
import SwiftUICore
import Combine
import AVKit
import KeyboardShortcuts

struct WorkingDirectory {
	static let appIdentifier = "com.marceloexc.rm2000"

	static func applicationSupportPath() -> URL {
		let documentURL = FileManager.default.urls(
			for: .applicationSupportDirectory, in: .userDomainMask
		).first!

		let path = documentURL.appendingPathComponent(appIdentifier)

		return path
	}
}

extension KeyboardShortcuts.Name {
	static let recordGlobalShortcut = Self("recordGlobalShortcut", default: .init(.g, modifiers: [.command, .option]))
}

extension URL {
	var isDirectory: Bool {
		(try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
	}
	
	// https://stackoverflow.com/a/56044623
	var fileSize: Int? {
		let value = try? resourceValues(forKeys: [.fileSizeKey])
		return value?.fileSize
	}
  
  // https://stackoverflow.com/a/34746109/30724926
  var isHidden: Bool {
    get {
      return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
    }
    set {
      var resourceValues = URLResourceValues()
      resourceValues.isHidden = newValue
      do {
        try setResourceValues(resourceValues)
      } catch {
        print("isHidden error:", error)
      }
    }
  }
}

func timeString(_ time: TimeInterval) -> String {
	let minutes = Int(time) / 60
	let seconds = Int(time) % 60
	return String(format: "%02d:%02d", minutes, seconds)
}

// https://stackoverflow.com/a/56894458
extension Color {
	init(hex: UInt, alpha: Double = 1) {
		self.init(
			.sRGB,
			red: Double((hex >> 16) & 0xff) / 255,
			green: Double((hex >> 08) & 0xff) / 255,
			blue: Double((hex >> 00) & 0xff) / 255,
			opacity: alpha
		)
	}
}

protocol FileRepresentable {
	var fileURL: URL { get }
	var id: UUID { get }
}

extension TemporaryActiveRecording: FileRepresentable { }
extension Sample: FileRepresentable { }

// i borrowed a lot of this from https://github.com/sindresorhus/Gifski/blob/main/Gifski/Utilities.swift
extension NSView {
	/**
	Get a subview matching a condition.
	*/
	func firstSubview(deep: Bool = false, where matches: (NSView) -> Bool) -> NSView? {
		for subview in subviews {
			if matches(subview) {
				return subview
			}

			if deep, let match = subview.firstSubview(deep: deep, where: matches) {
				return match
			}
		}

		return nil
	}
}

extension NSObjectProtocol where Self: NSObject {
	func updates<Value>(
		for keyPath: KeyPath<Self, Value>,
		options: NSKeyValueObservingOptions = [.initial, .new]
	) -> AsyncStream<Value> {
		publisher(for: keyPath, options: options).toAsyncStream
	}
}

extension Publisher where Failure == Never {
	var toAsyncStream: AsyncStream<Output> {
		AsyncStream(Output.self) { continuation in
			let cancellable = sink { completion in
				switch completion {
				case .finished:
					continuation.finish()
				}
			} receiveValue: { output in
				continuation.yield(output)
			}

			continuation.onTermination = { [cancellable] _ in
				cancellable.cancel()
			}
		}
	}
}

extension NSObject {
	// Note: It's intentionally a getter to get the dynamic self.
	/**
	Returns the class name without module name.
	*/
	static var simpleClassName: String { String(describing: self) }

	/**
	Returns the class name of the instance without module name.
	*/
	var simpleClassName: String { Self.simpleClassName }
}

extension NSLayoutConstraint {
	/**
	Returns copy of the constraint with changed properties provided as arguments.
	*/
	func changing(
		firstItem: Any? = nil,
		firstAttribute: Attribute? = nil,
		relation: Relation? = nil,
		secondItem: NSView? = nil,
		secondAttribute: Attribute? = nil,
		multiplier: Double? = nil,
		constant: Double? = nil
	) -> Self {
		.init(
			item: firstItem ?? self.firstItem as Any,
			attribute: firstAttribute ?? self.firstAttribute,
			relatedBy: relation ?? self.relation,
			toItem: secondItem ?? self.secondItem,
			attribute: secondAttribute ?? self.secondAttribute,
			// The compiler fails to auto-convert to CGFloat here.
			multiplier: multiplier.flatMap(CGFloat.init) ?? self.multiplier,
			constant: constant.flatMap(CGFloat.init) ?? self.constant
		)
	}
}

// https://stackoverflow.com/questions/38343186/write-extend-file-attributes-swift-example/38343753#38343753
extension URL {

	/// Get extended attribute.
	func extendedAttribute(forName name: String) throws -> Data  {

		let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in

			// Determine attribute size:
			let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
			guard length >= 0 else { throw URL.posixError(errno) }

			// Create buffer with required size:
			var data = Data(count: length)

			// Retrieve attribute:
			let result =  data.withUnsafeMutableBytes { [count = data.count] in
				getxattr(fileSystemPath, name, $0.baseAddress, count, 0, 0)
			}
			guard result >= 0 else { throw URL.posixError(errno) }
			return data
		}
		return data
	}

	/// Set extended attribute.
	func setExtendedAttribute(data: Data, forName name: String) throws {

		try self.withUnsafeFileSystemRepresentation { fileSystemPath in
			let result = data.withUnsafeBytes {
				setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, 0)
			}
			guard result >= 0 else { throw URL.posixError(errno) }
		}
	}

	/// Remove extended attribute.
	func removeExtendedAttribute(forName name: String) throws {

		try self.withUnsafeFileSystemRepresentation { fileSystemPath in
			let result = removexattr(fileSystemPath, name, 0)
			guard result >= 0 else { throw URL.posixError(errno) }
		}
	}

	/// Get list of all extended attributes.
	func listExtendedAttributes() throws -> [String] {

		let list = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
			let length = listxattr(fileSystemPath, nil, 0, 0)
			guard length >= 0 else { throw URL.posixError(errno) }

			// Create buffer with required size:
			var namebuf = Array<CChar>(repeating: 0, count: length)

			// Retrieve attribute list:
			let result = listxattr(fileSystemPath, &namebuf, namebuf.count, 0)
			guard result >= 0 else { throw URL.posixError(errno) }

			// Extract attribute names:
			let list = namebuf.split(separator: 0).compactMap {
				$0.withUnsafeBufferPointer {
					$0.withMemoryRebound(to: UInt8.self) {
						String(bytes: $0, encoding: .utf8)
					}
				}
			}
			return list
		}
		return list
	}

	/// Helper function to create an NSError from a Unix errno.
	private static func posixError(_ err: Int32) -> NSError {
		return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
									 userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
	}
}

extension CMTime {
	var displayString: String {
		guard CMTIME_IS_NUMERIC(self) && isValid && !self.seconds.isNaN else {
			return "--:--"
		}
		let totalSeconds = Int(seconds)
		let minutes = totalSeconds / 60
		let seconds = totalSeconds % 60
		return String(format: "%02d:%02d", minutes, seconds)
	}
}

extension NSApplication {
  public enum Dock {
  }
}


// https://stackoverflow.com/a/68057340/30724926
extension NSApplication.Dock {
  
  public enum MenuBarVisibiityRefreshMenthod: Int {
    case viaMenuVisibilityToggle, viaSystemAppActivation
  }
  
  public static func refreshMenuBarVisibiity(method: MenuBarVisibiityRefreshMenthod) {
    switch method {
    case .viaMenuVisibilityToggle:
      DispatchQueue.main.async { // Async call not reaaly needed. But intuition tells to leave it.
        // See: cocoa - Hiding the dock icon without hiding the menu bar - Stack Overflow: https://stackoverflow.com/questions/23313571/hiding-the-dock-icon-without-hiding-the-menu-bar
        NSMenu.setMenuBarVisible(false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Without delay windows were not always been brought to front.
          NSMenu.setMenuBarVisible(true)
          NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }
      }
    case .viaSystemAppActivation:
      DispatchQueue.main.async { // Async call not reaaly needed. But intuition tells to leave it.
        if let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first {
          dockApp.activate(options: [])
        } else if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
          finderApp.activate(options: [])
        } else {
          assertionFailure("Neither Dock.app not Finder.app is found in system.")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Without delay windows were not always been brought to front.
          NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }
      }
    }
  }
  
  public enum AppIconDockVisibilityUpdateMethod: Int {
    case carbon, appKit
  }
  
  @discardableResult
  public static func setAppIconVisibleInDock(_ shouldShow: Bool, method: AppIconDockVisibilityUpdateMethod = .appKit) -> Bool {
    switch method {
    case .appKit:
      return toggleDockIconViaAppKit(shouldShow: shouldShow)
    case .carbon:
      return toggleDockIconViaCarbon(shouldShow: shouldShow)
    }
  }
  
  private static func toggleDockIconViaCarbon(shouldShow state: Bool) -> Bool {
    // Get transform state.
    let transformState: ProcessApplicationTransformState
    if state {
      transformState = ProcessApplicationTransformState(kProcessTransformToForegroundApplication)
    } else {
      transformState = ProcessApplicationTransformState(kProcessTransformToUIElementApplication)
    }
    
    // Show / hide dock icon.
    var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
    let transformStatus: OSStatus = TransformProcessType(&psn, transformState)
    return transformStatus == 0
  }
  
  private static func toggleDockIconViaAppKit(shouldShow state: Bool) -> Bool {
    let newPolicy: NSApplication.ActivationPolicy = state ? .regular : .accessory
    let result = NSApplication.shared.setActivationPolicy(newPolicy)
    return result
  }
}
