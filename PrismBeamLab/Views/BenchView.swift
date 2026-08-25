//  BenchView.swift
//  Prism Beam Lab
//
//  The play screen: HUD, optical bench, component tray, hints and the completion panel.
//  Portrait stacks HUD / bench / tray; landscape moves the tray to the right-hand rail so the
//  bench never gets squeezed to nothing on a short screen.

import SwiftUI

struct BenchTab: View {
    @EnvironmentObject var store: LabStore
    var body: some View {
        BenchView(level: LevelLibrary.level(id: store.currentLevelID))
            .id("bench-\(store.currentLevelID)-\(store.benchEpoch)")
    }
}

struct BenchView: View {
    let level: LevelSpec
    @EnvironmentObject var store: LabStore
    @StateObject private var session: BenchSession

    @State private var boardRect: CGRect = .zero
    @State private var dragKind: InventoryEntry? = nil
    @State private var dragPoint: CGPoint = .zero
    @State private var showWin = false
    @State private var showGoal = false
    @State private var awardedStars = 0
    @State private var hintMessage: String? = nil

    private let sideRailWidth: CGFloat = 96

    init(level: LevelSpec) {
        self.level = level
        _session = StateObject(wrappedValue: BenchSession(level: level))
    }

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let landscape = geo.size.width > geo.size.height
            let compact = landscape || geo.size.height < 610
            let hudHeight: CGFloat = landscape ? 78 : (compact ? 92 : 108)

