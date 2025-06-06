import SwiftUI

struct LicenseTabView: View {
  
  @ObservedObject private var storeManager = StoreManager.shared
  
  var pText0: AttributedString {
    var result = AttributedString("Purchase\n")
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
    Form {
      VStack (spacing: 200) {
        VStack {
          Image(nsImage: NSApp.applicationIconImage)
            .shadow(radius: 6)
          Text(pText0 + pText1 + pText2)
            .foregroundStyle(Color(.black))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        VStack {
          
          Text("Thank you for downloading my little indie app! I built RM2000 Tape Recorder because I struggled to find a way to curate sounds. It is a native Mac application, using native frameworks, and has a gorgeous retro user interface.")
            .font(.custom("LucidaGrande", size: 15))
            .lineSpacing(1.2)
            .foregroundStyle(Color(hex: 0xa3a5a6))
            .kerning(-1)
          
          Button {
            print("hello")
          } label: {
            Text("Buy now")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.extraLarge)
          
          
          if storeManager.hasPurchasedApp {
            Text("Thank you for Purchasing!!")
              .font(.custom("LucidaGrande", size: 16))
              .foregroundStyle(Color(hex: 0x898a8b))
              .kerning(-1)
          }
        }
        .frame(width: 400)
      }
    }
    .frame(minWidth: 500, minHeight: 620)
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
          center: UnitPoint(x: 0.5, y: 0.33),
          startRadius: 0,
          endRadius: max(geometry.size.width, geometry.size.height) * 0.6
        )
        .scaleEffect(x: 2.5  , y: 1)
      }
    )
  }
  
}

#Preview ("License Tab"){
    LicenseTabView()
}
#Preview("Settings view") {
  SettingsView()
    .environmentObject(AppState.shared)

}
