//  PageModel.swift
//  Notepad++
//  Created by Michael Danylchuk on 2/20/25.

import Foundation
import PencilKit

struct PageModel: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = "New Page"
    var paperType: PaperType = .plain
    var drawingData: Data = PKDrawing().dataRepresentation()

    var drawing: PKDrawing {
        get { (try? PKDrawing(data: drawingData)) ?? PKDrawing() }
        set { drawingData = newValue.dataRepresentation() }
    }

    // ✅ Implement `Equatable`
    static func == (lhs: PageModel, rhs: PageModel) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.paperType == rhs.paperType && lhs.drawingData == rhs.drawingData
    }
}
