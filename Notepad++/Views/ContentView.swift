//
//  ContentView.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.

import SwiftUI

struct ContentView: View {
    @State private var items: [EditorItem] = [] // List of editor items
    @State private var showEditor = false // Control showing the editor
    @State private var selectedItem: EditorItem? = nil // Track the selected item

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    Button(action: {
                        selectedItem = item
                        showEditor = true
                    }) {
                        HStack {
                            if item.type == .drawing {
                                Image(systemName: "pencil.and.outline")
                            } else {
                                Image(systemName: "textformat")
                            }
                            Text(item.title)
                        }
                    }
                }
                .onDelete(perform: deleteItem)
            }
            .navigationTitle("My Notes")
            .toolbar {
                // Add new item
                Menu {
                    Button("New Drawing") {
                        addItem(type: .drawing)
                    }
                    Button("New Text") {
                        addItem(type: .text)
                    }
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showEditor) {
                if let item = selectedItem {
                    EditorView(item: $items[items.firstIndex(of: item)!])
                }
            }
        }
    }

    // Add a new item
    func addItem(type: EditorItemType) {
        let newItem = EditorItem(id: UUID(), title: "New \(type == .text ? "Text" : "Drawing")", type: type)
        items.append(newItem)
    }

    // Delete an item
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}