            ZStack(alignment: .top) {
                if landscape {
                    let boardSide = max(90, min(width - sideRailWidth - 22,
                                                geo.size.height - hudHeight - 10))
                    VStack(spacing: 0) {
                        hud(width: width, compact: true).frame(height: hudHeight)
                        HStack(spacing: 0) {
                            ZStack {
                                BenchBoard(session: session, boardSide: boardSide,
                                           colourBlind: store.progress.colourBlind,
                                           beamLabels: store.progress.showBeamLabels,
                                           onPlaceRequest: handleBoardTap,
                                           onFeedback: { store.tapFeedback() })
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            sideTray()
                                .frame(width: sideRailWidth)
                        }
                    }
                    .frame(width: width, height: geo.size.height)
                } else {
                    let trayHeight: CGFloat = compact ? 96 : 112
                    let availableH = max(80, geo.size.height - hudHeight - trayHeight - 10)
                    let boardSide = max(90, min(width - 24, availableH))
                    VStack(spacing: 0) {
                        hud(width: width, compact: compact).frame(height: hudHeight)
                        ZStack {
                            BenchBoard(session: session, boardSide: boardSide,
                                       colourBlind: store.progress.colourBlind,
                                       beamLabels: store.progress.showBeamLabels,
                                       onPlaceRequest: handleBoardTap,
                                       onFeedback: { store.tapFeedback() })
                        }
                        .frame(width: width, height: availableH)
                        bottomTray(width: width, compact: compact).frame(height: trayHeight)
                    }
                    .frame(width: width)
                }

                if let entry = dragKind {
                    ComponentGlyph(kind: entry.kind, band: entry.band, size: 56,
                                   colourBlind: store.progress.colourBlind)
                        .opacity(0.85)
                        .allowsHitTesting(false)
                        .position(dragPoint)
                }

                if showGoal { goalPanel(width: width, maxHeight: geo.size.height - 70) }
                if showWin { winPanel(width: width) }

                if let msg = hintMessage {
                    Text(msg)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Lab.background)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Lab.amber))
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .coordinateSpace(name: "bench")
            .onPreferenceChange(BoardRectKey.self) { boardRect = $0 }
        }
        .background(Lab.background)
        .onAppear { session.fineMode = store.progress.fineSnapDefault }
        .onChange(of: session.evaluation.solved) { solved in
            if solved { handleSolved() }
        }
    }

    // MARK: HUD

    private func hud(width: CGFloat, compact: Bool) -> some View {
        VStack(spacing: compact ? 5 : 8) {
            HStack(alignment: .center, spacing: 10) {
                Button {
                    store.tab = 1
                } label: {
                    HStack(spacing: 4) {
                        ChevronShape(pointsRight: false)
                            .stroke(Lab.cyan, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 10, height: 14)
                        Text("Levels")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Lab.cyan)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .background(Capsule().fill(Lab.panelRaised))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("LEVEL \(level.id)  ·  CH \(level.chapter)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.dim)
                        .tracking(1.1)
                    Text(level.name)
                        .font(.system(size: compact ? 15 : 17, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.ivory)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 4)

                HStack(spacing: 5) {
                    ForEach(Array(session.evaluation.satisfied.enumerated()), id: \.offset) { i, ok in
                        ZStack {
                            Circle()
                                .fill(ok ? Lab.ok : Lab.hex(0x2A3352))
                                .frame(width: 14, height: 14)
                            if let s = session.receptors[safe: i], !ok {
                                Text(s.label)
                                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                                    .foregroundColor(Lab.muted)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)

            HStack(spacing: 7) {
                statChip(title: "PARTS", value: "\(session.componentsUsed)/\(level.parComponents)",
                         good: session.componentsUsed <= level.parComponents)
                statChip(title: "TURNS", value: "\(session.rotationCount)/\(level.parRotations)",
                         good: session.rotationCount <= level.parRotations)

                Spacer(minLength: 2)

                iconButton(enabled: session.canUndo) {
                    session.undo(); store.tapFeedback()
                } content: {
                    UndoArrowShape().stroke(Lab.ivory, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
                iconButton(enabled: true) {
                    session.reset(); store.tapFeedback()
                } content: {
                    ResetShape().stroke(Lab.ivory, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
                iconButton(enabled: true) {
                    useHint()
                } content: {
                    BulbShape().stroke(store.progress.hintTokensAvailable > 0 ? Lab.amber : Lab.dim,
                                       style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                }
                Button {
                    session.fineMode.toggle(); store.tapFeedback()
                } label: {
                    Text(session.fineMode ? "1°" : "5°")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(session.fineMode ? Lab.background : Lab.cyan)
                        .frame(width: 34, height: 30)
                        .contentShape(Rectangle())
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(session.fineMode ? Lab.cyan : Lab.panelRaised))
                }
                iconButton(enabled: true) {
                    showGoal.toggle(); store.tapFeedback()
                } content: {
                    TargetRingShape().stroke(Lab.cyan, lineWidth: 1.6)
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.top, 4)
    }

    private func statChip(title: String, value: String, good: Bool) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 7.5, weight: .bold, design: .rounded))
                .foregroundColor(Lab.dim).tracking(0.8)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(good ? Lab.ok : Lab.amber)
        }
        .frame(width: 52, height: 30)
        .background(RoundedRectangle(cornerRadius: 8).fill(Lab.panelRaised))
    }

    private func iconButton<C: View>(enabled: Bool, action: @escaping () -> Void,
                                     @ViewBuilder content: () -> C) -> some View {
        Button(action: { if enabled { action() } }) {
            content()
                .frame(width: 17, height: 17)
                .frame(width: 34, height: 30)
                .contentShape(Rectangle())
                .background(RoundedRectangle(cornerRadius: 8).fill(Lab.panelRaised))
                .opacity(enabled ? 1 : 0.35)
        }
    }

    // MARK: selection controls (also the guaranteed way to rotate without the dial)

    @ViewBuilder
    private var selectionControls: some View {
        if let sel = session.selection, session.placed.indices.contains(sel) {
            let rotatable = session.placed[sel].kind.rotatable
            HStack(spacing: 6) {
                if rotatable {
                    nudgeButton("−") { session.nudgeAngle(index: sel, by: session.fineMode ? -1 : -5) }
                    nudgeButton("+") { session.nudgeAngle(index: sel, by: session.fineMode ? 1 : 5) }
                    Text(String(format: "%.0f°", normalisedDegrees(session.placed[sel].angle)))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.amber)
                        .frame(minWidth: 30)
                }
                Button {
                    session.remove(index: sel); store.tapFeedback()
                } label: {
                    HStack(spacing: 4) {
                        CrossShape().stroke(Lab.danger, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                            .frame(width: 9, height: 9)
                        Text("Remove")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Lab.danger)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .background(Capsule().fill(Lab.danger.opacity(0.14)))
                }
            }
        }
    }

    private func nudgeButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            action(); store.tapFeedback()
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.cyan)
                .frame(width: 30, height: 26)
                .contentShape(Rectangle())
                .background(RoundedRectangle(cornerRadius: 7).fill(Lab.panelRaised))
        }
    }

    private func normalisedDegrees(_ radians: Double) -> Double {
        var d = (radians * 180 / .pi).truncatingRemainder(dividingBy: 360)
        if d < 0 { d += 360 }
        return d
    }

    // MARK: trays

    private func bottomTray(width: CGFloat, compact: Bool) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(session.selection != nil ? "Drag to move · ring to rotate" : "Tap a part, then tap the bench")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Lab.dim)
                    .lineLimit(1)
                Spacer(minLength: 4)
                selectionControls
            }
            .padding(.horizontal, 14)
            .frame(height: 28)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(level.inventory, id: \.self) { entry in
                        trayChip(entry, compact: compact)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity)
        .background(Lab.panel.opacity(0.9))
    }

    private func sideTray() -> some View {
        VStack(spacing: 6) {
            selectionControlsVertical
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(level.inventory, id: \.self) { entry in
                        trayChip(entry, compact: true)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Lab.panel.opacity(0.9))
    }

    @ViewBuilder
    private var selectionControlsVertical: some View {
        if let sel = session.selection, session.placed.indices.contains(sel) {
            let rotatable = session.placed[sel].kind.rotatable
            VStack(spacing: 5) {
                if rotatable {
                    HStack(spacing: 5) {
                        nudgeButton("−") { session.nudgeAngle(index: sel, by: session.fineMode ? -1 : -5) }
                        nudgeButton("+") { session.nudgeAngle(index: sel, by: session.fineMode ? 1 : 5) }
                    }
                    Text(String(format: "%.0f°", normalisedDegrees(session.placed[sel].angle)))
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.amber)
                }
                Button {
                    session.remove(index: sel); store.tapFeedback()
                } label: {
                    Text("Remove")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.danger)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .contentShape(Rectangle())
                        .background(Capsule().fill(Lab.danger.opacity(0.14)))
                }
            }
            .padding(.top, 8)
        }
    }

    private func trayChip(_ entry: InventoryEntry, compact: Bool) -> some View {
        let left = session.remaining(entry)
        let armed = session.armed == entry
        let side: CGFloat = compact ? 40 : 46
        return VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                ComponentGlyph(kind: entry.kind, band: entry.band, size: side,
                               angle: entry.kind == .flatMirror || entry.kind == .beamSplitter ? pblDeg(45) : 0,
                               colourBlind: store.progress.colourBlind)
                    .frame(width: side, height: side)
                Text("\(left)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(left > 0 ? Lab.background : Lab.muted)
                    .frame(width: 15, height: 15)
                    .background(Circle().fill(left > 0 ? Lab.cyan : Lab.hex(0x2A3352)))
                    .offset(x: 5, y: -3)
            }
            Text(entry.band.map { "\($0.letter) Filter" } ?? entry.kind.shortTitle)
                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                .foregroundColor(left > 0 ? Lab.ivory : Lab.dim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 62)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(armed ? Lab.cyan.opacity(0.18) : Lab.panelRaised)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(armed ? Lab.cyan : Color.clear, lineWidth: 1.5)))
        .opacity(left > 0 ? 1 : 0.4)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("bench"))
                .onChanged { value in
                    guard left > 0 else { return }
                    if abs(value.translation.width) > 6 || abs(value.translation.height) > 6 {
                        dragKind = entry
                        dragPoint = value.location
                    }
                }
                .onEnded { value in
                    defer { dragKind = nil }
                    guard left > 0 else { return }
                    let moved = abs(value.translation.width) > 6 || abs(value.translation.height) > 6
                    if moved {
                        if boardRect.contains(value.location) && boardRect.width > 1 {
                            let local = CGPoint(x: value.location.x - boardRect.minX,
                                                y: value.location.y - boardRect.minY)
                            let t = BenchTransform(benchSide: level.benchSide, boardSide: boardRect.width)
                            session.place(kind: entry.kind, band: entry.band, at: t.toBench(local))
                            session.armed = nil
                            store.placeFeedback()
                        }
                    } else {
                        session.armed = (session.armed == entry) ? nil : entry
                        session.selection = nil
                        store.tapFeedback()
                    }
                }
        )
    }

    // MARK: actions

    private func handleBoardTap(_ benchPoint: CGPoint) {
        if let entry = session.armed, session.remaining(entry) > 0 {
            session.place(kind: entry.kind, band: entry.band, at: benchPoint)
            if session.remaining(entry) == 0 { session.armed = nil }
            store.placeFeedback()
        } else {
            session.selection = nil
        }
    }

    private func useHint() {
        guard !session.evaluation.solved else {
            flash("Already solved.")
            return
        }
        guard let next = session.nextHintComponent() else {
            flash("Every reference part is already placed.")
            return
        }
        // Never charge a token for a hint that is already on the bench.
        if session.hintGhosts.contains(where: { $0.kind == next.kind && pblDist($0.position, next.position) < 1 }) {
            flash("That hint is already showing.")
            return
        }
        guard store.spendHint(levelID: level.id) else {
            flash("No hint tokens. Earn 1 for every 3 stars.")
            return
        }
        _ = session.revealHint()
        store.tapFeedback()
        flash("Hint revealed. \(store.progress.hintTokensAvailable) left.")
    }

    private func flash(_ text: String) {
        hintMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if hintMessage == text { hintMessage = nil }
        }
    }

    private func handleSolved() {
        let stars = session.starsEarned
        awardedStars = stars
        store.recordSolve(levelID: level.id, stars: stars,
                          components: session.componentsUsed,
                          rotations: session.rotationCount,
                          seconds: session.elapsedSeconds)
        store.successFeedback()
        withAnimation(.easeOut(duration: 0.25)) { showWin = true }
    }

    // MARK: overlays

    private func goalPanel(width: CGFloat, maxHeight: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Goal")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.ivory)
                Spacer()
                Button { showGoal = false } label: {
                    CrossShape().stroke(Lab.muted, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 12, height: 12)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
            }
            Text(level.brief)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(Lab.muted)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(level.receptors.enumerated()), id: \.offset) { i, r in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(session.evaluation.satisfied[safe: i] == true ? Lab.ok : Lab.hex(0x2A3352))
                        .frame(width: 9, height: 9)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(receptorTitle(r))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Lab.ivory)
                        Text(receptorDetail(r, index: i))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(Lab.dim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }

            Text("Stars:  1 solve  ·  2 use \(level.parComponents) parts or fewer  ·  3 also \(level.parRotations) rotations or fewer")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundColor(Lab.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: min(width - 32, 400), alignment: .leading)
        }
        .frame(width: min(width - 32, 400))
        .frame(maxHeight: max(160, maxHeight))
        .fixedSize(horizontal: false, vertical: true)
        .labCard(fill: Lab.hex(0x101731))
        .shadow(color: Color.black.opacity(0.5), radius: 16, y: 6)
        .padding(.top, 46)
    }

    private func receptorTitle(_ r: ReceptorSpec) -> String {
        if r.isWhiteTarget { return "White receptor" }
        if r.bands.count == 1 { return "\(r.bands[0].title) receptor" }
        return r.bands.map { $0.title }.joined(separator: " + ") + " receptor"
    }

    private func receptorDetail(_ r: ReceptorSpec, index: Int) -> String {
        var parts: [String] = [String(format: "needs %.2f intensity", r.minIntensity)]
        if r.pure { parts.append("rejects other colours") }
        if let pol = r.polarisation {
            parts.append(String(format: "polarised %.0f° ±12°", pol * 180 / .pi))
        }
        if let reading = session.evaluation.trace.readings[safe: index] {
            let got = r.bands.map { String(format: "%@ %.2f", $0.letter, reading.perBand[$0.rawValue]) }
                .joined(separator: "  ")
            parts.append("now: \(got)")
        }
        return parts.joined(separator: " · ")
    }

    private func winPanel(width: CGFloat) -> some View {
        VStack(spacing: 11) {
            Text("BEAM LOCKED")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.cyan).tracking(2)
            Text(level.name)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Lab.ivory)
                .lineLimit(1).minimumScaleFactor(0.7)

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    StarShape()
                        .fill(i < awardedStars ? Lab.amber : Lab.hex(0x232D4E))
                        .overlay(StarShape().stroke(i < awardedStars ? Lab.amber : Lab.hex(0x33406B), lineWidth: 1))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.vertical, 2)

            HStack(spacing: 16) {
                winStat("PARTS", "\(session.componentsUsed)", "par \(level.parComponents)")
                winStat("TURNS", "\(session.rotationCount)", "par \(level.parRotations)")
                winStat("TIME", timeString(session.elapsedSeconds), "")
            }

            HStack(spacing: 10) {
                Button {
                    showWin = false
                    store.tapFeedback()
                } label: {
                    Text("Keep Tinkering")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.cyan)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .contentShape(Rectangle())
                        .background(RoundedRectangle(cornerRadius: 10).fill(Lab.panelRaised))
                }
                Button {
                    showWin = false
                    store.tapFeedback()
                    store.openLevel(min(level.id + 1, LevelLibrary.count))
                } label: {
                    Text(level.id < LevelLibrary.count ? "Next Level" : "Finish")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.background)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .contentShape(Rectangle())
                        .background(RoundedRectangle(cornerRadius: 10).fill(Lab.cyan))
                }
            }
        }
        .padding(18)
        .frame(width: min(width - 40, 360))
        .labCard(fill: Lab.hex(0x101731))
        .shadow(color: Color.black.opacity(0.6), radius: 20, y: 8)
        .padding(.top, 60)
    }

    private func winStat(_ title: String, _ value: String, _ sub: String) -> some View {
        VStack(spacing: 1) {
            Text(title).font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(Lab.dim).tracking(1)
            Text(value).font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Lab.ivory)
            if !sub.isEmpty {
                Text(sub).font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundColor(Lab.dim)
            }
        }
        .frame(minWidth: 60)
    }

    private func timeString(_ s: Double) -> String {
        let total = Int(s.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
