import Foundation
import SwiftUI
import OSLog

struct MenuBarView: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	@EnvironmentObject private var sampleStorage: SampleStorage
	@Environment(\.openWindow) private var openWindow
	
  weak var appDelegate: AppKitWindowManagerDelegate?
	
	var body: some View {
		VStack(spacing: 12) {
			// Header
			HStack {
				Text("RM2000 Tape Recorder")
					.font(.system(.headline))
					.fontWeight(.bold)
			}
			.padding(.top, 5)
			
			VStack() {
				
				Button(action: {
					if recordingState.status == .recording {
						recordingState.stopRecording()
					} else {
						recordingState.startRecording()
					}
				}) {
					HStack {
						Image(systemName: recordingState.status == .recording ? "stop.circle" : "record.circle")
							.contentTransition(.symbolEffect)
							.foregroundColor(recordingState.status == .recording ? .red.opacity(0.70) : .red)
						Text(recordingState.status == .recording ? "Stop Recording" : "Start Recording")
							.fontWeight(.medium)
						Spacer()
						
						if recordingState.status == .recording {
							ElapsedTime(textString: $recordingState.elapsedTimeRecording)
								.font(.system(.footnote, design: .monospaced))
								.padding(.horizontal, 6)
								.background(Color.secondary.opacity(0.15))
								.cornerRadius(4)
						}
					}
					.contentShape(Rectangle())
				}
			}
			.buttonStyle(MenuButtonStyle())
			.padding(.vertical, 3)
			.padding(.horizontal, 8)
			.background(
				RoundedRectangle(cornerRadius: 6)
					.fill(Color.secondary.opacity(0.07))
			)
			
			Divider()
			
			VStack() {
				Button(action: {
          appDelegate?.showMainWindow()
				}) {
					HStack {
						Image(systemName: "macwindow")
						Text("Open Main Window...")
							.fontWeight(.medium)
						Spacer()
					}
					.contentShape(Rectangle())
				}
				.buttonStyle(MenuButtonStyle())
				
				Button(action: {
					openWindow(id: "recordings-window")
				}) {
					HStack {
						Image(systemName: "rectangle.split.3x1")
						Text("Open Sample Library...")
							.fontWeight(.medium)
						Spacer()
					}
					.contentShape(Rectangle())
				}
				.buttonStyle(MenuButtonStyle())
			}
			
			Divider()
			
      if (StoreManager.shared.isTrialActive) {
        Text("Trial: \(StoreManager.shared.daysRemaining) day(s) left")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal, 4)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.secondary.opacity(0.2))
          )
      } else if (StoreManager.shared.isTrialExpired) {
        Text("Trial Expired!")
          .font(.caption)
          .foregroundColor(.red)
          .padding(.horizontal, 4)
          .background(
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.secondary.opacity(0.2))
          )
      }
      
			// Footer
			Button(action: {
				NSApplication.shared.terminate(nil)
			}) {
				HStack {
					Image(systemName: "power")
						.foregroundColor(.red.opacity(0.8))
						.fontWeight(.bold)

					Text("Quit RM2000")
						.fontWeight(.medium)
					Spacer()
					Text("⌘Q")
						.font(.caption2)
						.foregroundColor(.secondary)
				}
				.contentShape(Rectangle())
			}
			.buttonStyle(MenuButtonStyle())
			.keyboardShortcut("q")
			.padding(.bottom, 5)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.frame(width: 240)
	}
}

struct MenuButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding(.vertical, 2)
			.padding(.horizontal, 8)
			.background(
				RoundedRectangle(cornerRadius: 6)
					.fill(configuration.isPressed ?
								Color.accentColor.opacity(0.15) :
									Color.clear)
			)
	}
}

struct ElapsedTime: View {
	@Binding var textString: TimeInterval
	
	var body: some View {
		Text(timeString(textString))
	}
}

#Preview {
	MenuBarView()
		.environmentObject(TapeRecorderState())
		.environmentObject(SampleStorage())
}
