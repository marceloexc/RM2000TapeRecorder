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
      VStack (spacing: 150) {
        VStack {
          Image(nsImage: NSApp.applicationIconImage)
            .shadow(radius: 6)
          
          if storeManager.hasPurchasedApp {
            Text(pText1 + pText2)
              .foregroundStyle(Color(.black))
              .multilineTextAlignment(.center)
              .lineSpacing(3)
              .shadow(color: Color(hex:  0x898a8b), radius: 5)
          } else {
            Text(pText0 + pText1 + pText2)
              .foregroundStyle(Color(.black))
              .multilineTextAlignment(.center)
              .lineSpacing(3)
              .shadow(color: Color(hex:  0x898a8b), radius: 5)
          }
        }
        if storeManager.hasPurchasedApp {
          ValuedCustomerView()
        } else {
          LicenseWindowShopperView()
            .environmentObject(storeManager)
        }

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

struct LicenseWindowShopperView: View {
  
  @EnvironmentObject private var storeManager: StoreManager
  
  var body: some View {
    HStack(spacing: 40) {
      VStack {
        Text("Thank you for downloading my little app! I hope you find it useful - I built RM2000 Tape Recorder in order to make my life easier. It is a native Mac application, using SwiftUI+AppKit, and has an awesome retro user interface. \n \nThere are still many features I would like to include in future versions - If you see RM2000 Tape Recorder being a handy tool during the free trial, a purchase for a lifetime license helps support future development!")
          .font(.custom("LucidaGrande", size: 12))
          .foregroundStyle(Color(hex: 0xe7e9ea))
          .shadow(color: Color(hex:  0x494a57), radius: 10)
          .frame(width: 300)
        if storeManager.hasPurchasedApp {
          Text("Thank you for Purchasing!!")
            .font(.custom("LucidaGrande", size: 16))
            .foregroundStyle(Color(hex: 0x898a8b))
            .kerning(-1)
        }
      }
      VStack(spacing: 1) {
        
        if storeManager.isLoading {
          Text("Loading...")
            .font(.custom("LucidaGrande", size: 12))
            .foregroundStyle(Color(hex: 0xe7e9ea))
        }
        
        else if let product = storeManager.products.first {
          Text(product.displayPrice)
            .font(.custom("InstrumentSerif-Regular", size: 50))
            .foregroundStyle(Color(hex: 0xe7e9ea))
            .contentTransition(.numericText())
            .animation(.easeInOut, value: product.displayPrice)
          
          Text("Lifetime, Forever")
            .font(.custom("LucidaGrande", size: 12))
            .foregroundStyle(Color(hex: 0xe7e9ea))
          
          Button {
            Task { await storeManager.purchaseAppLicenseThankYouSoMuch() }
          } label: {
            Text("Buy now")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.extraLarge)
        }
        else {
          Text("Error loading products from the store...")
        }
      }
    }
  }
}

struct ValuedCustomerView: View {
  var body: some View {
    Text("Lifetime License Activated")
      .font(.custom("InstrumentSerif-Regular", size: 50))
      .foregroundStyle(Color(hex: 0xe7e9ea))

    
    Text("Thank you!")
      .font(.custom("LucidaGrande", size: 12))
      .foregroundStyle(Color(hex: 0xe7e9ea))
  }
}

#Preview ("License Tab"){
    LicenseTabView()
}
#Preview("Settings view") {
  SettingsView()
    .environmentObject(AppState.shared)

}
