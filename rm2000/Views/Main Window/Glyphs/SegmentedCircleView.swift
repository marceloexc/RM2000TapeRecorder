//
//  SegmentedCircleView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 4/19/25.
//

import SwiftUI

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


#Preview {
	
	let hello = [true, true, false, true, false, true, true, true]
	let segments = Array(repeating: true, count: 8)
	SegmentedCircleView(segments: hello)
}

