//
//  Notepad__App.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.
//

import SwiftUI

@main
struct Notepad__App: App {
    @StateObject private var documentManager = DocumentManager()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(documentManager)
        }
    }
}
