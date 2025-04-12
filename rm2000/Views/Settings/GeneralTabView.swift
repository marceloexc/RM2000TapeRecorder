import SwiftUI
import OSLog

struct GeneralTabView: View {

	
	var body: some View {
		Form {
			Section {
				//				Toggle("Start at Login", isOn: $autostartAtLogin)
				//					.onChange(of: autostartAtLogin) { newValue in
				//						autoStartAtLogin()
				//					}
				//				Toggle("Minimize to Toolbar", isOn: $minimizeToToolbar)
				//					.disabled(!autostartAtLogin)
			}
			
			Section {
				Toggle("Show File Extensions", isOn: .constant(true))
				Toggle("Keep unsaved samples", isOn: .constant(true))
			}
		}
	}
}

#Preview {
	SettingsView()
		.environmentObject(AppState.shared)
}
