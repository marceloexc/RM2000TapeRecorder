import Foundation
import Combine
import AVKit

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

enum AudioFormat: String {
	case aac, mp3, flac, wav
}

protocol FileRepresentable {
	var fileURL: URL { get }
}

extension NewRecording: FileRepresentable { }
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

extension AVPlayerView {
	/**
	Activates trim mode without waiting for trimming to finish.
	*/
	func activateTrimming() async throws { // TODO: `throws(CancellationError)`.
		_ = await updates(for: \.canBeginTrimming).first { $0 }

		try Task.checkCancellation()

		Task {
			await beginTrimming()
		}

		await Task.yield()
	}
	
	func hideTrimButtons() {
		// This method is a collection of hacks, so it might be acting funky on different OS versions.
		guard
			let avTrimView = firstSubview(deep: true, where: { $0.simpleClassName == "AVTrimView" }),
			let superview = avTrimView.superview
		else {
			return
		}

		// First find the constraints for `avTrimView` that pins to the left edge of the button.
		// Then replace the left edge of a button with the right edge - this will stretch the trim view.
		if let constraint = superview.constraints.first(where: {
			($0.firstItem as? NSView) == avTrimView && $0.firstAttribute == .right
		}) {
			superview.removeConstraint(constraint)
			constraint.changing(secondAttribute: .right).isActive = true
		}

		if let constraint = superview.constraints.first(where: {
			($0.secondItem as? NSView) == avTrimView && $0.secondAttribute == .right
		}) {
			superview.removeConstraint(constraint)
			constraint.changing(firstAttribute: .right).isActive = true
		}

		// Now find buttons that are not images (images are playing controls) and hide them.
		superview.subviews
			.first { $0 != avTrimView }?
			.subviews
			.filter { ($0 as? NSButton)?.image == nil }
			.forEach {
				$0.isHidden = true
			}
	}
	
	open override func cancelOperation(_ sender: Any?) {}

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
