//  EditorItem.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.

import Foundation

struct EditorItem: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var type: EditorItemType
    var content: String // Holds text for text items
    var drawing: Data? // Holds serialized drawing data for drawing items
    var isPinned: Bool = false
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
