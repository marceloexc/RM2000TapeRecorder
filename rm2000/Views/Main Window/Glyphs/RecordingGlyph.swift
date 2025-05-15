import SwiftUI

// CLAUDE SUCKS
struct SmoothPulseEffect: ViewModifier {
	let active: Bool
	@State private var opacity: Double = 1.0
	@State private var isAnimating: Bool = false
	private let minOpacity: Double
	private let maxOpacity: Double
	private let duration: TimeInterval
	
	init(active: Bool, range: ClosedRange<Double> = 0.2...1.0, duration: TimeInterval = 0.8) {
		self.active = active
		self.minOpacity = range.lowerBound
		self.maxOpacity = range.upperBound
		self.duration = duration
	}
	
	func body(content: Content) -> some View {
		content
			.opacity(opacity)
			.onChange(of: active) { wasActive, isActive in
				if isActive && !wasActive {
					startPulsing()
				} else if !isActive && wasActive {
					stopPulsing()
				}
			}
			.onAppear {
				opacity = active ? maxOpacity : minOpacity
				if active {
					startPulsing()
				}
			}
	}
	
	private func startPulsing() {
		isAnimating = true
		withAnimation(.easeIn(duration: 0.3)) {
			opacity = maxOpacity
		}
		withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
			opacity = minOpacity
		}
	}
	
	private func stopPulsing() {
		isAnimating = false
		// smoothly transition to the idle opacity
		withAnimation(.easeOut(duration: 0.3)) {
			opacity = minOpacity
		}
	}
}

extension View {
	func smoothPulseEffect(
		active: Bool,
		range: ClosedRange<Double> = 0.2...1.0,
		duration: TimeInterval = 0.8
	) -> some View {
		modifier(SmoothPulseEffect(active: active, range: range, duration: duration))
	}
}

struct RecordingGlyph: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	
	var body: some View {
		Image(systemName: "recordingtape")
			.rotationEffect(.degrees(180))
			.fontWeight(.black)
			.foregroundColor(Color("LCDTextColor"))
			.smoothPulseEffect(
				active: recordingState.status == .busy,
				range: recordingState.status == .busy ? 0.2...0.9 : 0.25...0.25)
	}
}

#Preview {
    RecordingGlyph()
}
