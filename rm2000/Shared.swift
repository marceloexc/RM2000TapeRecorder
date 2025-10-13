import Foundation
import SwiftUI
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
	
  var attributes: [FileAttributeKey : Any]? {
    do {
      return try FileManager.default.attributesOfItem(atPath: path)
    } catch let error as NSError {
      print("FileAttribute error: \(error)")
    }
    return nil
  }
  
  var fileSize: UInt64 {
    return attributes?[.size] as? UInt64 ?? UInt64(0)
  }
  
  var fileSizeString: String {
    return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
  }
  
  var creationDate: Date? {
    return attributes?[.creationDate] as? Date
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

// https://stackoverflow.com/a/39501096/30724926
extension URL {
  /// The time at which the resource was created.
  /// This key corresponds to an Date value, or nil if the volume doesn't support creation dates.
  /// A resource’s creationDateKey value should be less than or equal to the resource’s contentModificationDateKey and contentAccessDateKey values. Otherwise, the file system may change the creationDateKey to the lesser of those values.
  var creation: Date? {
    get {
      return (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate
    }
    set {
      var resourceValues = URLResourceValues()
      resourceValues.creationDate = newValue
      try? setResourceValues(resourceValues)
    }
  }
  /// The time at which the resource was most recently modified.
  /// This key corresponds to an Date value, or nil if the volume doesn't support modification dates.
  var contentModification: Date? {
    get {
      return (try? resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
    set {
      var resourceValues = URLResourceValues()
      resourceValues.contentModificationDate = newValue
      try? setResourceValues(resourceValues)
    }
  }
  /// The time at which the resource was most recently accessed.
  /// This key corresponds to an Date value, or nil if the volume doesn't support access dates.
  ///  When you set the contentAccessDateKey for a resource, also set contentModificationDateKey in the same call to the setResourceValues(_:) method. Otherwise, the file system may set the contentAccessDateKey value to the current contentModificationDateKey value.
  var contentAccess: Date? {
    get {
      return (try? resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate
    }
    // Beginning in macOS 10.13, iOS 11, watchOS 4, tvOS 11, and later, contentAccessDateKey is read-write. Attempts to set a value for this file resource property on earlier systems are ignored.
    set {
      var resourceValues = URLResourceValues()
      resourceValues.contentAccessDate = newValue
      try? setResourceValues(resourceValues)
    }
  }
}

func timeString(_ time: TimeInterval) -> String {
	let minutes = Int(time) / 60
	let seconds = Int(time) % 60
	return String(format: "%02d:%02d", minutes, seconds)
}

extension Double {
  var formattedDuration: String {
    let totalMilliseconds = Int((self * 100).rounded())
    let mins = totalMilliseconds / 6000
    let secs = (totalMilliseconds % 6000) / 100
    let millis = totalMilliseconds % 100
    return String(format: "%d:%02d.%02d", mins, secs, millis)
  }
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
  var title: String { get }
}

extension TemporaryActiveRecording: FileRepresentable {
  var title: String {
    "Temporary Audio File"
  }
}
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

extension View {
    func modify<Content>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}

struct StandardSheetSizingModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content
                .presentationSizing(.fitted)
        } else {
            content
                .introspect(.window, on: .macOS(.v14)) { window in
                    window.styleMask.formUnion(.resizable)
                }
        }
    }
}

func showNSAlert(error: Error) {
  let alert = NSAlert()
  alert.messageText = "Error processing audio"
  alert.informativeText = error.localizedDescription
  alert.alertStyle = .critical
  alert.addButton(withTitle: "OK")
  alert.runModal()
}
