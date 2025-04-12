// Modified version of this library
// https://github.com/fcanas/TokenField

import SwiftUI
import AppKit
import OSLog

fileprivate let Log = Logger(subsystem: "TokenField", category: "tokenﬁeld")

public struct TokenField<Data>: View, NSViewRepresentable where Data: RandomAccessCollection {
	
	@Binding private var data: Data
	
	private var conversion: (Data.Element) -> String
	var completions: [String] = []
	
	public init(_ data: Binding<Data>, _ tokenConversion: @escaping (Data.Element) -> String) {
		conversion = tokenConversion
		_data = data
	}
	
	public func makeCoordinator() -> Coordinator<Data> {
		Coordinator(self)
	}
	
	public final class Coordinator<Data>: NSObject, NSTokenFieldDelegate, ObservableObject where Data: RandomAccessCollection {
		
		var data: Binding<Data>?
		var parent: TokenField<Data>
		var completions: [String] = []
		
		internal init(_ parent: TokenField<Data>) {
			self.parent = parent
			self.conversion = parent.conversion
			self.completions = parent.completions
		}
		
		private final class RepresentedToken<E> where E: Identifiable {
			internal init(token: E, conversion: @escaping (E) -> String) {
				self.token = token
				self.conversion = conversion
			}
			var token: E
			var conversion: (E) -> String
		}
		
		var conversion: ((Data.Element) -> String)! = nil
		
		public func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
			return representedObject as? String
		}
		
		public func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
			return false
		}
		
		public func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
			return .rounded
		}
		
		public func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
			guard let newTokens = tokens as? [AnyHashable] else {
				Log.debug("New tokens are not hashable")
				return tokens
			}
			guard let existingTokens = tokenField.objectValue as? [AnyHashable] else {
				Log.debug("Existing tokens are not hashable")
				return tokens
			}
			Log.debug("candidate: \(newTokens)")
			Log.debug("existing: \(existingTokens)")
			var set = Set<AnyHashable>()
			
			return newTokens.filter { t in
				defer {set.insert(t)}
				return !set.contains(t)
			}
		}
		
		public func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
			// Only match suggestions that START with the typed substring
			return completions.filter { $0.lowercased().hasPrefix(substring.lowercased()) }
		}
		
		public func completions(_ completions: [String]) -> Self {
			var copy = self
			copy.completions = completions
			return copy
		}
		
		public func controlTextDidChange(_ obj: Notification) {
			guard let tf = obj.object as? NSTokenField else {
				Log.debug("Control text did change, but object not a token field")
				return
			}
			guard let data = tf.objectValue as? Data else {
				Log.debug("Control text did change, but object value data unexpected type: \(type(of: tf.objectValue))")
				return
			}
			self.data?.wrappedValue = data
		}
	}
	
	public func makeNSView(context: Context) -> NSTokenField {
		let tf = NSTokenField()
		tf.autoresizingMask = [.width, .height]
		tf.tokenStyle = .plainSquared
		tf.setContentHuggingPriority(.defaultLow, for: .vertical)
		
		tf.objectValue = data
		let cell = tf.cell as? NSTokenFieldCell
		cell?.setCellAttribute(.cellIsBordered, to: 1)
		cell?.tokenStyle = .rounded
		context.coordinator.data = _data
		context.coordinator.conversion = self.conversion
		tf.delegate = context.coordinator
		tf.lineBreakMode = .byTruncatingMiddle
		return tf
	}
	
	public func updateNSView(_ nsView: NSTokenField, context: Context) {
		if let b = nsView.superview?.bounds {
			context.coordinator.completions = self.completions
			nsView.frame = b
		}
	}
}

extension TokenField where Data.Element == String {
	public init(_ data: Binding<Data>) {
		conversion = {$0}
		_data = data
	}
}

extension TokenField {
	public func completions(_ completions: [String]) -> Self {
		var copy = self
		copy.completions = completions
		return copy
	}
}
