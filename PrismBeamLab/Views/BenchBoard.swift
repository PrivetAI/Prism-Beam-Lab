//  BenchBoard.swift
//  Prism Beam Lab
//
//  The optical bench itself: grid, glowing beams, components, receptors and all touch
//  handling. Every screen coordinate is derived from `boardSide`, which the PARENT measures
//  with a GeometryReader — never from the Canvas closure's own `size` (BATCH_BRIEF §7.1).

import SwiftUI

// MARK: - Transform

struct BenchTransform {
    let benchSide: Double
    let boardSide: CGFloat

    var scale: CGFloat { boardSide / CGFloat(benchSide) }

    func toScreen(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * scale, y: p.y * scale)
    }

    func toBench(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x / scale, y: p.y / scale)
    }

    func len(_ v: Double) -> CGFloat { CGFloat(v) * scale }
}

// MARK: - Annulus (rotation dial hit area)

struct AnnulusShape: Shape {
    var innerFraction: CGFloat = 0.62
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let ir = r * innerFraction
        // Two subpaths wound in OPPOSITE directions so the ring survives either fill rule.
        p.move(to: CGPoint(x: c.x + r, y: c.y))
        p.addArc(center: c, radius: r, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        p.closeSubpath()
        p.move(to: CGPoint(x: c.x + ir, y: c.y))
        p.addArc(center: c, radius: ir, startAngle: .degrees(360), endAngle: .degrees(0), clockwise: true)
        p.closeSubpath()
        return p
    }
}

// MARK: - Board rect reporting

struct BoardRectKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let v = nextValue()
        if v != .zero { value = v }
    }
}

// MARK: - The board

struct BenchBoard: View {
    @ObservedObject var session: BenchSession
    let boardSide: CGFloat
    var colourBlind: Bool = false
    var beamLabels: Bool = false
    var interactive: Bool = true
    var onPlaceRequest: ((CGPoint) -> Void)? = nil
    var onFeedback: (() -> Void)? = nil

    @State private var dragIndex: Int? = nil
    @State private var dragStart: CGPoint = .zero
    @State private var dragPushed: Bool = false
    @State private var rotatingIndex: Int? = nil

    private var t: BenchTransform {
        BenchTransform(benchSide: session.level.benchSide, boardSide: boardSide)
    }

    private var componentBoxSide: CGFloat { t.len(78) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Surface + grid + beams (never receives touches).
            Canvas { ctx, _ in
                drawBench(ctx)
            }
            .frame(width: boardSide, height: boardSide)
            .allowsHitTesting(false)

            // 2. Tap surface for placing parts / clearing the selection.
            Color.clear
                .frame(width: boardSide, height: boardSide)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
                        .onEnded { value in
                            guard interactive else { return }
                            let dx = abs(value.translation.width), dy = abs(value.translation.height)
                            guard dx < 8 && dy < 8 else { return }
                            onPlaceRequest?(t.toBench(value.location))
                        }
                )

