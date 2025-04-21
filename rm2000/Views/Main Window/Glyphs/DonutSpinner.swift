import SwiftUI

struct DonutSpinner: View {
	var wedgeCount: Int = 8
	var gapAngle: Double = 2
	var strokeWidth: CGFloat = 1.0
	var innerRadiusRatio: CGFloat = 0.3
	
	@State private var activeWedgeIndex: Int = 0
	
	var body: some View {
		GeometryReader { geometry in
			// Calculate the outer radius based on the available space
			let size = min(geometry.size.width, geometry.size.height)
			let outerRadius = (size / 2) - (strokeWidth / 2)
			let innerRadius = outerRadius * innerRadiusRatio
			
			ZStack {
				// Base donut shape
				DonutShape(outerRadius: outerRadius, innerRadius: innerRadius)
					.stroke(.clear, lineWidth: strokeWidth)
				
				// Stationary wedges with outlines
				ForEach(0..<wedgeCount, id: \.self) { index in
					let wedgeAngle = (360.0 / Double(wedgeCount)) - gapAngle
					
					DonutWedgeShape(
						outerRadius: outerRadius,
						innerRadius: innerRadius,
						startAngle: .degrees(Double(index) * (360.0 / Double(wedgeCount))),
						endAngle: .degrees(Double(index) * (360.0 / Double(wedgeCount)) + wedgeAngle)
					)
					.stroke(Color.clear, lineWidth: strokeWidth)
					.background(
						DonutWedgeShape(
							outerRadius: outerRadius,
							innerRadius: innerRadius,
							startAngle: .degrees(Double(index) * (360.0 / Double(wedgeCount))),
							endAngle: .degrees(Double(index) * (360.0 / Double(wedgeCount)) + wedgeAngle)
						)
						.fill(index == activeWedgeIndex ? Color("LCDTextColor") : Color("LCDTextColor").opacity(0.25))
					)
				}
			}
			.position(x: geometry.size.width / 2, y: geometry.size.height / 2)
		}
		.aspectRatio(1, contentMode: .fit)
		.onAppear {
			startAnimation()
		}
	}
	
	func startAnimation() {
		Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
			withAnimation {
				activeWedgeIndex = (activeWedgeIndex + 1) % wedgeCount
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
	DonutSpinner()
}
#Preview("LCD Screen") {
	LCDScreenView()
		.environmentObject(TapeRecorderState())
}

