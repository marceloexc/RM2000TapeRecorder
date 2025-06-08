import SwiftUI

struct GettingStartedOnboardingView: View {
  var body: some View {
    VStack(spacing: 32) {
      Text("Getting Started is Easy")
        .font(.custom("InstrumentSerif-Regular", size: 50))
        .kerning(-2.0)
        .foregroundStyle(
          LinearGradient(
            stops: [
              .init(color: Color(hex: 0xdfdfdf), location: 0),
              .init(color: Color(hex: 0xdfdfdf), location: 1),
            ], startPoint: .bottom, endPoint: .top)
        )
        .shadow(color: .black, radius: 1, y: 1)

      VStack(spacing: 20) {
        StepView {
          HStack(alignment: .top, spacing: 16) {
            ActiveRecordButtonDecor()

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
            Text("2")
              .font(.custom("LucidaGrande-Bold", size: 20))
              .frame(width: 36, height: 36)
              .background(Color(hex: 0xE7E9EA))
              .foregroundColor(.black)
              .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
              Text("2. Organize Effortlessly")
                .font(.custom("LucidaGrande-Bold", size: 18))
                .foregroundStyle(Color(hex: 0xE7E9EA))

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
            Text("3")
              .font(.custom("LucidaGrande-Bold", size: 20))
              .frame(width: 36, height: 36)
              .background(Color(hex: 0xE7E9EA))
              .foregroundColor(.black)
              .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
              Text("3. Use Them Anywhere")
                .font(.custom("LucidaGrande-Bold", size: 18))
                .foregroundStyle(Color(hex: 0xE7E9EA))

              Text("Drop them into your DAW, or preview them on the fly.")
                .font(.custom("LucidaGrande", size: 14))
                .foregroundStyle(Color(hex: 0xB0B2B3))
            }
          }
        }
      }
    }
    .padding()
    .frame(width: 600, height: 500)
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
      .frame(minHeight: 90)

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
