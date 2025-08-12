import SwiftUI
import Combine

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
          .blur(radius: 1.85)
        
        // idle blocks for volume
        Rectangle()
        .fill(Color.black.opacity(0.2))			}
      .padding(geometry.size.width * 0.2)
      .onReceive(
        NotificationCenter.default.publisher(for: .audioLevelUpdated)
          .map { $0.userInfo?["level"] as? Float ?? 0.0 }
          .merge(with: Just(0.0).delay(for: .milliseconds(500), scheduler: RunLoop.main))
          .removeDuplicates()
      ) { level in
        volumeAsString = level
      }
    }
	}
}

#Preview {
    VUMeter()
}
