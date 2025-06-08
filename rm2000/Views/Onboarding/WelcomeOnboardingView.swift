import SwiftUI

struct WelcomeOnboardingView: View {

  var pText0: AttributedString {
    var result = AttributedString("Welcome to\n")
    result.font = .custom("LucidaGrande-Bold", size: 24)
    result.kern = -1.0
    return result
  }

  var pText1: AttributedString {
    var result = AttributedString("RM2000")
    result.font = .custom("LucidaGrande-Bold", size: 24)
    result.kern = -1.0
    return result
  }

  var pText2: AttributedString {
    var result = AttributedString(" Tape Recorder")
    result.font = .custom("LucidaGrande-Bold", size: 19)
    result.kern = -1.0
    return result
  }
  var body: some View {
    VStack(spacing: 15) {
      Image("MainWindowBitmap")
        .resizable()
        .scaledToFit()
        .frame(height: 300)
        .shadow(color: .black, radius: 5)

      Text(pText0 + pText1 + pText2)
        .multilineTextAlignment(.center)
        .shadow(color: Color(hex: 0x898a8b), radius: 10)

    }
    .frame(width: 600, height: 500)
    .background(
      GeometryReader { geometry in
        RadialGradient(
          gradient: Gradient(stops: [
            .init(color: Color(hex: 0xc1c6c4), location: 0.04),
            .init(color: Color(hex: 0x959d9f), location: 0.16),
            .init(color: Color(hex: 0x6c757a), location: 0.28),
            .init(color: Color(hex: 0x454e56), location: 0.40),
            .init(color: Color(hex: 0x212732), location: 0.52),
            .init(color: Color(hex: 0x00010f), location: 0.65),
          ]),
          center: UnitPoint(x: 0.5, y: 0.7),
          startRadius: 0,
          endRadius: max(geometry.size.width, geometry.size.height) * 0.75
        )
        .scaleEffect(x: 1.4, y: 1)
      }
    )
  }
}

#Preview {
  WelcomeOnboardingView()
}
