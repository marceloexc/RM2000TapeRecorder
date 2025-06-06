import SwiftUI

struct LicenseTabView: View {
  var body: some View {
    Form {
      VStack {
        Image(nsImage: NSApp.applicationIconImage)
        Text("Purchase\nRM2000 Tape Recorder")
          .font(.custom("Lucida Grande", size: 18))
          .fontWeight(.bold)
          .kerning(-0.8)
          .multilineTextAlignment(.center)
      }
    }
    .frame(minWidth: 420, maxWidth: 500, minHeight: 320)
    .background(
      GeometryReader { geometry in
        RadialGradient(
          gradient: Gradient(stops: [
            .init(color: Color(red: 0.7568, green: 0.7764, blue: 0.7686), location: 0.04), // #c1c6c4
            .init(color: Color(red: 0.5843, green: 0.6156, blue: 0.6235), location: 0.28), // #959d9f
            .init(color: Color(red: 0.4235, green: 0.4588, blue: 0.4784), location: 0.46), // #6c757a
            .init(color: Color(red: 0.2705, green: 0.3058, blue: 0.3372), location: 0.64), // #454e56
            .init(color: Color(red: 0.1294, green: 0.1529, blue: 0.1960), location: 0.82), // #212732
          ]),
          center: UnitPoint(x: 0.5, y: 0.8),
          startRadius: 0,
          endRadius: max(geometry.size.width, geometry.size.height) * 0.5 // Relative to the Form's size
        )
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
