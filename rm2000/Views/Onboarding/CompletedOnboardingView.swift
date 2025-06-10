//
//  CompletedOnboardingView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 6/9/25.
//

import SwiftUI

struct CompletedOnboardingView: View {
  
  @ObservedObject private var storeManager = StoreManager.shared
  
    var body: some View {
      VStack(spacing: 10) {
        
        Image(nsImage: NSApp.applicationIconImage)
          .shadow(radius: 6)
        
        Text("Purchase RM2000 Tape Recorder")
          .font(.custom("LucidaGrande-Bold", size: 24))
          .foregroundStyle(.black)
          .kerning(-1.0)
        
        HStack {
          Text("While RM2000 Tape Recorder is a paid product, you can evaluate the app with a 7-day free trial. \n\nPurchase information is located in the App Settings.")
            .font(.custom("LucidaGrande", size: 12))
            .foregroundStyle(.black)
            .frame(width: 300)
            .multilineTextAlignment(.leading)
          
          VStack(alignment: .trailing, spacing: 5) {
            
            if storeManager.isLoading {
              Text("Loading...")
                .font(.custom("LucidaGrande", size: 12))
                .foregroundStyle(Color(hex: 0xe7e9ea))
            }
            
            else if let product = storeManager.products.first {
              Text(product.displayPrice)
                .font(.custom("InstrumentSerif-Regular", size: 50))
                .foregroundStyle(.black)
              
              Text("Lifetime, Forever.\nNot a Subscription; Never Expires.")
                .font(.custom("LucidaGrande", size: 12))
                .foregroundStyle(.black)
                .multilineTextAlignment(.trailing)
            }
          }
        }
        
        Button {
          relaunch()
        } label: {
          Text("Complete Onboarding and Use Free Trial")
        }
        .controlSize(.extraLarge)
        .buttonStyle(.borderedProminent)

      }
      .frame(width: 700, height: 550)
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
            center: UnitPoint(x: 0.5, y: 0.5),
            startRadius: 0,
            endRadius: max(geometry.size.width, geometry.size.height) * 0.8
          )
          .scaleEffect(x: 2, y: 1)
        }
      )
    }
  
  private func relaunch(afterDelay seconds: TimeInterval = 0.5) -> Never {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "sleep \(seconds); open \"\(Bundle.main.bundlePath)\""]
    task.launch()
    
    NSApp.terminate(self)
    exit(0)
  }
}

#Preview {
    CompletedOnboardingView()
}
