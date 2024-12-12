//  SidebarView.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.
import SwiftUICore
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var documentManager: DocumentManager
    var body: some View {
        List {
//            ForEach(documentManager.documents) { document in
//                Text(document.name)
//            }.environmentObject(documentManager)
//            .onDelete { indexSet in
//                indexSet.forEach { documentManager.deleteDocument(documentManager.documents[$0]) }
//            }
            Text("Hello World!")
        }
        .navigationTitle("Documents")
        .toolbar {
            Button(action: {
                documentManager.addDocument(named: "New Document")
            }) {
                Image(systemName: "plus")
            }
        }
    }
}
