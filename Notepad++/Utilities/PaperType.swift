//
//  PaperType.swift
//  Notepad++
//
//  Created by Michael Danylchuk on 2/18/25.
//

import SwiftUI

enum PaperType: String, Codable{
    case plain, graph, binder
}

struct PaperView: View {
    let type: PaperType

    var body: some View {
        switch type {
        case .plain:
            Color.white
        case .graph:
            GraphPaperView()
        case .binder:
            BinderPaperView()
        }
    }
}

struct GraphPaperView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 20
                for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            .background(Color.white)
        }
    }
}

struct BinderPaperView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                Path { path in
                    let lineSpacing: CGFloat = 25
                    for y in stride(from: 40, to: geometry.size.height, by: lineSpacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 0))
                    path.addLine(to: CGPoint(x: 40, y: geometry.size.height))
                }
                .stroke(Color.red.opacity(0.5), lineWidth: 2)
            }
        }
    }
}


