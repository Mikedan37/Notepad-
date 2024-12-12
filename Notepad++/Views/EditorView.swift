//  EditorView.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 12/11/24.

import SwiftUI
import PencilKit

struct EditorView: View {
    @Binding var item: EditorItem // Binding to the item being edited
    @State private var drawing = PKDrawing() // Current drawing content

    var body: some View {
        VStack {
            if item.type == .text {
                TextEditor(text: $item.content) // Edit text
                    .padding()
            } else if item.type == .drawing {
                DrawingCanvas(drawing: $drawing)
                    .onAppear {
                        if let data = item.drawing {
                            DispatchQueue.main.async {
                                drawing = (try? PKDrawing(data: data)) ?? PKDrawing()
                            }
                        }
                    }
                    .onDisappear {
                        DispatchQueue.main.async {
                            item.drawing = try? drawing.dataRepresentation()
                        }
                    }
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DrawingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}
