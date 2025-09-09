//
//  DebugTabView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 6/19/25.
//

import SwiftUI
import OSLog

struct DebugTabView: View {

  @EnvironmentObject var appDelegate: AppKitWindowManagerDelegate
  
  var body: some View {
    Form {
      Text( "For debug use only")
      
      Button{
        appDelegate.showEditingWindow()
        
      } label: {
        Text("Show editing window")
      }
      
      Button {
        exportLogs()
      } label: {
        Text("Export Logs")
      }
    }
  }

  private func exportLogs() {
    let entries = LogStore().export()
    let prettifiedEntries = entries.joined(separator: "\n")
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(prettifiedEntries, forType: .string)
    let alert = NSAlert()
    alert.messageText = "Copied to clipboard"
    alert.runModal()
  }

}

#Preview {
  DebugTabView()
}
