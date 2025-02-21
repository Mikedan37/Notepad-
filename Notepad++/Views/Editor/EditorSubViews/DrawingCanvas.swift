//  DrawingCanvas.swift
//  Notepad++
//  Created by Michael Danylchuk on 2/20/25.

import PencilKit
import SwiftUI

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
        canvasView.becomeFirstResponder()
        
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = context.coordinator
        canvasView.addInteraction(pencilInteraction)
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
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

struct TouchDetectingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var selectedTool: PKTool?
    @Binding var strokeWidth: CGFloat
    let isFingerDrawingAllowed = false // Prevent accidental finger drawing
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: TouchDetectingCanvas

        init(parent: TouchDetectingCanvas) {
            self.parent = parent
        }

        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            // Re-enable the tool when Pencil is used
            DispatchQueue.main.async {
                if self.parent.selectedTool == nil {
                    self.parent.selectedTool = PKInkingTool(.pen, color: .black, width: self.parent.strokeWidth)
                    print("✏️ Apple Pencil detected, re-enabling pen tool!")
                }
            }
        }

        func canvasViewTouchesBegan(_ canvasView: PKCanvasView, touches: Set<UITouch>, with event: UIEvent?) {
            // Check if touch is from a finger
            if let touch = touches.first, touch.type == .direct {
                DispatchQueue.main.async {
                    print("🖐️ Finger detected, deselecting tool!")
                    self.parent.selectedTool = nil // Unselect tool
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        canvasView.allowsFingerDrawing = isFingerDrawingAllowed // Prevent accidental finger drawing
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
        if let tool = selectedTool {
            uiView.tool = tool
        }
    }
}
