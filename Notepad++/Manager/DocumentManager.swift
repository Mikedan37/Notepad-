//  DocumentManager.swift
//  Notepad++
//  Created by Michael Danylchuk on 12/11/24.

import Foundation

class DocumentManager: ObservableObject {
    @Published var documents: [Document] = []

    func addDocument(named name: String) {
        documents.append(Document(name: name, content: ""))
    }

    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
    }
}
