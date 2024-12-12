//
//  ContentView.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.
import SwiftUI

struct ContentView: View {
    @State private var items: [EditorItem] = []
    @State private var showEditor = false
    @State private var selectedItem: EditorItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray.opacity(0.2) // Background for entire view
                    .ignoresSafeArea()
                
                List {
                    ForEach($items) { $item in
                        NavigationLink(
                            destination: EditorView(item: $item)
                        ) {
                            HStack {
                                Image(systemName: item.type.systemImage)
                                Text(item.title)
                            }
                        }
                    }
                }
                //.scrollContentBackground(.hidden) // Remove list background
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("New Drawing") {
                            addItem(type: .drawing)
                        }
                        Button("New Text") {
                            addItem(type: .text)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                    }
                }
            }
            .navigationTitle("My Notes")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                configureNavigationBarAppearance()
            }
        }
        .accentColor(.white)
    }

    func addItem(type: EditorItemType) {
        let newItem = EditorItem(
            id: UUID(),
            title: "New \(type == .text ? "Text" : "Drawing")",
            type: type,
            content: type == .text ? "" : "",
            drawing: nil
        )
        items.append(newItem)
    }

    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    /// Configure the navigation bar appearance
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        
        // Set the background color for the navigation bar
        appearance.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.6)
        
        // Customize title attributes
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        
        // Customize large title attributes (optional)
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 32)
        ]
        
        // Apply the appearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

#Preview{
    ContentView()
}
