import OSLog
import SwiftUI
import UserNotifications

enum OnboardingStep: CaseIterable {
  case welcome
  case gettingstarted
  case settings
  case req_permission
  case complete

  static let fullOnboarding = OnboardingStep.allCases

  var shouldShowNextButton: Bool {
    switch self {
    case .welcome, .settings, .gettingstarted, .req_permission:
      return true
    default:
      return false
    }
  }
  
  var shouldShowPreviousButton: Bool {
    switch self {
    case .gettingstarted, .settings, .complete, .req_permission:
      return true
    default:
      return false
    }
  }

  @ViewBuilder
  func view() -> some View {
    switch self {
    case .welcome:
      WelcomeOnboardingView()
    case .gettingstarted:
      GettingStartedOnboardingView()
    case .settings:
      SettingsOnboardingView()
    case .complete:
      CompletedOnboardingView()
    case .req_permission:
      RequestPermissionOnboardingView()
    }
  }
}

struct OnboardingView: View {
  @EnvironmentObject var appState: AppState
  @State private var currentPage: OnboardingStep = .welcome
  @State private var transitionDirection: AnimationDirection = .forward
  private let pages: [OnboardingStep]
  
  enum AnimationDirection {
    case forward
    case backward
  }

  init(pages: [OnboardingStep]) {
    self.pages = pages
  }
  var body: some View {
    ZStack(alignment: .bottom) {
      currentPage.view()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        .id(currentPage)
        .transition(transition)
        .animation(.smooth(duration: 0.3), value: currentPage)
      
      HStack {
        if currentPage.shouldShowPreviousButton {
          Button(action: showPreviousPage) {
            Text("Previous")
          }
        }
        
        Spacer()
        
        if currentPage.shouldShowNextButton {
          Button(action: showNextPage) {
            Text("Next")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.extraLarge)
          }
      }      .padding()
        
      }
    .background(Color(hex: 0x00010f))
    .frame(width: 700, height: 550.0)
    .edgesIgnoringSafeArea(.bottom)
  }
  
  private var transition: AnyTransition {
    switch transitionDirection {
    case .forward:
      return AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
      )
    case .backward:
      return AnyTransition.asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .trailing)
      )
    }
  }

  private func showNextPage() {
    guard let currentIndex = pages.firstIndex(of: currentPage),
      pages.count > currentIndex + 1
    else {
      return
    }
    transitionDirection = .forward
    currentPage = pages[currentIndex + 1]
  }
  
  private func showPreviousPage() {
    guard let currentIndex = pages.firstIndex(of: currentPage),
          currentIndex > 0
    else {
      return
    }
    transitionDirection = .backward
    currentPage = pages[currentIndex - 1]
  }
}

#Preview {
  OnboardingView(pages: OnboardingStep.fullOnboarding)
    .environmentObject(AppState.shared)  // Ensure AppState is injected
}
