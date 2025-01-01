//
//  NoteManager.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/29/24.
//

import SwiftUI

class NoteManager: ObservableObject {
    @Published var items: [EditorItem] = [] // Regular Notes
    @Published var pinnedItems: [EditorItem] = [] // Pinned Notes
    private var saveWorkItem: DispatchWorkItem?
    
    private var regularFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("notes.json")
    }
    
    private var pinnedFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("pinnedNotes.json")
    }
    
    init() {
        loadItems()
        addLifecycleObservers()
    }
    
    deinit {
        removeLifecycleObservers()
    }
    
    func saveItems() {
        DispatchQueue.global(qos: .background).async {
               do {
                   let regularData = try JSONEncoder().encode(self.items)
                   let pinnedData = try JSONEncoder().encode(self.pinnedItems)
                   
                   try regularData.write(to: self.regularFileURL)
                   try pinnedData.write(to: self.pinnedFileURL)
               } catch {
                   print("Failed to save items: \(error.localizedDescription)")
               }
           }
    }


    func loadItems() {
        DispatchQueue.global(qos: .background).async {
               do {
                   // Load regular items
                   if let regularData = try? Data(contentsOf: self.regularFileURL) {
                       let decodedRegularItems = try JSONDecoder().decode([EditorItem].self, from: regularData)
                       DispatchQueue.main.async {
                           self.items = decodedRegularItems
                       }
                   }

                   // Load pinned items
                   if let pinnedData = try? Data(contentsOf: self.pinnedFileURL) {
                       let decodedPinnedItems = try JSONDecoder().decode([EditorItem].self, from: pinnedData)
                       DispatchQueue.main.async {
                           self.pinnedItems = decodedPinnedItems
                       }
                   }

                   print("Items loaded successfully.")
               } catch {
                   DispatchQueue.main.async {
                       print("Failed to load items: \(error.localizedDescription)")
                       self.items = []
                       self.pinnedItems = []
                   }
               }
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
