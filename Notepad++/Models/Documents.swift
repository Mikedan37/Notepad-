//  Docuents.swift
//  Notepad++
//  Created by Michael Danylchuk on 12/11/24.
import Foundation

struct Document: Identifiable{
    let id = UUID()
    var name: String
    var content: String
}
