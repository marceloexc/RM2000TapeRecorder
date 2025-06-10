import SwiftUI

struct GettingStartedOnboardingView: View {
  
  // TODO - this shit is not aligned properly - when i have time to fix it i will!
  
  var body: some View {
    VStack(spacing: 32) {
      Text("Getting Started is Easy")
        .font(.custom("InstrumentSerif-Regular", size: 50))
        .kerning(-2.0)
        .foregroundStyle(
          LinearGradient(
            stops: [
              .init(color: Color(hex: 0xdfdfdf), location: 0),
              .init(color: Color(hex: 0xc0c0c0), location: 1),
            ], startPoint: .bottom, endPoint: .top)
        )
        .shadow(color: .black, radius: 1, y: 1)

      VStack(spacing: 20) {
        StepView {
          HStack(alignment: .top, spacing: 16) {
            ActiveRecordButtonDecor()

            Spacer()
            VStack(alignment: .leading, spacing: 4) {
              Text("1. Record Your Samples")
                .font(.custom("LucidaGrande-Bold", size: 18))
                .foregroundStyle(Color(hex: 0xcccccc))

              Text("Use the built-in recorder to capture any sound you like.")
                .font(.custom("LucidaGrande", size: 14))
                .foregroundStyle(Color(hex: 0xB0B2B3))
            }
          }
        }

        StepView {
          HStack(alignment: .top, spacing: 16) {
            
            Image(systemName: "tag.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 50)
              .padding()
              .foregroundStyle(
                LinearGradient(
                  stops: [
                    .init(color: Color(hex: 0xdfdfdf), location: 0),
                    .init(color: Color(hex: 0xc0c0c0), location: 1),
                  ], startPoint: .bottom, endPoint: .top)
              )
              

            
            Spacer()

            VStack(alignment: .leading, spacing: 4) {
              Text("2. Organize Effortlessly")
                .font(.custom("LucidaGrande-Bold", size: 18))
                .foregroundStyle(Color(hex: 0xcccccc))

              Text(
                "Tag, rename, and categorize your recordings for easy access."
              )
              .font(.custom("LucidaGrande", size: 14))
              .foregroundStyle(Color(hex: 0xB0B2B3))
            }
          }
        }

        StepView {
          HStack(alignment: .top, spacing: 16) {
            Image("FolderButton")
              .renderingMode(.original)
              .resizable()
              .scaledToFit()
              .frame(width: 120)
            
            Spacer()

            VStack(alignment: .leading, spacing: 4) {
              Text("3. Use Them Anywhere")
                .font(.custom("LucidaGrande-Bold", size: 18))
                .foregroundStyle(Color(hex: 0xcccccc))

              Text("Drop them into your DAW, or sort through them through the Sample Library Window")
                .font(.custom("LucidaGrande", size: 14))
                .foregroundStyle(Color(hex: 0xB0B2B3))
            }
          }
        }
      }
    }
    .padding()
    .frame(width: 700, height: 550)
    .background(
      RadialGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: 0x474247), location: 0.04),
          .init(color: Color(hex: 0x00010f), location: 0.65),
        ]),
        center: .center,
        startRadius: 0,
        endRadius: 400
      )
    )
  }
}

struct StepView<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding()
      .frame(maxWidth: 550, minHeight: 90)

      .background(
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(
            LinearGradient(
              gradient: Gradient(colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.04),
              ]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1.2
          )
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.white.opacity(0.02))
          )
      )
  }
}

struct ActiveRecordButtonDecor: View {
  var body: some View {
    ZStack {
      Image("RecordButtonActiveTemp")
      Image("RecordButtonTemp")
        .pulseEffect()
      Image("RecordButtonGlow")
        .resizable()
        .frame(width: 100, height: 200)
        .brightness(0.2)

        .pulseEffect()
    }
    .frame(height: 80)
  }
}

#Preview {
  GettingStartedOnboardingView()
}
