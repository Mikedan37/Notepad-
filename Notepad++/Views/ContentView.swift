import SwiftUI

struct ContentView: View {
    @StateObject private var noteManager = NoteManager()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gray.opacity(0.2) // Background for entire view
                    .ignoresSafeArea()
                
                List {
                    ForEach(noteManager.items) { item in
                        NavigationLink(
                            destination: EditorView(item: Binding(
                                get: { item },
                                set: { updatedItem in
                                    if let index = noteManager.items.firstIndex(where: { $0.id == updatedItem.id }) {
                                        noteManager.items[index] = updatedItem
                                    }
                                }
                            ))
                        ) {
                            HStack {
                                Image(systemName: item.type.systemImage)
                                Text(item.title)
                            }
                        }
                    }
                    .onDelete(perform: deleteItem) // Fixed `.onDelete`
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            addItem(type: .drawing)
                        }) {
                            HStack {
                                Text("New Drawing")
                                Image(systemName: "pencil.and.scribble")
                            }
                        }
                        Button(action: {
                            addItem(type: .text)
                        }) {
                            HStack {
                                Text("New Text")
                                Image(systemName: "textformat.alt")
                            }
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
        noteManager.items.append(newItem)
        noteManager.saveItems() // Save immediately after adding
    }

    func deleteItem(at offsets: IndexSet) {
        noteManager.items.remove(atOffsets: offsets)
        noteManager.saveItems() // Save changes immediately after deleting
    }
    
    /// Configure the navigation bar appearance
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        
        // Set the background color for the navigation bar
        appearance.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.7)
        
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
