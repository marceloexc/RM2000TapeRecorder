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
		HStack(alignment: .center) {
			VStack(alignment: .leading) {
				HStack {
					VStack(alignment: .leading, spacing: 4) {
						let hello = [true, true, false, true, false, true, true, true]
						SegmentedCircleView(segments: hello)
						LCDTextCaption("STEREO 44.1kHz")
					}.frame(width: 100, height: 40)
				}
				
				LCDTextBig("M4A")
					.padding(.top, 15)
				if recordingState.isRecording {
					LCDTextBig(timeString(recordingState.elapsedTimeRecording))
						.frame(maxWidth: 150, alignment: .leading)
				} else {
					LCDTextBig("STBY")
						.frame(maxWidth: 150, alignment: .leading)
				}
			}/*.frame(maxWidth: 170, alignment: .leading)*/
			
			VUMeter()
				.colorEffect(Shader(function: .init(library: .default, name: "dotMatrix"), arguments: []))
				.shadow(color: .black.opacity(0.35), radius: 1, x: 2, y: 4)
				.frame(width: 40, height: 155)
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
					.fill(Color("LCDTextColor"))
					.frame(height: geometry.size.height * CGFloat(self.volumeAsString))
					.animation(.easeOut(duration:0.05))
				
				// idle blocks for volume
				Rectangle()
					.fill(Color.black.opacity(0.2))			}
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

struct SegmentedCircleView: View {
	let segments: [Bool]
	var activeColor: Color = Color("LCDTextColor")
	var spacingColor: Color = Color(.black).opacity(0.25)
	
	private let totalSegments = 8
	private var segmentAngle: Double { 2 * .pi / Double(totalSegments) }
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				// Background circle (visible between segments)
				Circle()
					.fill(spacingColor)
				
				// Segments
				ForEach(0..<totalSegments, id: \.self) { index in
					if segments.indices.contains(index) && segments[index] {
						Wedge(startAngle: startAngle(for: index),
									endAngle: endAngle(for: index))
						.fill(activeColor)
					}
				}
			}
			.padding(1)
		}
	}
	
	private func startAngle(for index: Int) -> Double {
		-Double.pi/2 + Double(index) * segmentAngle
	}
	
	private func endAngle(for index: Int) -> Double {
		startAngle(for: index) + segmentAngle
	}
}

struct Wedge: Shape {
	let startAngle: Double
	let endAngle: Double
	
	func path(in rect: CGRect) -> Path {
		var path = Path()
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = min(rect.width, rect.height) / 2
		
		// Create thicker segments by using 90% of the available space
		let adjustedRadius = radius * 0.9
		
		path.move(to: center)
		path.addArc(center: center, radius: adjustedRadius,
								startAngle: Angle(radians: startAngle),
								endAngle: Angle(radians: endAngle),
								clockwise: false)
		path.closeSubpath()
		return path
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

#Preview("LCD Symbols") {
	LCDScreenSymbols()
		.environmentObject(TapeRecorderState())
		.border(.black)
		.padding()
}

#Preview("Segmented Circle") {
	
	let hello = [true, true, false, true, false, true, true, true]
	let segments = Array(repeating: true, count: 8)
	SegmentedCircleView(segments: hello)
}
