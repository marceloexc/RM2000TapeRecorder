import AppKit
import FluidGradient
import SwiftUI

class FloatingWindow: NSWindow {
  init(contentRect: NSRect, backing: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false) {
    super.init( contentRect: contentRect, styleMask: [.titled], backing: backing, defer: flag)

    // Window configuration
    self.isOpaque = false
    self.backgroundColor = .clear
    self.level = .floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    self.hasShadow = true
    self.title = "Recording..."
    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = true

    // Create the visual effect view for blurred edges
    let visualEffectView = NSVisualEffectView(frame: contentRect)
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.material = .fullScreenUI
    visualEffectView.state = .active
    visualEffectView.wantsLayer = true
    //		visualEffectView.layer?.opacity = 0.8
    visualEffectView.layer?.masksToBounds = true

    visualEffectView.maskImage = maskImage(cornerRadius: 20.0)

    // This is the key part - create a mask that makes the center transparent
    let maskLayer = CALayer()
    maskLayer.frame = visualEffectView.bounds
    maskLayer.backgroundColor = NSColor.black.cgColor

    // Create a hole in the center
    let centerRect = NSRect(
      x: contentRect.width * 0.1,
      y: contentRect.height * 0.1,
      width: contentRect.width * 1,
      height: contentRect.height * 1
    )

    let path = CGMutablePath()
    path.addRect(visualEffectView.bounds)
    path.addRoundedRect(
      in: centerRect,
      cornerWidth: 10,
      cornerHeight: 10
    )

    let maskShapeLayer = CAShapeLayer()
    maskShapeLayer.path = path
    maskShapeLayer.fillRule = .evenOdd

    maskLayer.mask = maskShapeLayer
    visualEffectView.layer?.mask = maskLayer

    self.contentView = visualEffectView
  }

  override var canBecomeKey: Bool {
    return true
  }

  // https://eon.codes/blog/2016/01/23/Chromeless-window/
  private func maskImage(cornerRadius: CGFloat) -> NSImage {
    let edgeLength = 2.0 * cornerRadius + 1.0
    let maskImage = NSImage(
      size: NSSize(width: edgeLength, height: edgeLength), flipped: false
    ) { rect in
      let bezierPath = NSBezierPath(
        roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
      NSColor.black.set()
      bezierPath.fill()
      return true
    }
    maskImage.capInsets = NSEdgeInsets(
      top: cornerRadius, left: cornerRadius, bottom: cornerRadius,
      right: cornerRadius)
    maskImage.resizingMode = .stretch
    return maskImage
  }
}

struct FloatingGradientView: View {
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
          } else {
            LCDTextBigWithGradientHUD("STBY")
              .frame(maxWidth: 150, alignment: .leading)
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
            LCDTextCaptionWithGradient("Press ⌘ + ⌥ + G to stop recording")
              .transition(.blurReplace)
          }
        }
        .font(Font.tasaFont)
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
  FloatingGradientView()
    .environmentObject(TapeRecorderState())
}
