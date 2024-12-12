//
//  Notepad__App.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.
//

import SwiftUI

@main
struct NotepadApp: App { // Remove the double underscore for cleaner naming
    @StateObject private var documentManager = DocumentManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(documentManager) // Properly attach the environment object
        }
    }
}
