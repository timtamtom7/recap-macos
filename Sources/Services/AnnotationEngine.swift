import Foundation
import SwiftUI
import AppKit
import CoreGraphics

final class AnnotationEngine: ObservableObject {
    @Published var currentTool: AnnotationTool = .pen
    @Published var currentColor: CodableColor = .red
    @Published var currentStrokeWidth: CGFloat = 4
    @Published var currentProject: AnnotationProject?
    @Published var isDrawing = false

    private var currentLayer: AnnotationLayer?
    private var undoStack: [[AnnotationLayer]] = []
    private var redoStack: [[AnnotationLayer]] = []

    func startStroke(at point: CGPoint, time: TimeInterval) {
        let layer = AnnotationLayer(
            tool: currentTool,
            color: currentTool == .highlighter ? CodableColor(red: currentColor.red, green: currentColor.green, blue: currentColor.blue, alpha: 0.4) : currentColor,
            strokeWidth: currentStrokeWidth,
            points: [point],
            startTime: time,
            endTime: time
        )
        currentLayer = layer
        isDrawing = true
    }

    func continueStroke(to point: CGPoint, time: TimeInterval) {
        guard var layer = currentLayer else { return }
        layer.points.append(point)
        layer.endTime = time
        currentLayer = layer
    }

    func endStroke(at rect: CGRect?, text: String?, time: TimeInterval) {
        guard var layer = currentLayer else { return }
        layer.endTime = time

        if let rect = rect {
            layer.rect = rect
        }
        if let text = text {
            layer.text = text
        }

        saveUndoState()
        currentProject?.layers.append(layer)
        currentLayer = nil
        isDrawing = false
    }

    func clearCurrentLayer() {
        currentLayer = nil
        isDrawing = false
    }

    func undo() {
        guard let project = currentProject, !undoStack.isEmpty else { return }
        redoStack.append(project.layers)
        let previousState = undoStack.removeLast()
        currentProject?.layers = previousState
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        undoStack.append(currentProject?.layers ?? [])
        currentProject?.layers = redoStack.removeLast()
    }

    private func saveUndoState() {
        undoStack.append(currentProject?.layers ?? [])
        redoStack.removeAll()
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }

    func setProject(_ project: AnnotationProject) {
        currentProject = project
        undoStack.removeAll()
        redoStack.removeAll()
    }

    func currentDrawingLayer() -> AnnotationLayer? {
        currentLayer
    }
}
