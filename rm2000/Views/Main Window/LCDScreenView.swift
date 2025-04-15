import SwiftUI

struct LCDScreenView: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	
	var body: some View {
		ZStack {
			
			if recordingState.isRecording {
				Image("LCDScreenFrameRecording")
					.resizable()
					.scaledToFit()
					.frame(width: 300)
					.offset(x: 0, y: 0)
			} else {
				Image("LCDScreenFrameInactive")
					.resizable()
					.scaledToFit()
					.frame(width: 300)
					.offset(x: 0, y: 0)
			}

			
			VStack(alignment: .leading) {
				HStack {
					VStack(alignment: .leading, spacing: 4) {
						LCDTextCaption("STEREO 44.1kHz")
						LCDTextCaption("16 BIT")
					}
					Spacer()
				}
				
				LCDTextBig("M4A")
					.padding(.top, 15)
				if recordingState.isRecording {
					LCDTextBig(timeString(recordingState.elapsedTimeRecording))
				} else {
					LCDTextBig("STBY")
				}
			}
			.frame(width: 200, height: 168)
			
			Image("LCDOuterGlow")
				.resizable()
				.frame(width: 330)
		}
	}
	
	private func timeString(_ time: TimeInterval) -> String {
		let minutes = Int(time) / 60
		let seconds = Int(time) % 60
		return String(format: " %02d:%02d ", minutes, seconds)
	}
}

struct LCDTextStyle: ViewModifier {
	func body(content: Content) -> some View {
		content

	}
}

extension Font {
	static let tachyoFont = Font.custom("Tachyo", size: 41)
	static let tasaFont = Font.custom("TASAExplorer-SemiBold", size: 14)
}

extension View {
	func LCDText() -> some View {
		modifier(LCDTextStyle())
	}
}

struct LCDTextCaption: View {
	var title: String
	
	init(_ title: String) {
		self.title = title
	}
	
	var body: some View {
		Text(title)
			.foregroundColor(Color("LCDTextColor"))
			.shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 4)
			.font(Font.tasaFont)
	}
}

struct LCDTextBig: View {
	var title: String
	
	init(_ title: String) {
		self.title = title
	}
	
	var body: some View {
		Text(" \(title) ")
			.foregroundColor(Color("LCDTextColor"))
			.shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 4)
			.font(Font.tachyoFont)
			.fontWeight(.medium)
			.fixedSize()
			.offset(x: -15)
			.kerning(-1.5)
	}
}

#Preview("LCD Screen") {
	LCDScreenView()
		.environmentObject(TapeRecorderState())
}
