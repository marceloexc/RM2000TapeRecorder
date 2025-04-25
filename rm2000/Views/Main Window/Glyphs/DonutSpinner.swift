import SwiftUI

enum spinnerGlyphDirection {
	case clockwise, counterclockwise
}

struct DonutSpinner: View {
	let direction: spinnerGlyphDirection
	var wedgeCount: Int = 11
	var gapAngle: Double = 2
	var strokeWidth: CGFloat = 1.0
	var innerRadiusRatio: CGFloat = 0.3
	let active: Bool
	
	@State private var activeWedgeIndex: Int = 0
	
	var body: some View {
		GeometryReader { geometry in
			let size = min(geometry.size.width, geometry.size.height)
			let outerRadius = (size / 2) - (strokeWidth / 2)
			let innerRadius = outerRadius * innerRadiusRatio
			let baseAngle = 360.0 / Double(wedgeCount)
			let offsetAngle = -105.0 // Make wedge 0 appear at the top
			
			ZStack {
				DonutShape(outerRadius: outerRadius, innerRadius: innerRadius)
					.stroke(.clear, lineWidth: strokeWidth)
				
				ForEach(0..<wedgeCount, id: \.self) { index in
					
					let wedgeAngle = baseAngle - gapAngle
					let startAngle = Double(index) * baseAngle + offsetAngle
					let endAngle = startAngle + wedgeAngle
					
					DonutWedgeShape(
						outerRadius: outerRadius,
						innerRadius: innerRadius,
						startAngle: .degrees(startAngle),
						endAngle: .degrees(endAngle)
					)
					.stroke(Color.clear, lineWidth: strokeWidth)
					.background(
						DonutWedgeShape(
							outerRadius: outerRadius,
							innerRadius: innerRadius,
							startAngle: .degrees(startAngle),
							endAngle: .degrees(endAngle)
						)
						.fill(index == activeWedgeIndex
									? Color("LCDTextColor")
									: Color("LCDTextColor").opacity(0.25))
					)
				}
			}
			.position(x: geometry.size.width / 2, y: geometry.size.height / 2)
		}
		.aspectRatio(1, contentMode: .fit)
		.onAppear {
			if active {
				startAnimation()
			} else {
				activeWedgeIndex = -1
			}
		}
	}
	
	func startAnimation() {
		Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
			withAnimation {
				switch direction {
				case .clockwise:
					activeWedgeIndex = (activeWedgeIndex + 1) % wedgeCount
				case .counterclockwise:
					activeWedgeIndex = (activeWedgeIndex - 1 + wedgeCount) % wedgeCount
				}
			}
		}
	}
}


struct DonutShape: Shape {
	var outerRadius: CGFloat
	var innerRadius: CGFloat
	
	func path(in rect: CGRect) -> Path {
		let center = CGPoint(x: rect.midX, y: rect.midY)
		
		var path = Path()
		
		// Outer circle
		path.addArc(center: center,
								radius: outerRadius,
								startAngle: .degrees(0),
								endAngle: .degrees(360),
								clockwise: false)
		
		// Inner circle (hole)
		path.addArc(center: center,
								radius: innerRadius,
								startAngle: .degrees(0),
								endAngle: .degrees(360),
								clockwise: true)
		
		return path
	}
}

struct DonutWedgeShape: Shape {
	var outerRadius: CGFloat
	var innerRadius: CGFloat
	var startAngle: Angle
	var endAngle: Angle
	
	func path(in rect: CGRect) -> Path {
		let center = CGPoint(x: rect.midX, y: rect.midY)
		
		var path = Path()
		
		// Line from inner start to outer start
		path.move(to: CGPoint(
			x: center.x + innerRadius * cos(startAngle.radians),
			y: center.y + innerRadius * sin(startAngle.radians)
		))
		
		path.addLine(to: CGPoint(
			x: center.x + outerRadius * cos(startAngle.radians),
			y: center.y + outerRadius * sin(startAngle.radians)
		))
		
		// Outer arc
		path.addArc(
			center: center,
			radius: outerRadius,
			startAngle: startAngle,
			endAngle: endAngle,
			clockwise: false
		)
		
		// Line from outer end to inner end
		path.addLine(to: CGPoint(
			x: center.x + innerRadius * cos(endAngle.radians),
			y: center.y + innerRadius * sin(endAngle.radians)
		))
		
		// Inner arc
		path.addArc(
			center: center,
			radius: innerRadius,
			startAngle: endAngle,
			endAngle: startAngle,
			clockwise: true
		)
		
		path.closeSubpath()
		
		return path
	}
}

#Preview("Donut Spinner") {
//	DonutSpinner(direction: .clockwise)
}
#Preview("LCD Screen") {
	LCDScreenView()
		.environmentObject(TapeRecorderState())
}

