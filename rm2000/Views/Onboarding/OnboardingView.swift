import OSLog
import SwiftUI
import UserNotifications

enum OnboardingStep: CaseIterable {
  case welcome
  case gettingstarted
  case settings
  case complete

  static let fullOnboarding = OnboardingStep.allCases

  var shouldShowNextButton: Bool {
    switch self {
    case .welcome, .settings, .gettingstarted:
      return true
    default:
      return false
    }
  }

  @ViewBuilder
  func view(action: @escaping () -> Void) -> some View {
    switch self {
    case .welcome:
      WelcomeOnboardingView()
    case .gettingstarted:
      GettingStartedOnboardingView()
    case .settings:
      SettingsOnboardingView()
    case .complete:
      Text("Complete")
    }
  }
}

class OnboardingViewModel: ObservableObject {
  @Published var currentStep: OnboardingStep = .welcome
}

struct FinalOnboardingCompleteView: View {
  @Environment(\.dismiss) var dismiss
  @ObservedObject var viewModel: OnboardingViewModel
  @EnvironmentObject var appState: AppState

  var body: some View {
    Text("Complete!")

    Text("App will now close. Please restart")
    HStack {
      Button("Back") {
        viewModel.currentStep = .settings
      }

      Button("Finish") {
        appState.hasCompletedOnboarding = true
        /*
						 this has to be appkit compatible as the mainwindow uses
						 an appkit based lifetime
						 */
        print("closing")
        exit(0)
      }
      .buttonStyle(.borderedProminent)
    }
  }
}

struct SettingsStepView: View {

  private let streamManager = SCStreamManager()

  @ObservedObject var viewModel: OnboardingViewModel
  @EnvironmentObject var appState: AppState

  @State private var showFileChooser: Bool = false

  var body: some View {
    Text("Set directory for all samples to get saved in")
    HStack {
      TextField(
        "Set RM2000 Sample Directory",
        text: Binding(
          get: { appState.sampleDirectory?.path ?? "" },
          set: { appState.sampleDirectory = URL(fileURLWithPath: $0) }
        ))
      Button("Browse") {
        showFileChooser = true
      }
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
    HStack {
      Button("Back") {
        viewModel.currentStep = .welcome
      }

      Button("Next") {
        viewModel.currentStep = .complete
        print(appState.sampleDirectory?.path ?? "No directory set")
      }
      .buttonStyle(.borderedProminent)
    }
  }

  private func invokeRecordingPermission() async {
    do {
      try await streamManager.setupAudioStream()
    } catch {
      Logger.viewModels.error("Recording permission declined")

      // https://stackoverflow.com/a/78740238
      // i seriously have to use NSAlert for this?

      let alert = showPermissionAlert()
      if alert.runModal() == .alertFirstButtonReturn {
        NSWorkspace.shared.open(
          URL(
            string:
              "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
          )!)
      }
    }
  }

  private func showPermissionAlert() -> NSAlert {
    let alert = NSAlert()
    alert.messageText = "Permission Request"
    alert.alertStyle = .informational
    alert.informativeText =
      "RM2000 requires permission to record the screen in order to grab system audio."
    alert.addButton(withTitle: "Open System Settings")
    alert.addButton(withTitle: "Quit")
    return alert
  }
}

struct WelcomeView: View {

  @ObservedObject var viewModel: OnboardingViewModel
  var body: some View {
    VStack {
      Image(nsImage: NSApp.applicationIconImage)
      Text("Welcome to RM2000")
        .font(.title)
    }
    Text("This build is considered ")
      + Text("incredibly fragile")
      .foregroundColor(.red)

    Text("Consider all the samples you record with this app as ephemeral")

    Text("More stable builds will follow in the next weeks")
    HStack {
      Button("Next") {
        viewModel.currentStep = .settings
      }
      .buttonStyle(.borderedProminent)
    }
  }
}

struct OnboardingView: View {
  @EnvironmentObject var appState: AppState
  @State private var currentPage: OnboardingStep = .welcome
  private let pages: [OnboardingStep]

  init(pages: [OnboardingStep]) {
    self.pages = pages
  }
  var body: some View {
    ZStack(alignment: .bottom) {
      //      Color(hex: 0x00010f)
      //        .ignoresSafeArea(.all)

      ForEach(pages, id: \.self) { page in
        if page == currentPage {
          page.view(action: showNextPage)
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(
              AnyTransition.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading))
            )
            .animation(.snappy)
        }
      }

      if currentPage.shouldShowNextButton {
        HStack {
          Spacer()
          Button(action: showNextPage) {
            Text("Next")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.extraLarge)
        }
        .padding()
      }
    }
    .background(Color(.gray))
    .frame(width: 600, height: 500.0)
    .edgesIgnoringSafeArea(.bottom)
  }

  private func showNextPage() {
    guard let currentIndex = pages.firstIndex(of: currentPage),
      pages.count > currentIndex + 1
    else {
      return
    }
    currentPage = pages[currentIndex + 1]
  }
}

#Preview {
  OnboardingView(pages: OnboardingStep.fullOnboarding)
    .environmentObject(AppState.shared)  // Ensure AppState is injected
}
