//  EditorItem.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.

import Foundation
import PencilKit // ✅ Required for PKDrawing

struct EditorItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var type: EditorItemType
    var content: String // Holds text for text items
    var isPinned: Bool = false
    var paperType: PaperType? = .plain
    var pages: [PageModel] // ✅ Store unique pages per note
    
    // ✅ Fix: Remove duplicate `drawing` property and correctly encode/decode PKDrawing
    var drawingData: Data? // Holds serialized drawing data
    
    var drawing: PKDrawing {
        get { (try? PKDrawing(data: drawingData ?? Data())) ?? PKDrawing() }
        set { drawingData = newValue.dataRepresentation() }
    }

    // ✅ Custom Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id, title, type, content, isPinned, paperType, pages, drawingData
    }
}

enum EditorItemType: String, Codable {
    case drawing
    case text

    var systemImage: String {
        switch self {
        case .drawing: return "pencil.and.outline"
        case .text: return "textformat"
        }
    }
}
