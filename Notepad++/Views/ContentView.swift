import SwiftUI

struct ContentView: View {
    @EnvironmentObject var noteManager: NoteManager
    @State private var renamingItem: EditorItem? // Tracks renamed item
    @State private var isRenameAlertPresented = false // Controls the alert visibility
    @State private var expandedFolders: Set<UUID> = [] // Track expanded folder IDs
    @State private var searchText: String = ""
    
    init(){
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.9) // Background for entire view
                    .ignoresSafeArea()
                VStack{
                    if !noteManager.items.filter({ $0.isPinned }).isEmpty {
                        // Display pinned items
                        ZStack{
                            RoundedRectangle(cornerRadius: 10).foregroundStyle(.clear)
                            VStack {
                                // Pinned notes UI
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(noteManager.items.filter({ $0.isPinned })) { item in
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
                                                VStack {
                                                    Circle()
                                                        .fill(Color.yellow.opacity(0.8)).brightness(0.1)
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
                                            }.contextMenu{
                                                Button(action: {
                                                    togglePin(item: item)
                                                }) {
                                                    Label(item.isPinned ? "Unpin from Favorites" : "Pin to Favorites", systemImage: item.isPinned ? "pin.slash" : "pin")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal,10).padding([.bottom,.top],5)
                                }.padding([.bottom,.top],5)
                            }
                        }.frame(height:90).padding(.horizontal,15).padding(.top, 15).padding(.bottom,5)
                    }
                    ZStack{
                        Color.clear.ignoresSafeArea()
                        List {
                            if noteManager.items.contains(where: { $0.type == .text }) {
                                Section(header: Text("Documents").foregroundStyle(.white).bold()){
                                    ForEach(noteManager.items.filter {item in (searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)) && (item.type == .text)}) { item in
                                        
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
                                                Image(systemName: item.type.systemImage)
                                                Text(item.title)
                                            }.foregroundColor(.white)
                                        }.listRowBackground(Color.clear)
                                            .contextMenu{
                                                //                                Button(action: {
                                                ////                                    if let folder = noteManager.folders.first { // Choose a folder here
                                                ////                                        noteManager.moveNoteToFolder(note: item, folder: folder)
                                                ////                                    }
                                                //                                }) {
                                                //                                    Label("Move to Folder", systemImage: "folder")
                                                //                                }
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
                                        
                                        
                                    }.onDelete(perform: deleteItem) // Fixed `.onDelete`
                                    //.filter{$0.type == .text}
                                }
                            }
                            if noteManager.items.contains(where: { $0.type == .drawing }) {
                                Section(header: Text("Drawings").foregroundStyle(.white).bold()){
                                    ForEach(noteManager.items.filter {item in (searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)) && (item.type == .drawing)}) { item in
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
                                                Image(systemName: item.type.systemImage)
                                                Text(item.title)
                                            }.foregroundColor(.white)
                                        }.listRowBackground(Color.clear)
                                            .contextMenu{
                                                //                                Button(action: {
                                                ////                                    if let folder = noteManager.folders.first { // Choose a folder here
                                                ////                                        noteManager.moveNoteToFolder(note: item, folder: folder)
                                                ////                                    }
                                                //                                }) {
                                                //                                    Label("Move to Folder", systemImage: "folder")
                                                //                                }
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
                                    }.onDelete(perform: deleteItem) // Fixed `.onDelete`
                                    //.filter{$0.type == .drawing}
                                }
                            }
                        }
                        .searchable(text: $searchText , placement: .navigationBarDrawer)
                        .listStyle(GroupedListStyle()).background(Color.clear).scrollContentBackground(.hidden)
                    }
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
    
    private func updateItem(_ updatedItem: EditorItem) {
        DispatchQueue.main.async {
            if let index = noteManager.items.firstIndex(where: { $0.id == updatedItem.id }) {
                noteManager.items[index] = updatedItem
            }
        }
    }

    func addItem(type: EditorItemType) {
        let newItem = EditorItem(
            id: UUID(),
            title: "New \(type == .text ? "Text" : "Drawing")",
            type: type,
            content: type == .text ? "" : "",
            pages: [PageModel()] // ✅ Ensure every new note starts with at least one page
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
    
    func addFolder() {
        let newFolder = Folder(id: UUID(), title: "New Folder", notes: [])
        noteManager.folders.append(newFolder)
        noteManager.saveItems()
    }
    
    func deleteNoteFromFolder(note: EditorItem, folder: Folder) {
        if let folderIndex = noteManager.folders.firstIndex(where: { $0.id == folder.id }),
           let noteIndex = noteManager.folders[folderIndex].notes.firstIndex(where: { $0.id == note.id }) {
            noteManager.folders[folderIndex].notes.remove(at: noteIndex)
            noteManager.saveItems()
        }
    }
    
    func toggleFolderExpansion(folder: Folder) {
        if expandedFolders.contains(folder.id) {
            expandedFolders.remove(folder.id)
        } else {
            expandedFolders.insert(folder.id)
        }
    }
    
    func moveNoteToFolder(note: EditorItem, folder: Folder) {
        // Find the folder to which the note will be moved
        guard let targetFolderIndex = noteManager.folders.firstIndex(where: { $0.id == folder.id }) else {
            print("Target folder not found.")
            return
        }

        // Append the note to the target folder's notes
        noteManager.folders[targetFolderIndex].notes.append(note)

        // Remove the note from the noteManager.items list if it exists there
        if let noteIndex = noteManager.items.firstIndex(where: { $0.id == note.id }) {
            noteManager.items.remove(at: noteIndex)
        } else {
            print("Note not found in noteManager.items. Make sure the source collection is correct.")
        }

        // Save changes to the noteManager
        noteManager.saveItems()
    }
    
    
    /// Configure the navigation bar appearance
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        
        // Set the background color for the navigation bar
        appearance.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.77)
       
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
        EditorItem(
            id: UUID(),
            title: "Sample Text",
            type: .text,
            content: "This is a sample note.",
            pages: [PageModel()] // ✅ Ensure pages is initialized correctly
        ),
        EditorItem(
            id: UUID(),
            title: "Sample Drawing",
            type: .drawing,
            content: "",
            pages: [PageModel()] // ✅ Ensure pages is initialized correctly
        )
    ]
    return ContentView().environmentObject(mockManager) // ✅ Explicitly return the view
}
