import SwiftUI

struct ContentView: View {
    @StateObject private var noteManager = NoteManager()
    @State private var renamingItem: EditorItem? // Tracks renamed item
    @State private var isRenameAlertPresented = false // Controls the alert visibility
    @State private var isDragging: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.2) // Background for entire view
                    .ignoresSafeArea()
                VStack{
                    if !noteManager.items.filter({ $0.isPinned }).isEmpty || isDragging {
                        // Display pinned items
                        VStack {
                            // Pinned notes UI
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(noteManager.items.filter({ $0.isPinned })) { item in
                                        VStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.8))
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    Text(item.title.prefix(1))
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                )
                                            Text(item.title)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }.padding([.bottom,.top],5).padding(.top,10)
                        }
                    }
                    List {
                        ForEach(noteManager.items) { item in
                            NavigationLink(
                                destination: EditorView(item: Binding(
                                    get: { item },
                                    set: { updatedItem in
                                        DispatchQueue.main.async {
                                            if let index = noteManager.items.firstIndex(where: { $0.id == updatedItem.id }) {
                                                noteManager.items[index] = updatedItem
                                            }
                                        }
                                    }
                                ))
                            ) {
                                HStack {
                                    Image(systemName: item.type.systemImage ?? "exclamationmark.triangle")
                                    Text(item.title)
                                }
                            }
                            .contextMenu{
                                Button(action: {
                                    renameItem(item:item)
                                }) {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button(action: {
                                    togglePin(item: item)
                                }) {
                                    Label(item.isPinned ? "Unpin from Favorites" : "Pin to Favorites", systemImage: item.isPinned ? "pin.slash" : "pin")
                                }
                            }
                        }
                        .onDelete(perform: deleteItem) // Fixed `.onDelete`
                    }.listStyle(PlainListStyle())
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
            .alert("Rename Note", isPresented: $isRenameAlertPresented, actions: {
                            TextField("Enter new name", text: Binding(
                                get: { renamingItem?.title ?? "" },
                                set: { renamingItem?.title = $0 }
                            ))
                            Button("Save", action: {
                                if let renamingItem = renamingItem,
                                   let index = noteManager.items.firstIndex(where: { $0.id == renamingItem.id }) {
                                    noteManager.items[index].title = renamingItem.title
                                    noteManager.saveItems() // Save changes to disk
                                }
                                self.renamingItem = nil
                            })
                            Button("Cancel", role: .cancel) {
                                self.renamingItem = nil
                            }
                        })
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
        let validOffsets = offsets.filter { $0 < noteManager.items.count }
         validOffsets.forEach { noteManager.items.remove(at: $0) }
         noteManager.saveItems()
    }
    
    func renameItem(item: EditorItem){
        renamingItem = item
        isRenameAlertPresented = true
    }
    
    func togglePin(item: EditorItem) {
        if let index = noteManager.items.firstIndex(where: { $0.id == item.id }) {
            noteManager.items[index].isPinned.toggle()
            if noteManager.items[index].isPinned {
                noteManager.pinnedItems.append(noteManager.items[index])
            } else {
                noteManager.pinnedItems.removeAll { $0.id == item.id }
            }
            noteManager.saveItems() // Save changes to disk
        }
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

#Preview {
    let mockManager = NoteManager()
    mockManager.items = [
        EditorItem(id: UUID(), title: "Sample Text", type: .text, content: "This is a sample note."),
        EditorItem(id: UUID(), title: "Sample Drawing", type: .drawing, content: "")
    ]
    return ContentView().environmentObject(mockManager)
}
