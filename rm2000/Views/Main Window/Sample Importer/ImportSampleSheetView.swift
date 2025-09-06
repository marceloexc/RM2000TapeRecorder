//
//  ImportSampleSheetView.swift
//  rm2000
//
//  Created by Marcelo Mendez on 9/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportSampleSheetView: View {
  @State private var isBeingDragged: Bool = false
  
  weak var appDelegate: AppKitWindowManagerDelegate?

  
  var body: some View {
      ZStack {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(.primary, style: StrokeStyle(lineWidth: 2, dash: [5]))
          .fill(Color(nsColor: .tertiarySystemFill))
        
        Text("Drop media files here")
      }
      .frame(minHeight: 300)
      .padding()
      .onDrop(of: [.fileURL], isTargeted: $isBeingDragged) { providers in
        
        for provider in providers {
          provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
            if let data = item as? Data {
              let url = URL(dataRepresentation: data, relativeTo: nil)
              print("dropped file url: \(url!)")
              NSWorkspace.shared.open(url!)

            }
          }
        }
        return true
      }
    }
}

#Preview {
    ImportSampleSheetView()
}
