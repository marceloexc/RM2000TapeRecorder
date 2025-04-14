import SwiftUI

struct LCDScreenView: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	
	var body: some View {
		ZStack {
			Image("LCDScreenEmptyTemp")
				.resizable()
				.scaledToFit()
				.frame(width: 300)
				.offset(x: 0, y: 0)
			
			LCDScreenSymbols()
			
			Image("LCDOuterGlow")
				.resizable()
				.frame(width: 330)
		}
	}

}

struct LCDScreenSymbols: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	
	
	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				HStack {
					VStack(alignment: .leading, spacing: 4) {
						LCDTextCaption("STEREO 44.1kHz")
						LCDTextCaption("16 BIT")
					}.frame(width: 100)
					Spacer()
				}
				
				LCDTextBig("M4A")
					.padding(.top, 15)
				if recordingState.isRecording {
					LCDTextBig(timeString(recordingState.elapsedTimeRecording))
				} else {
					LCDTextBig("STBY")
				}
			}.frame(maxWidth: 150)
			
			VUMeter()
				.frame(width: 50, height: 155)
		}	.frame(width: 200, height: 168)
	}
	
	
	private func timeString(_ time: TimeInterval) -> String {
		let minutes = Int(time) / 60
		let seconds = Int(time) % 60
		return String(format: "%02d:%02d", minutes, seconds)
	}
}

struct VUMeter: View {
	
	@State var volumeAsString: Float = 0.0
	
	var body: some View {
		GeometryReader
		{ geometry in
			ZStack(alignment: .bottom){
				
				// Colored rectangle in back of ZStack
				Rectangle()
					.fill(LinearGradient(gradient: Gradient(colors: [.red, .yellow, .green]), startPoint: .top, endPoint: .center))
				Rectangle()
					.fill(Color.black)
					.mask(Rectangle().padding(.bottom, geometry.size.height * CGFloat(self.volumeAsString)))
					.animation(.easeOut(duration: 0.05))
			}
			.padding(geometry.size.width * 0.2)
			.onReceive(NotificationCenter.default.publisher(for: .audioLevelUpdated)) { levels in
				if var level = levels.userInfo?["level"] as? Float {
					volumeAsString = level
				} else {
					volumeAsString = 0.0
				}
			}
		}
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
