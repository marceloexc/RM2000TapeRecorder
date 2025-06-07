import SwiftUI

struct LCDScreenView: View {
	@EnvironmentObject private var recordingState: TapeRecorderState
	
	var body: some View {
		ZStack {
			
			if recordingState.status == .recording {
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
			LCDSymbolGlyphs()
			
			Image("LCDOuterGlow")
				.resizable()
				.frame(width: 330)
		}
	}
}

struct LCDSymbolGlyphs: View {
	@EnvironmentObject private var recordingState: TapeRecorderState

	var body: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				HStack { // top half
					VStack(alignment: .leading, spacing: 4) {
						LCDTextCaptionWithGradient("STEREO 44.1kHz")
						
						HStack(spacing: 6) {
							
							// todo - just make donutsspinner have an @EnvrionmentObject of recordingState
							if recordingState.status == .recording {
								DonutSpinner(direction: .counterclockwise, active: true)
								DonutSpinner(direction: .clockwise, active: true)
							} else {
								DonutSpinner(direction: .counterclockwise, active: false)
								DonutSpinner(direction: .clockwise, active: false)
							}

							RecordingGlyph()
							SourceGlyph()
							ErrorGlyph()
						}
					}.frame(width: 125, height: 40)
						.padding(.trailing, -20)
				}
				
				VStack(alignment: .leading) {
					LCDTextBig(recordingState.sampleRecordAudioFormat.asString.uppercased())
					
					if recordingState.status == .recording {
						LCDTextBigWithGradient(timeString(recordingState.elapsedTimeRecording))
							.frame(maxWidth: 150, alignment: .leading)
					} else {
						LCDTextBigWithGradient("STBY")
							.frame(maxWidth: 150, alignment: .leading)
					}
				}.padding(.leading, 3)
			}
			
			VUMeter()
				.mask(LinearGradient(
          colors: [Color(hex: 0x220300, alpha: 0),
                   Color(hex: 0x220300, alpha: 0.3),
									 Color(hex: 0x220300)],
					startPoint: .bottom,
					endPoint: .top
				))
				.colorEffect(Shader(function: .init(library: .default, name: "dotMatrix"), arguments: []))
				.shadow(color: .black.opacity(0.35), radius: 1, x: 2, y: 4)

				.frame(width: 60, height: 155)
				.padding(.leading, -20)
			// todo - too close. claustrophobic
		}	.frame(width: 200, height: 168)
	}
}

struct LCDTextStyle: ViewModifier {
	func body(content: Content) -> some View {
		content

	}
}

extension Font {
	static let tachyoFont = Font.custom("Tachyo", size: 41)
	static let tachyoFontBig = Font.custom("Tachyo", size: 61)
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

struct LCDTextCaptionWithGradient: View {
	var title: String
	
	init(_ title: String) {
		self.title = title
	}
	
	var body: some View {
		Text(title)
			.foregroundStyle(LinearGradient(
				colors: [Color(hex: 0x220300, alpha: 0.32),
								 Color(hex: 0x220300)],
				startPoint: .top,
				endPoint: .bottom
			))
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

struct LCDTextBigWithGradient: View {
	var title: String
	
	init(_ title: String) {
		self.title = title
	}
	
	var body: some View {
		Text(" \(title) ")
			.foregroundStyle(LinearGradient(
				colors: [Color(hex: 0x220300, alpha: 0.32),
								 Color(hex: 0x220300)],
				startPoint: .bottom,
				endPoint: .top
			))
			.shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 4)
			.font(Font.tachyoFont)
			.fontWeight(.medium)
			.fixedSize()
			.offset(x: -15)
			.kerning(-1.5)
	}
}

struct LCDTextBigWithGradientHUD: View {
	var title: String
	
	init(_ title: String) {
		self.title = title
	}
	
	var body: some View {
		Text(" \(title) ")
			.foregroundStyle(LinearGradient(
				colors: [Color(hex: 0x220300, alpha: 0.32),
								 Color(hex: 0x220300)],
				startPoint: .bottom,
				endPoint: .top
			))
			.shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 4)
			.font(Font.tachyoFontBig)
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

#Preview("LCD Symbols") {
	LCDSymbolGlyphs()
		.environmentObject(TapeRecorderState())
		.border(.black)
		.padding()
}
