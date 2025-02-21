//  EditorView.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.

#warning("BUG_1: View Does Not")
import SwiftUI
import PencilKit

// This will hold the overall view and all variables for the view
struct EditorView: View {
    
    // Singelton to allow saving notes
    @EnvironmentObject var noteManager: NoteManager
    
    // Passing in from parent what ever note were working on
    @Binding var item: EditorItem
    @State private var pages: [PageModel] = [PageModel()] // Multi-page support: pages stored in an array.
    
    // MARK: Infinite Canvas State Variables
    @State private var canvasOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    // Variables Involving Drawing
    @State private var drawing = PKDrawing()
    @State private var selectedTool: PKTool = PKInkingTool(.pen, color: .white, width: 5)
    @State private var strokeWidth: CGFloat = 5
    @State private var selectedColor: Color = .white
    @State private var showColorPicker: Bool = false
    @State private var selectedPaper: PaperType = .graph
    
    // Variables For Handling ToolBar
    @State private var showToolbar: Bool = true // ✅ Controls toolbar visibility
    @State private var isEditingTitle = false  // State to toggle title editing
    @State private var tempTitle = ""  // Temporary storage for the editable title
    
    var body: some View {
        wholeEditorView()
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                titleChangerView()
            }
            
            // 🎨 **Color Picker Directly in Toolbar**
            ToolbarItem(placement: .navigationBarTrailing) {
                colorPickerButton()
            }
            
            // Paper Choice Button
            ToolbarItem(placement: .navigationBarTrailing) {
                paperSelectorButton()
            }
            
            ToolbarItem(placement: .navigationBarTrailing){
                // New "Add Page" Button placed next to the above
                addPageButton()
            }
        }
        .onAppear {
            loadPages(for: item.id)  // ✅ Load saved pages & drawings
        }
    }
}

// This will be the overall view
extension EditorView{
    private func wholeEditorView() -> some View{
        ZStack {
            VStack(spacing: 20) {
                ForEach($pages) { $page in
                    ZStack {
                        // Background Paper for a single page (8.5"x11" at 72 DPI: 612 x 792 points)
                        PaperView(type: selectedPaper)
                            .frame(width: 612, height: 792)
                        
                        // Drawing Canvas for this page
                        DrawingCanvas(
                            drawing: Binding(
                                get: { page.drawing }, // ✅ Get the correct page's drawing
                                set: { page.drawing = $0 // ✅ Modify only this page's drawing
                                    saveDrawing(for: item.id)
                                }
                            ),
                            selectedTool: $selectedTool,
                            strokeWidth: $strokeWidth
                        )
                        .frame(width: 612, height: 792)
                    }
                    .border(Color.gray, width: 1)
                }
            }
            .scaleEffect(canvasScale)
            .offset(canvasOffset)
            .gesture(
                    DragGesture()
                        .onChanged { value in
                            canvasOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = canvasOffset
                        }
                        .simultaneously(with:
                            MagnificationGesture()
                                .onChanged { value in
                                    canvasScale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = canvasScale
                                }
                        )
                )
            VStack {
                Spacer()
                Button(action: { showToolbar.toggle() }) {
                    Image(systemName: showToolbar ? "chevron.down" : "chevron.up")
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(.bottom, 8)
                .zIndex(1)
                
                if showToolbar {
                    toolbarView()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
        }
    }
}

// Helper Functions and Navigation View Buttons Abstracted for Neatness
extension EditorView{
    
    // Top Center Text Editor and Note Title
    private func titleChangerView() -> some View{
        // Group to toggle between text and editable text field
        Group {
            if isEditingTitle {
                TextField("Enter Title", text: $tempTitle, onCommit: {
                    // Actions to commit the title change
                    item.title = tempTitle
                    isEditingTitle = false
                    saveTitle()  // Call a function to save the new title
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onAppear {
                    self.tempTitle = self.item.title  // Initialize the temporary title
                }
            } else {
                Text(item.title)
                    .onTapGesture {
                        self.isEditingTitle = true  // Toggle editing mode
                    }
            }
        }
    }
    
    // Top Right Corner Color Picker Button
    private func colorPickerButton() -> some View{
        ColorPicker("", selection: $selectedColor)
            .scaleEffect(0.8)
            .labelsHidden() // ✅ Hide label for compact design
            .frame(width: 30) // ✅ Keep it compact in the toolbar
            .onChange(of: selectedColor) { newColor in
                let uiColor = UIColor(newColor)
                
                // 🛠 Fix: Prevent setting transparent or invalid colors
                if uiColor.cgColor.alpha < 0.1 {
                    print("⚠️ Selected color is nearly invisible! Reverting to black.")
                    selectedColor = .black
                }
                
                // 🛠 Fix: Ensure PencilKit supports the color
                DispatchQueue.main.async {
                    if let inkingTool = selectedTool as? PKInkingTool {
                        selectedTool = PKInkingTool(inkingTool.inkType, color: uiColor, width: strokeWidth)
                    }
                }
                
                print("🎨 Color changed to: \(selectedColor)")
            }
    }
    
    // Top Right Corner Paper Selector Button
    private func paperSelectorButton() -> some View {
        Menu {
            Button("Plain Paper") { selectedPaper = .plain }
            Button("Graph Paper") { selectedPaper = .graph }
            Button("Binder Paper") { selectedPaper = .binder }
        } label: {
            Image(systemName: "doc.plaintext") // ✅ Paper selection button
        }
    }
    
    // Top Right Corner Add Page Button
    private func addPageButton() -> some View{
        Button(action: {
            var newPage = PageModel() // ✅ Create a fresh new page
            newPage.drawing = PKDrawing() // ✅ Set the blank drawing properly
            pages.append(newPage) // ✅ Append new page without copying previous drawing
            saveDrawing(for: item.id) // ✅ Save updated pages
        }) {
            Image(systemName: "plus")
        }
    }
    
    private func loadPages(for noteID: UUID) {
        let fileURL = getFileURL(for: noteID) // ✅ Get the correct file path
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let loadedPages = try JSONDecoder().decode([PageModel].self, from: data)
                pages = loadedPages // ✅ Load only this note's pages
                print("✅ Loaded pages for note: \(noteID)")
            } catch {
                print("❌ Failed to load pages: \(error)")
                pages = [PageModel()] // Fallback to empty pages
            }
        } else {
            pages = [PageModel()] // If no file exists, start fresh
        }
    }
    
    private func getFileURL(for noteID: UUID) -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("\(noteID).json") // ✅ Unique file per note
    }
    
    // Helper Function to Save the drawing on exit of the view
    private func saveDrawing(for noteID: UUID) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileURL = getFileURL(for: noteID) // ✅ Get file path for the note
                let data = try JSONEncoder().encode(pages)
                try data.write(to: fileURL, options: .atomic)
                print("✅ Successfully saved pages for note: \(noteID)")
            } catch {
                print("❌ Failed to save pages: \(error)")
            }
        }
    }
    
