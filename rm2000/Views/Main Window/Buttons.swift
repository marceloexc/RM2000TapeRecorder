import SwiftUI

struct UtilityButtons: View {
	@Environment(\.openWindow) var openWindow
	@Environment(\.openSettingsLegacy) private var openSettingsLegacy
	@State private var isPressed = false
	
	var body: some View {
		Button(action: { try? openSettingsLegacy() }) {
			Image("SettingsButton")
		}
		.buttonStyle(AnimatedButtonStyle())
		
		Button(action: { openWindow(id: "recordings-window") }) {
			Image("FolderButton")
				.renderingMode(.original)
		}.buttonStyle(AnimatedButtonStyle())
		
		Menu {
      Button {
        //
      } label: {
        Label("System Audio (active)", systemImage: "checkmark")
      }

		} label: {
			Image("SourceButton")
		}
		.buttonStyle(AnimatedButtonStyle())
	}
}

struct AnimatedButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.background(.clear)
			.scaleEffect(configuration.isPressed ? 0.94 : 1.0)
			.animation(
				.spring(response: 0.3, dampingFraction: 0.6),
				value: configuration.isPressed)
	}
}

struct StandbyRecordButton: View {
	var onPress: () -> Void
	
	var body: some View {
		ZStack {
			Image("RecordButtonIndent")
			Image("RecordButtonTemp")
			Image("RecordButtonGlow")
				.resizable()
				.frame(width: 180, height: 180)
				.allowsHitTesting(false)
			
			Button(action: onPress) {
				Rectangle()
				// i cant have opactiy(0) on a button, because then that disables it completely
					.fill(Color.white.opacity(0.001))
					.frame(width: 70, height: 70)
			}
			.buttonStyle(AnimatedButtonStyle())
		}
		.frame(height: 80)
	}
}

struct ActiveRecordButton: View {
	var onPress: () -> Void
	
	var body: some View {
		ZStack {
			Image("RecordButtonIndent")
			Image("RecordButtonActiveTemp")
			Image("RecordButtonTemp")
				.pulseEffect()
			Image("RecordButtonGlow")
				.resizable()
				.frame(width: 200, height: 200)
				.pulseEffect()
				.allowsHitTesting(false)

			
			Button(action: onPress) {
				Rectangle()
					.fill(Color.white.opacity(0.001))  //stupid hack again
					.frame(width: 70, height: 70)
			}
			.buttonStyle(AnimatedButtonStyle())
		}
		.frame(height: 80)
	}
}

// https:stackoverflow.com/questions/61778108/swiftui-how-to-pulsate-image-opacity
struct PulseEffect: ViewModifier {
	@State private var pulseIsInMaxState: Bool = true
	private let range: ClosedRange<Double>
	private let duration: TimeInterval
	
	init(range: ClosedRange<Double>, duration: TimeInterval) {
		self.range = range
		self.duration = duration
	}
	
	func body(content: Content) -> some View {
		content
			.opacity(pulseIsInMaxState ? range.upperBound : range.lowerBound)
			.onAppear { pulseIsInMaxState.toggle() }
			.animation(
				.easeInOut(duration: duration).repeatForever(autoreverses: true),
				value: pulseIsInMaxState)
	}
}

extension View {
	public func pulseEffect(
		range: ClosedRange<Double> = 0.1...1, duration: TimeInterval = 1
	) -> some View {
		modifier(PulseEffect(range: range, duration: duration))
	}
}

#Preview("RecordingButton") {
  StandbyRecordButton(onPress: ({print("Hello world")}))
    .frame(width: 300, height:300)
}
