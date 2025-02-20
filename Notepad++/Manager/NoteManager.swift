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
    @Published var folders: [Folder] = [] // Stores folders with their notes
    
    private var saveWorkItem: DispatchWorkItem?
    
//    private var folderFileURL: URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("folders.json")
//    }
    
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
        saveItems()
        removeLifecycleObservers()
    }
    
    func saveItems() {
        DispatchQueue.global(qos: .background).async {
            do {
                let regularData = try JSONEncoder().encode(self.items)
                print("✅ Successfully encoded regular items.")

                let pinnedData = try JSONEncoder().encode(self.pinnedItems)
                print("✅ Successfully encoded pinned items.")

//                let folderData = try JSONEncoder().encode(self.folders)
//                print("✅ Successfully encoded folders.")

                try self.ensureDirectoryExists()

                try regularData.write(to: self.regularFileURL, options: .atomic)
                print("📁 Successfully wrote regular notes.")

                try pinnedData.write(to: self.pinnedFileURL, options: .atomic)
                print("📁 Successfully wrote pinned notes.")

//                try folderData.write(to: self.folderFileURL, options: .atomic)
//                print("📁 Successfully wrote folders.")

            } catch {
                print("❌ Failed to save items: \(error.localizedDescription)")
            }
        }
    }

    private func ensureDirectoryExists() {
        let directory = self.regularFileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                print("📂 Directory created successfully.")
            } catch {
                print("❌ Failed to create directory: \(error.localizedDescription)")
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
                           print("Regular Item loaded")
                       }
                   }

                   // Load pinned items
                   if let pinnedData = try? Data(contentsOf: self.pinnedFileURL) {
                       let decodedPinnedItems = try JSONDecoder().decode([EditorItem].self, from: pinnedData)
                       DispatchQueue.main.async {
                           self.pinnedItems = decodedPinnedItems
                           print("Pinned Item loaded")
                       }
                   }
                   
//                   if let folderData = try? Data(contentsOf: self.folderFileURL) {
//                                 let decodedFolders = try JSONDecoder().decode([Folder].self, from: folderData)
//                                 DispatchQueue.main.async {
//                                     self.folders = decodedFolders
//                                     print("Folder Item loaded")
//                                 }
//                             }
                   
                   DispatchQueue.main.async{
                       print("Items loaded successfully.")
                   }
                   
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
