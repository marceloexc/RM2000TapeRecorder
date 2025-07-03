 import SwiftUI

struct WhatsNewView: View {
  var body: some View {
    ZStack {
      VStack(alignment: .leading) {
        Text("What's New in \nRM2000 Tape Recorder")
          .font(.custom("LucidaGrande-Bold", size: 24))
          .kerning(-2.0)
          .padding()
          .foregroundStyle(Color.black)
        Text("Hello there guys how are you doing?")
        
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.init(hex: 0xf1f1f1))
    //    .background(
    //      GeometryReader { geometry in
    //        LinearGradient(
    //          gradient: Gradient(stops: [
    //            .init(color: Color(hex: 0xa5a5a5), location: 0.01),
    //            .init(color: Color(hex: 0xa5a5a5), location: 0.78),
    //            .init(color: Color(hex: 0x3d3f3a), location: 0.95),
    //          ]),
    //          startPoint: .top,
    //          endPoint: .bottom
    //        )
    //      }
    //    )
    //
    //    .overlay {
    //      Rectangle()
    //        .colorEffect(
    //          ShaderLibrary.randomNoise(
    //            .float(99.0)
    //          )
    //        )
    //        .opacity(0.03)
    //    }
    //  }
  }
}

#Preview {
    WhatsNewView()
    .frame(width: 300, height: 400)
}
