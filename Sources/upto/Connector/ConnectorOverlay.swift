import SwiftUI
import UptoCore

// Draws the line from the focused form field to the preview element it
// affects, plus a highlight on every affected element.
struct ConnectorOverlay: View {
    let anchors: ConnectorAnchors
    let focus: EditorFocus?
    let activity: Activity

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let focus {
                    let targets = focus.previewTargets(in: activity)
                    let targetRects = targets.compactMap { target in
                        anchors.targets[target].map { proxy[$0] }
                    }
                    let fieldRect = anchors.fields[focus].map { proxy[$0] }
                    let viewport = anchors.editorViewport.map { proxy[$0] }

                    ForEach(Array(targetRects.enumerated()), id: \.offset) { _, rect in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                            .frame(width: rect.width + 8, height: rect.height + 8)
                            .position(x: rect.midX, y: rect.midY)
                    }

                    // No line when the field's row is scrolled out of
                    // view. The target highlights stay.
                    if let fieldRect,
                       let target = targetRects.first,
                       viewport.map({ $0.intersects(fieldRect) }) ?? true {
                        let start = CGPoint(x: fieldRect.maxX - 2, y: fieldRect.midY)
                        let end = CGPoint(x: target.minX - 6, y: target.midY)
                        ConnectorLine(from: start, to: end)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .position(start)
                    }
                }
            }
            .animation(.snappy(duration: 0.2), value: focus)
        }
        .allowsHitTesting(false)
    }
}

struct ConnectorLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let reach = max(40, abs(to.x - from.x) * 0.4)
        path.addCurve(
            to: to,
            control1: CGPoint(x: from.x + reach, y: from.y),
            control2: CGPoint(x: to.x - reach, y: to.y)
        )
        return path
    }
}
