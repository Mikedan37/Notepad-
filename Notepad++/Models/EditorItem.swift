//  EditorItem.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.

import Foundation

enum EditorItemType: String, Codable {
    case text
    case drawing
}

struct EditorItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var type: EditorItemType
    var content: String = "" // Used for text
    var drawing: Data? = nil // Used for drawings
}
