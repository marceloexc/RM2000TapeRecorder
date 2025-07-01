 import SwiftUI

struct WhatsNewView: View {
    var body: some View {
      ZStack {
        Text("What's New?")
          .font(.custom("InstrumentSerif-Regular", size: 40))
          .kerning(-2.0)
          .foregroundStyle(Color(hex: 0xadc1c8))
//          .shadow(color: .black, radius: 1, y: 1)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            GeometryReader { geometry in
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: 0x809fb4), location: 0.01),
                  .init(color: Color(hex: 0x6980a9), location: 0.24),
                  .init(color: Color(hex: 0x32386a), location: 0.64),
                  .init(color: Color(hex: 0x140f16), location: 0.95),
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
//              .scaleEffect(x: 1.4, y: 1)
              .frame(width: geometry.size.width, height: geometry.size.height)
            }
          )
      }
    }
}

#Preview {
    WhatsNewView()
}
