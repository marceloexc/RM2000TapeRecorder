import OSLog
import SwiftUI

struct PathControlView: NSViewRepresentable {
  @Binding var selectedPath: URL?
  let sampleDirectoryURL: URL

  init(selectedPath: Binding<URL?> = .constant(nil), sampleDirectoryURL: URL) {
    self._selectedPath = selectedPath
    self.sampleDirectoryURL = sampleDirectoryURL
  }

  func makeNSView(context: Context) -> NSPathControl {
    let pathControl = NSPathControl()
    pathControl.pathStyle = .standard
    pathControl.target = context.coordinator
    pathControl.action = #selector(Coordinator.pathChanged(_:))
    pathControl.backgroundColor = .clear

    let url: URL = self.sampleDirectoryURL
    pathControl.url = url

    return pathControl
  }

  func updateNSView(_ nsView: NSPathControl, context: Context) {
    if let selectedPath = selectedPath {
      nsView.url = selectedPath
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject {
    let parent: PathControlView

    init(_ parent: PathControlView) {
      self.parent = parent
    }

    @objc func pathChanged(_ sender: NSPathControl) {
      parent.selectedPath = sender.url
    }
  }
}

struct SettingsOnboardingView: View {
  @EnvironmentObject var appState: AppState
  @State private var mousePosition: CGPoint = .zero
  @State private var iconCenter: CGPoint = .zero
  @State private var showFileChooser = false
  
  var body: some View {
    VStack(spacing: 40) {
      VStack {
        Image("HappyFolder")
          .resizable()
          .scaledToFit()
          .frame(width: 200, height: 200)
          .background(
            GeometryReader { geometry in
              // todo - why does this .clear need to be here?
              Color.clear
                .onAppear {
                  let frame = geometry.frame(in: .global)
                  iconCenter = CGPoint(
                    x: frame.midX,
                    y: frame.midY
                  )
                }
                .onChange(of: geometry.frame(in: .global)) { newFrame in
                  iconCenter = CGPoint(
                    x: newFrame.midX,
                    y: newFrame.midY
                  )
                }
            }
          )
          .rotation3DEffect(
            .degrees(calculateRotation().x),
            axis: (x: 1, y: 0, z: 0)
          )
          .rotation3DEffect(
            .degrees(calculateRotation().y),
            axis: (x: 0, y: 1, z: 0)
          )
          .animation(.easeOut(duration: 0.05), value: mousePosition)

        Text("Where Should Your Samples Go?")
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
      }

      VStack {
        HStack(alignment: .center, spacing: 5) {
          PathControlView(
            sampleDirectoryURL: AppState.shared.sampleDirectory
              ?? FileManager.default.urls(
                for: .musicDirectory, in: .userDomainMask
              ).first!.appendingPathComponent("RM2000 Tape Recorder")
          )
          .frame(height: 30)
          .background(
            LinearGradient(
              stops: [
                .init(color: Color(hex: 0xdfdfdf), location: 0),
                .init(color: Color(hex: 0xc0c0c0), location: 1),
              ], startPoint: .bottom, endPoint: .top)
          )
          .cornerRadius(6)

          Spacer()

          Button {
            showFileChooser = true
          } label: {
            Text("Choose Different Folder")
          }
          .controlSize(.large)
          .fileImporter(
            isPresented: $showFileChooser, allowedContentTypes: [.directory]
          ) { result in
            switch result {
            case .success(let directory):
              // get security scoped bookmark
              guard directory.startAccessingSecurityScopedResource() else {
                Logger.appState.error(
                  "Could not get security scoped to the directory \(directory)")
                return
              }
              appState.sampleDirectory = directory
              Logger.viewModels.info("Set new sampleDirectory as \(directory)")
            case .failure(let error):
              Logger.viewModels.error("Could not set sampleDirectory: \(error)")

            }
          }
        }

        Text("The Default Folder Location is ~/Music/RM2000 Tape Recorder/")
          .font(.custom("LucidaGrande", size: 12))
          .foregroundStyle(Color(.white))
      }
      .frame(width: 600)
    }
    .frame(width: 700, height: 550)
    .background(Color(hex: 0x00010f))
    .onContinuousHover(coordinateSpace: .global) { phase in
      switch phase {
      case .active(let location):
        mousePosition = location
      case .ended:
        // reset to center
        break
      }
    }
  }

  private func calculateRotation() -> (x: Double, y: Double) {
    // difference between mouse position and icon center
    let deltaX = mousePosition.x - iconCenter.x
    let deltaY = mousePosition.y - iconCenter.y

    let maxRotation: Double = 30.0  // maximum rotation angle in degrees
    let sensitivity: Double = 200.0  // distance for maximum rotation

    let yRotation = min(
      max(deltaX / sensitivity * maxRotation, -maxRotation), maxRotation)
    let xRotation = -min(
      max(deltaY / sensitivity * maxRotation, -maxRotation), maxRotation)

    return (x: xRotation, y: yRotation)
  }
}

#Preview {
  SettingsOnboardingView()
}