//    private func saveDrawing() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            let drawingData = drawing.dataRepresentation()
//            
//            let drawingChanged = (item.drawing ?? Data()) != drawingData
//            let paperChanged = item.paperType != selectedPaper
//            
//            // 🛠 Fix: Detect when drawing is empty (no strokes)
//            let isEmptyDrawing = drawing.strokes.isEmpty
//            
//            if drawingChanged || paperChanged || isEmptyDrawing {
//                DispatchQueue.main.async {
//                    item.drawing = drawingData
//                    item.paperType = selectedPaper
//                    noteManager.saveItems()
//                    print("✅ Changes detected & saved!")
//                    print("🔴 Saving drawing size: \(drawingData.count) bytes")
//                    print("🔴 Saving paper type: \(selectedPaper)")
//                    
//                    // Ensure persistence (debugging fallback)
//                    UserDefaults.standard.set(drawingData, forKey: "lastSavedDrawing")
//                    UserDefaults.standard.synchronize()
//                }
//            } else {
//                print("⚠️ Skipping save: No changes detected")
//            }
//        }
//    }
    
    // Helped function to save the Title when its changed in the Editor view
    private func saveTitle() {
        // Function to save the title, possibly involving persistence logic
        print("Title saved: \(item.title)")
    }
}

// This will store the ToolBarCode
extension EditorView{
    // Bottom Tool Bar View
    @ViewBuilder
    private func toolbarView() -> some View {
        HStack {
            toolButton(icon: "pencil", tool: PKInkingTool(.pen, color: UIColor(selectedColor), width: strokeWidth))
            toolButton(icon: "scribble", tool: PKInkingTool(.pencil, color: UIColor(selectedColor), width: strokeWidth))
            toolButton(icon: "lasso", tool: PKLassoTool())
            toolButton(icon: "eraser", tool: PKEraserTool(.vector))

            // 🎚 **Thickness Slider**
            Slider(value: $strokeWidth, in: 1...10, step: 1)
                .frame(width: 100)
                .onChange(of: strokeWidth) { newValue in
                    if let inkingTool = selectedTool as? PKInkingTool {
                        selectedTool = PKInkingTool(inkingTool.inkType, color: UIColor(selectedColor), width: newValue)
                    }
                }
        }
        .padding()
    }
    
    // 🔹 **Reusable Tool Button Function**
    private func toolButton(icon: String, tool: PKTool) -> some View {
        Button(action: {
            if let inkingTool = tool as? PKInkingTool {
                selectedTool = PKInkingTool(inkingTool.inkType, color: UIColor(selectedColor), width: strokeWidth)
            } else {
                selectedTool = tool
            }
        }) {
            Image(systemName: icon)
                .padding()
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected(tool: tool) ? Color.gray : Color.clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // Checks if tool is Selected
    private func isSelected(tool: PKTool) -> Bool {
        if let inkingTool = tool as? PKInkingTool,
           let selectedInkingTool = selectedTool as? PKInkingTool {
            return inkingTool.inkType == selectedInkingTool.inkType
        }
        return type(of: selectedTool) == type(of: tool)
    }
}


#Preview {
    NavigationStack {
        ZStack {
            // 1) Black background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            // 2) The EditorView itself
            EditorView(
                item: .constant(
                    EditorItem(
                        id: UUID(),
                        title: "Sample Note",
                        type: .text,
                        content: "",
                        paperType: .plain,
                        pages: [PageModel()] // ✅ Fix: Provide a default page list
                    )
                )
            )
            .environmentObject(NoteManager())
        }
        // 3) On-appear styling for the navigation bar
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.77)
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 32)
            ]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        }
    }
    // 4) Choose an iPad device & orientation
    .previewDevice("iPad (10th generation)")
    .previewInterfaceOrientation(.portrait)
    .previewDisplayName("EditorView iPad")
}
