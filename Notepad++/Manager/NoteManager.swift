//
//  NoteManager.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/29/24.
//

import SwiftUI

class NoteManager: ObservableObject {
    @Published var items: [EditorItem] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("notes.json")
    }

    init() {
        loadItems()
        addLifecycleObservers()
    }

    deinit {
        removeLifecycleObservers()
    }

    func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL)
            print("Items saved successfully.")
        } catch {
            print("Failed to save items: \(error.localizedDescription)")
        }
    }

    func loadItems() {
        do {
            let data = try Data(contentsOf: fileURL)
            items = try JSONDecoder().decode([EditorItem].self, from: data)
            print("Items loaded successfully.")
        } catch {
            print("Failed to load items: \(error.localizedDescription)")
        }
    }

    private func addLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveItemsOnBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveItemsOnBackground),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    private func removeLifecycleObservers() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc private func saveItemsOnBackground() {
        saveItems()
    }
}