            // 3. Hint ghosts.
            ForEach(Array(session.hintGhosts.enumerated()), id: \.offset) { _, ghost in
                ComponentGlyph(kind: ghost.kind, band: ghost.band, size: componentBoxSide,
                               angle: ghost.angle, colourBlind: colourBlind)
                    .opacity(0.35)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Lab.amber.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .frame(width: componentBoxSide * 0.9, height: componentBoxSide * 0.9)
                    )
                    .allowsHitTesting(false)
                    .position(t.toScreen(ghost.position))
            }

            // 4. Emitters and receptors — decoration, never touch targets.
            ForEach(Array(session.emitters.enumerated()), id: \.offset) { _, e in
                EmitterGlyph(size: t.len(46), angle: e.angle, band: e.band)
                    .allowsHitTesting(false)
                    .position(clampToBoard(t.toScreen(e.position)))
            }

            ForEach(Array(session.receptors.enumerated()), id: \.offset) { i, r in
                ReceptorGlyph(diameter: t.len(r.radius * 2.1),
                              spec: r,
                              satisfied: i < session.evaluation.satisfied.count && session.evaluation.satisfied[i],
                              colourBlind: colourBlind)
                    .allowsHitTesting(false)
                    .position(t.toScreen(r.position))
            }

            // 5. Locked components.
            ForEach(Array(session.level.fixed.enumerated()), id: \.offset) { _, c in
                ComponentGlyph(kind: c.kind, band: c.band, size: componentBoxSide, angle: c.angle,
                               locked: true,
                               pairLabel: c.kind == .fibrePortal ? pairLetter(c.pairID) : nil,
                               colourBlind: colourBlind)
                    .allowsHitTesting(false)
                    .position(t.toScreen(c.position))
            }

            // 6. Rotation dial — under the components so a part always wins its own touch.
            if interactive, let sel = session.selection, session.placed.indices.contains(sel),
               session.placed[sel].kind.rotatable {
                rotationDial(index: sel)
            }

            // 7. Player components (topmost so they take the touch).
            ForEach(Array(session.placed.enumerated()), id: \.offset) { i, c in
                componentView(index: i, component: c)
            }
        }
        .frame(width: boardSide, height: boardSide)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Lab.bench)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Lab.benchEdge, lineWidth: 1.5))
        )
        .clipped()
        .coordinateSpace(name: "board")
        .background(
            GeometryReader { g in
                Color.clear.preference(key: BoardRectKey.self, value: g.frame(in: .named("bench")))
            }
        )
    }

    private func clampToBoard(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(t.len(16), p.x), boardSide - t.len(16)),
                y: min(max(t.len(16), p.y), boardSide - t.len(16)))
    }

    private func pairLetter(_ id: Int?) -> String {
        guard let id = id else { return "" }
        let letters = ["A", "B", "C", "D"]
        return letters[min(max(0, id), letters.count - 1)]
    }

    // MARK: component view + gestures

    @ViewBuilder
    private func componentView(index i: Int, component c: PlacedComponent) -> some View {
        let selected = session.selection == i
        ComponentGlyph(kind: c.kind, band: c.band, size: componentBoxSide, angle: c.angle,
                       pairLabel: c.kind == .fibrePortal ? pairLetter(c.pairID) : nil,
                       colourBlind: colourBlind)
            .background(
                Circle()
                    .fill(Lab.cyan.opacity(selected ? 0.16 : 0))
                    .frame(width: componentBoxSide, height: componentBoxSide)
            )
            .overlay(
                Circle()
                    .stroke(Lab.cyan.opacity(selected ? 0.9 : 0), lineWidth: 1.5)
                    .frame(width: componentBoxSide * 0.94, height: componentBoxSide * 0.94)
            )
            .frame(width: componentBoxSide, height: componentBoxSide)
            // A circular touch area (not the full square) keeps the bench corners free for
            // placing the next part, and still covers the whole glyph. contentShape and the
            // gesture both go BEFORE .position, or the hit area becomes the whole board.
            .contentShape(Circle())
            .gesture(interactive ? componentDrag(i) : nil)
            .position(t.toScreen(c.position))
    }

    private func componentDrag(_ i: Int) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
            .onChanged { value in
                if dragIndex != i {
                    dragIndex = i
                    dragPushed = false
                    dragStart = CGPoint(x: session.placed[safe: i]?.x ?? 0,
                                        y: session.placed[safe: i]?.y ?? 0)
                    session.selection = i
                }
                let moved = abs(value.translation.width) > 3 || abs(value.translation.height) > 3
                if moved {
                    if !dragPushed {
                        session.snapshotForDrag()
                        dragPushed = true
                    }
                    let d = t.toBench(CGPoint(x: value.translation.width, y: value.translation.height))
                    session.move(index: i, to: CGPoint(x: dragStart.x + d.x, y: dragStart.y + d.y))
                }
            }
            .onEnded { _ in
                if dragPushed { onFeedback?() }
                dragIndex = nil
                dragPushed = false
            }
    }

    @ViewBuilder
    private func rotationDial(index sel: Int) -> some View {
        let c = session.placed[sel]
        let centre = t.toScreen(c.position)
        let dialD = max(96, min(boardSide * 0.46, t.len(150)))
        ZStack {
            AnnulusShape(innerFraction: 0.60)
                .fill(Lab.cyan.opacity(0.07))
            Circle()
                .stroke(Lab.cyan.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
                .frame(width: dialD * 0.8, height: dialD * 0.8)
            Circle()
                .fill(Lab.amber)
                .frame(width: 13, height: 13)
                .offset(x: cos(CGFloat(c.angle)) * dialD * 0.4,
                        y: sin(CGFloat(c.angle)) * dialD * 0.4)
            Circle()
                .fill(Lab.amber.opacity(0.5))
                .frame(width: 9, height: 9)
                .offset(x: -cos(CGFloat(c.angle)) * dialD * 0.4,
                        y: -sin(CGFloat(c.angle)) * dialD * 0.4)
        }
        .frame(width: dialD, height: dialD)
        .contentShape(AnnulusShape(innerFraction: 0.60))
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
                .onChanged { value in
                    if rotatingIndex != sel {
                        rotatingIndex = sel
                        session.beginRotate(index: sel)
                    }
                    let a = atan2(Double(value.location.y - centre.y), Double(value.location.x - centre.x))
                    session.setAngle(index: sel, radians: a)
                }
                .onEnded { _ in
                    if rotatingIndex == sel {
                        session.endRotate()
                        onFeedback?()
                    }
                    rotatingIndex = nil
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.55).onEnded { _ in
                session.fineMode.toggle()
                onFeedback?()
            }
        )
        .position(centre)
    }

    // MARK: canvas drawing

    private func drawBench(_ ctx: GraphicsContext) {
        let g = ctx

        // grid
        let step = t.len(40)
        if step > 6 {
            var grid = Path()
            var x: CGFloat = step
            while x < boardSide - 0.5 {
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: boardSide))
                x += step
            }
            var y: CGFloat = step
            while y < boardSide - 0.5 {
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: boardSide, y: y))
                y += step
            }
            g.stroke(grid, with: .color(Lab.grid), lineWidth: 0.6)
        }

        // beams, additive
        var glow = g
        glow.blendMode = .plusLighter
        let segments = session.evaluation.trace.segments
        for s in segments {
            let a = t.toScreen(s.a)
            let b = t.toScreen(s.b)
            var p = Path()
            p.move(to: a)
            p.addLine(to: b)
            let inten = min(1.4, max(0.05, s.intensity))
            let (r, gg, bb) = Lab.beamRGB(s.band)
            let wide = Color(.sRGB, red: r, green: gg, blue: bb, opacity: 0.16 * inten)
            let core = Color(.sRGB, red: min(1, r + 0.25), green: min(1, gg + 0.25), blue: min(1, bb + 0.25),
                             opacity: 0.95)
            glow.stroke(p, with: .color(wide),
                        style: StrokeStyle(lineWidth: 3.0 + 7.0 * CGFloat(inten), lineCap: .round))
            glow.stroke(p, with: .color(core),
                        style: StrokeStyle(lineWidth: 0.9 + 2.0 * CGFloat(inten), lineCap: .round))
        }

        // colour-blind band tags along long beams
        if beamLabels || colourBlind {
            for s in segments {
                let a = t.toScreen(s.a)
                let b = t.toScreen(s.b)
                let dx = b.x - a.x, dy = b.y - a.y
                let len = (dx * dx + dy * dy).squareRoot()
                if len < 70 { continue }
                let mid = CGPoint(x: a.x + dx * 0.5, y: a.y + dy * 0.5)
                let text = Text(s.band.letter)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.beam(s.band))
                g.draw(text, at: CGPoint(x: mid.x, y: mid.y - 9), anchor: .center)
            }
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
