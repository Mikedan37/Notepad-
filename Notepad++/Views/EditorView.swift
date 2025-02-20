//  EditorView.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.

import SwiftUI
import PencilKit

struct EditorView: View {
    @Binding var item: EditorItem
    @State private var drawing = PKDrawing()
    @State private var selectedTool: PKTool = PKInkingTool(.pen, color: .black, width: 5)
    @State private var strokeWidth: CGFloat = 5
    @State private var selectedColor: Color = .white
    @State private var showColorPicker: Bool = false
    @State private var selectedPaper: PaperType = .plain
    @State private var showToolbar: Bool = true // ✅ Controls toolbar visibility
    @EnvironmentObject var noteManager: NoteManager
    
    var body: some View {
        ZStack {
            // ✅ Background Paper
            PaperView(type: selectedPaper)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // ✅ Drawing Canvas
                DrawingCanvas(drawing: $drawing, selectedTool: $selectedTool, strokeWidth: $strokeWidth)
                    .onAppear {
                        DispatchQueue.main.async {
                            let key = "lastSavedDrawing_\(item.id.uuidString)"
                            
                            if let savedData = item.drawing, !savedData.isEmpty {
                                print("📂 Attempting to load saved drawing: \(savedData.count) bytes")
                                if let loadedDrawing = try? PKDrawing(data: savedData) {
                                    drawing = loadedDrawing
                                    print("🟢 Successfully loaded drawing size: \(savedData.count) bytes, strokes: \(drawing.strokes.count)")
                                } else {
                                    print("❌ Failed to decode drawing data (possible corruption)")
                                }
                            } else {
                                // Use the note-specific key from UserDefaults as fallback
                                if let lastSaved = UserDefaults.standard.data(forKey: key) {
                                    if let lastDrawing = try? PKDrawing(data: lastSaved) {
                                        drawing = lastDrawing
                                        print("🛠 Loaded drawing from UserDefaults for key: \(key)")
                                    }
                                } else {
                                    drawing = PKDrawing()
                                }
                            }
                            
                            selectedPaper = item.paperType ?? .plain
                            print("🟢 Loaded paper type: \(selectedPaper)")
                        }
                    }
                .onDisappear {
                    saveDrawing()
                    print("Save Drawing Ran")
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // ✅ Toggle Button to Show/Hide Toolbar
                Button(action: { showToolbar.toggle() }) {
                    Image(systemName: showToolbar ? "chevron.down" : "chevron.up")
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(.bottom, 8)
                .zIndex(1) // Ensure button is above everything

                // ✅ Toolbar (Hidden when `showToolbar` is `false`)
                if showToolbar {
                    toolbarView()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom)) // ✅ Smooth hide/show animation
                        .zIndex(1) // ✅ Keep above PaperView
                }
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 🎨 **Color Picker Directly in Toolbar**
                ToolbarItem(placement: .navigationBarTrailing) {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Plain Paper") { selectedPaper = .plain }
                    Button("Graph Paper") { selectedPaper = .graph }
                    Button("Binder Paper") { selectedPaper = .binder }
                } label: {
                    Image(systemName: "doc.plaintext") // ✅ Paper selection button
                }
            }
        }
    }
    
    private func saveDrawing() {
        DispatchQueue.global(qos: .userInitiated).async {
            let drawingData = drawing.dataRepresentation()
            let drawingChanged = (item.drawing ?? Data()) != drawingData
            let paperChanged = item.paperType != selectedPaper
            let isEmptyDrawing = drawing.strokes.isEmpty

            if drawingChanged || paperChanged || isEmptyDrawing {
                DispatchQueue.main.async {
                    item.drawing = drawingData
                    item.paperType = selectedPaper
                    noteManager.saveItems()
                    print("✅ Changes detected & saved!")
                    print("🔴 Saving drawing size: \(drawingData.count) bytes")
                    print("🔴 Saving paper type: \(selectedPaper)")
                    
                    // Save drawing with note-specific key
                    let key = "lastSavedDrawing_\(item.id.uuidString)"
                    UserDefaults.standard.set(drawingData, forKey: key)
                    UserDefaults.standard.synchronize()
                }
            } else {
                print("⚠️ Skipping save: No changes detected")
            }
        }
    }

    // ✅ Extracted Toolbar View (So We Can Hide It Easily)
    @ViewBuilder
    private func toolbarView() -> some View {
        HStack {
            // ✏️ **Pen Tool**
            Button(action: {
                selectedTool = PKInkingTool(.pen, color: UIColor(selectedColor), width: strokeWidth)
            }) {
                Image(systemName: "pencil")
                    .padding()
                    .frame(height: 30)
                    .background(isSelected(tool: .pen) ? Color.gray : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // ✍️ **Pencil Tool**
            Button(action: {
                selectedTool = PKInkingTool(.pencil, color: UIColor(selectedColor), width: strokeWidth)
            }) {
                Image(systemName: "scribble")
                    .padding()
                    .frame(height: 30)
                    .background(isSelected(tool: .pencil) ? Color.gray : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // ✂️ **Clipper / Selection Tool**
            Button(action: {
                selectedTool = PKLassoTool()
            }) {
                Image(systemName: "lasso")
                    .padding()
                    .frame(height: 30)
                    .background(selectedTool is PKLassoTool ? Color.gray : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 🧼 **Eraser Tool**
            Button(action: {
                selectedTool = PKEraserTool(.vector)
            }) {
                Image(systemName: "eraser")
                    .padding()
                    .frame(height: 30)
                    .background(selectedTool is PKEraserTool ? Color.gray : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

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

    func isSelected(tool: PKInkingTool.InkType) -> Bool {
        if let inkingTool = selectedTool as? PKInkingTool {
            return inkingTool.inkType == tool
        }
        return false
    }
}

struct DrawingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var selectedTool: PKTool // NEW: Tool selection
    @Binding var strokeWidth: CGFloat // NEW: Stroke width control

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.tool = selectedTool
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = context.coordinator
        canvasView.addInteraction(pencilInteraction)
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
        uiView.tool = selectedTool // Update tool when changed
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, drawing: $drawing)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate, UIPencilInteractionDelegate {
        var parent: DrawingCanvas
        @Binding var drawing: PKDrawing
        private var lastUpdateTime: Date = Date()
        private var lastTool: PKTool? // Store last used tool

        init(parent: DrawingCanvas, drawing: Binding<PKDrawing>) {
            self.parent = parent
            _drawing = drawing
            self.lastTool = parent.selectedTool // Initialize last tool
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    // ✅ Ensure the drawing is valid before assigning it
                    let newDrawing = canvasView.drawing
                    if !newDrawing.strokes.isEmpty {
                        self.parent.drawing = newDrawing
                    }
                }
//            let now = Date()
//
//            // Only update if at least 0.2 seconds have passed (debounce mechanism)
//            if now.timeIntervalSince(lastUpdateTime) > 0.2 {
//                DispatchQueue.main.async {
//                    self.drawing = canvasView.drawing
//                }
//                lastUpdateTime = now
//            }
        }

        // ✅ Handle Apple Pencil Double-Tap to Switch Tools
            func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
                DispatchQueue.main.async {
                    if let lastTool = self.lastTool {
                        let currentTool = self.parent.selectedTool
                        self.parent.selectedTool = lastTool
                        self.lastTool = currentTool
                        print("🔁 Switched tool on double-tap")
                    } else {
                        self.lastTool = self.parent.selectedTool
                        print("🟡 No last tool stored, setting current tool as last used.")
                    }
                }
            }
    }
}

#Preview{
    
}
