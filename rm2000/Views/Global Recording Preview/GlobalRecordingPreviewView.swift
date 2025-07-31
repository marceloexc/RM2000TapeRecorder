import FluidGradient
import SwiftUI

struct GlobalRecordingPreviewView: View {
  @EnvironmentObject private var recordingState: TapeRecorderState
  @State private var opacity: Double = 0.0
  @State private var isAnimating = true
  @State private var showHintText = false

  var body: some View {
    ZStack {

      FluidGradient(
        blobs: [Color(hex: 0xCA7337), Color(hex: 0xd9895d)],
        highlights: [.gray],
        speed: 1.0,
        blur: 0.70)

      VStack {
        HStack(spacing: 90) {

          if recordingState.status == .recording {
            LCDTextBigWithGradientHUD(
              timeString(recordingState.elapsedTimeRecording)
            )
            .frame(maxWidth: 150, alignment: .leading)
            .foregroundColor(Color("LCDTextColor"))
          } else {
            LCDTextBigWithGradientHUD("STBY")
              .frame(maxWidth: 150, alignment: .leading)
              .foregroundColor(Color("LCDTextColor"))
          }
            
          VUMeter()
            .mask(
              LinearGradient(
                colors: [
                  Color(hex: 0x220300, alpha: 0.02),
                  Color(hex: 0x220300),
                ],
                startPoint: .bottom,
                endPoint: .top
              )
            )
            .colorEffect(
              Shader(
                function: .init(library: .default, name: "dotMatrix"),
                arguments: [])
            )
            .shadow(color: .black.opacity(0.35), radius: 1, x: 2, y: 4)

            .frame(width: 60, height: 135)
            .padding(.leading, -20)
        }
        Group {
          if showHintText {
            Text("(Press ⌘ + ⌥ + G to stop recording)")
              .transition(.blurReplace)
          }
        }
        .font(Font.tasaFont)
        .foregroundStyle(Color("LCDTextColor"))
        .animation(.easeInOut, value: showHintText)
      }
    }
    .frame(width: 400, height: 250)
    .opacity(opacity)
    .onAppear {
      withAnimation(.easeIn(duration: 0.3)) { opacity = 1.0 }
      DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        withAnimation {
          showHintText = true
        }
      }
      // make sure Dock Icon is not hidden
      NSApp.setActivationPolicy(.regular)
    }
    .onDisappear {
      withAnimation(.easeIn(duration: 0.3)) { opacity = 0.0 }
    }
  }
}

#Preview {
  GlobalRecordingPreviewView()
    .environmentObject(TapeRecorderState())
}
