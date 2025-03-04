//
//  DebugView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 3/4/25.
//

import SwiftUI

struct DebugView: View {
	@EnvironmentObject var appState: AppState
	@EnvironmentObject private var sampleStorage: SampleStorage
	
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
		Text("Current saving directory: \(String(describing: appState.sampleDirectory)) with count of \(SampleStorage.shared.UserDirectory.files.count)")
    }
}

#Preview {
    DebugView()
}
