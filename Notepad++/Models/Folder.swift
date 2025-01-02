//  Folder.swift
//  Notepad++
//  Created by Michael Danylchuk on 12/31/24.
import SwiftUI

struct Folder: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: [EditorItem] // Notes in the folder
}
