//  SandboxView.swift
//  Prism Beam Lab
//
//  Free bench: every component, unlimited counts, a movable emitter and six save slots.

import SwiftUI

private let sandboxBenchSide: Double = 400

private func makeSandboxLevel() -> LevelSpec {
    LevelSpec(id: 0, chapter: 0, name: "Free Bench", brief: "Build anything.",
              benchSide: sandboxBenchSide,
              emitters: [EmitterSpec(x: 16, y: 200, angle: 0)],
              receptors: [], fixed: [],
              inventory: sandboxInventory, solution: [],
              parComponents: 0, parRotations: 0, buildIssues: [])
}

private let sandboxInventory: [InventoryEntry] = [
    InventoryEntry(kind: .flatMirror, band: nil, count: 99),
    InventoryEntry(kind: .prism, band: nil, count: 99),
    InventoryEntry(kind: .convergingLens, band: nil, count: 99),
    InventoryEntry(kind: .divergingLens, band: nil, count: 99),
    InventoryEntry(kind: .beamSplitter, band: nil, count: 99),
    InventoryEntry(kind: .colourFilter, band: .red, count: 99),
    InventoryEntry(kind: .colourFilter, band: .green, count: 99),
    InventoryEntry(kind: .colourFilter, band: .blue, count: 99),
    InventoryEntry(kind: .polariser, band: nil, count: 99),
    InventoryEntry(kind: .amplifier, band: nil, count: 99),
    InventoryEntry(kind: .fibrePortal, band: nil, count: 99),
    InventoryEntry(kind: .absorber, band: nil, count: 99),
    InventoryEntry(kind: .receptor, band: nil, count: 99)
]

struct SandboxView: View {
    @EnvironmentObject var store: LabStore
    @StateObject private var session = BenchSession(level: makeSandboxLevel(), isSandbox: true)

    @State private var boardRect: CGRect = .zero
    @State private var movingEmitter = false
    @State private var showSlots = false
    @State private var toast: String? = nil

    var body: some View {
        Group {
            if store.progress.sandboxUnlocked {
                bench
            } else {
                locked
            }
        }
        .background(Lab.background.ignoresSafeArea())
    }

    private var locked: some View {
        VStack(spacing: 14) {
            LockShape().stroke(Lab.dim, lineWidth: 2)
                .frame(width: 42, height: 48)
            Text("Free Bench Locked")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(Lab.ivory)
            Text("Finish Chapter 2, or earn 25 stars, and the sandbox opens with every component unlocked and no limits.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(Lab.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 34)
            Text("\(store.progress.totalStars) / 25 stars")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Lab.amber)
            Button {
                store.tab = 1
            } label: {
                Text("Open Chapters")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.background)
                    .padding(.horizontal, 22).frame(height: 40)
                    .contentShape(Rectangle())
                    .background(RoundedRectangle(cornerRadius: 10).fill(Lab.cyan))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bench: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let landscape = geo.size.width > geo.size.height
            let compact = landscape || geo.size.height < 610
            let headerH: CGFloat = landscape ? 74 : (compact ? 76 : 86)

            ZStack(alignment: .top) {
                if landscape {
                    let boardSide = max(90, min(width - 118, geo.size.height - headerH - 10))
                    VStack(spacing: 0) {
                        header(width: width).frame(height: headerH)
                        HStack(spacing: 0) {
                            ZStack {
                                BenchBoard(session: session, boardSide: boardSide,
                                           colourBlind: store.progress.colourBlind,
                                           beamLabels: store.progress.showBeamLabels,
                                           onPlaceRequest: handleTap,
                                           onFeedback: { store.tapFeedback() })
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            sideTray().frame(width: 96)
                        }
                    }
                    .frame(width: width, height: geo.size.height)
                } else {
                    let trayH: CGFloat = compact ? 96 : 108
                    let availableH = max(80, geo.size.height - headerH - trayH - 10)
                    let boardSide = max(90, min(width - 24, availableH))
                    VStack(spacing: 0) {
                        header(width: width).frame(height: headerH)
                        ZStack {
                            BenchBoard(session: session, boardSide: boardSide,
                                       colourBlind: store.progress.colourBlind,
                                       beamLabels: store.progress.showBeamLabels,
                                       onPlaceRequest: handleTap,
                                       onFeedback: { store.tapFeedback() })
                        }
                        .frame(width: width, height: availableH)
                        tray(width: width, compact: compact).frame(height: trayH)
                    }
                    .frame(width: width)
                }

                if showSlots { slotsPanel(width: width, maxHeight: geo.size.height - 60) }

                if let t = toast {
                    Text(t)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Lab.background)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(Lab.amber))
                        .padding(.top, 6)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .coordinateSpace(name: "bench")
            .onPreferenceChange(BoardRectKey.self) { boardRect = $0 }
        }
    }

    // MARK: header

    private func header(width: CGFloat) -> some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("FREE BENCH")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(Lab.dim).tracking(1.6)
                    Text("\(session.placed.count) parts placed")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.ivory)
                }
                Spacer()
                smallButton("Slots") { showSlots.toggle(); store.tapFeedback() }
                smallButton("Undo", enabled: session.canUndo) { session.undo(); store.tapFeedback() }
                smallButton("Clear") { session.reset(); store.tapFeedback() }
            }
            .padding(.horizontal, 14)

            HStack(spacing: 7) {
                Button {
                    movingEmitter.toggle()
                    session.armed = nil
                    store.tapFeedback()
                } label: {
                    Text(movingEmitter ? "Tap bench to move lamp" : "Move Lamp")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(movingEmitter ? Lab.background : Lab.cyan)
                        .padding(.horizontal, 10).frame(height: 28)
                        .contentShape(Rectangle())
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(movingEmitter ? Lab.cyan : Lab.panelRaised))
                }
                Button { rotateEmitter(-5) } label: { rotLabel("−5°") }
                Button { rotateEmitter(5) } label: { rotLabel("+5°") }
                Button { cycleBand() } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(session.sandboxEmitter.band.map { Lab.beam($0) } ?? Lab.beamWhite)
                            .frame(width: 11, height: 11)
                        Text(session.sandboxEmitter.band?.title ?? "White")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Lab.ivory)
                    }
                    .padding(.horizontal, 10).frame(height: 28)
                    .contentShape(Rectangle())
                    .background(RoundedRectangle(cornerRadius: 8).fill(Lab.panelRaised))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
        }
        .padding(.top, 4)
    }

    private func rotLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Lab.cyan)
            .frame(width: 42, height: 28)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 8).fill(Lab.panelRaised))
    }

    private func smallButton(_ title: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Lab.cyan)
                .padding(.horizontal, 11).frame(height: 28)
                .contentShape(Rectangle())
                .background(RoundedRectangle(cornerRadius: 8).fill(Lab.panelRaised))
                .opacity(enabled ? 1 : 0.4)
        }
    }

    // MARK: tray

    private func tray(width: CGFloat, compact: Bool) -> some View {
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
                    ForEach(sandboxInventory, id: \.self) { entry in
                        chip(entry, compact: compact)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity)
        .background(Lab.panel.opacity(0.85))
    }

    private func chip(_ entry: InventoryEntry, compact: Bool) -> some View {
        let armed = session.armed == entry
        let side: CGFloat = compact ? 40 : 46
        return VStack(spacing: 2) {
            ComponentGlyph(kind: entry.kind, band: entry.band, size: side,
                           angle: entry.kind == .flatMirror || entry.kind == .beamSplitter ? pblDeg(45) : 0,
                           colourBlind: store.progress.colourBlind)
                .frame(width: side, height: side)
            Text(entry.band.map { "\($0.letter) Filter" } ?? entry.kind.shortTitle)
                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                .foregroundColor(Lab.ivory)
                .lineLimit(1)
        }
        .frame(width: 62)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(armed ? Lab.cyan.opacity(0.18) : Lab.panelRaised)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(armed ? Lab.cyan : Color.clear, lineWidth: 1.5)))
        .contentShape(Rectangle())
        .onTapGesture {
            movingEmitter = false
            session.armed = armed ? nil : entry
            session.selection = nil
            store.tapFeedback()
        }
    }

    private func sideTray() -> some View {
        VStack(spacing: 6) {
            selectionControlsVertical
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(sandboxInventory, id: \.self) { entry in
                        chip(entry, compact: true)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Lab.panel.opacity(0.9))
    }

    @ViewBuilder
    private var selectionControls: some View {
        if let sel = session.selection, session.placed.indices.contains(sel) {
            HStack(spacing: 6) {
                if session.placed[sel].kind.rotatable {
                    nudgeButton("−") { session.nudgeAngle(index: sel, by: session.fineMode ? -1 : -5) }
                    nudgeButton("+") { session.nudgeAngle(index: sel, by: session.fineMode ? 1 : 5) }
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
        }
    }

    @ViewBuilder
    private var selectionControlsVertical: some View {
        if let sel = session.selection, session.placed.indices.contains(sel) {
            VStack(spacing: 5) {
                if session.placed[sel].kind.rotatable {
                    HStack(spacing: 5) {
                        nudgeButton("−") { session.nudgeAngle(index: sel, by: session.fineMode ? -1 : -5) }
                        nudgeButton("+") { session.nudgeAngle(index: sel, by: session.fineMode ? 1 : 5) }
                    }
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

    // MARK: actions

    private func handleTap(_ point: CGPoint) {
        if movingEmitter {
            let clamped = CGPoint(x: min(max(12, point.x), CGFloat(sandboxBenchSide) - 12),
                                  y: min(max(12, point.y), CGFloat(sandboxBenchSide) - 12))
            session.sandboxEmitter = EmitterSpec(x: Double(clamped.x), y: Double(clamped.y),
                                                 angle: session.sandboxEmitter.angle,
                                                 band: session.sandboxEmitter.band,
                                                 polarisation: session.sandboxEmitter.polarisation)
            session.recompute()
            movingEmitter = false
            store.placeFeedback()
            return
        }
        if let entry = session.armed {
            session.place(kind: entry.kind, band: entry.band, at: point)
            store.placeFeedback()
        } else {
            session.selection = nil
        }
    }

    private func rotateEmitter(_ degrees: Double) {
        var e = session.sandboxEmitter
        e = EmitterSpec(x: e.x, y: e.y, angle: e.angle + pblDeg(degrees), band: e.band, polarisation: e.polarisation)
        session.sandboxEmitter = e
        session.recompute()
        store.tapFeedback()
    }

    private func cycleBand() {
        let e = session.sandboxEmitter
        let next: Band?
        switch e.band {
        case nil: next = .red
        case .some(.red): next = .green
        case .some(.green): next = .blue
        case .some(.blue): next = nil
        }
        session.sandboxEmitter = EmitterSpec(x: e.x, y: e.y, angle: e.angle, band: next, polarisation: e.polarisation)
        session.recompute()
        store.tapFeedback()
    }

    private func flash(_ s: String) {
        toast = s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if toast == s { toast = nil }
        }
    }

    // MARK: slots

    private func slotsPanel(width: CGFloat, maxHeight: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Save Slots")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.ivory)
                Spacer()
                Button { showSlots = false } label: {
                    CrossShape().stroke(Lab.muted, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 12, height: 12).frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
            }
            ForEach(0..<PrismProgress.slotCount, id: \.self) { i in
                slotRow(i)
            }
        }
        .padding(16)
        .frame(width: min(width - 32, 400), alignment: .leading)
        }
        .frame(width: min(width - 32, 400))
        .frame(maxHeight: max(160, maxHeight))
        .fixedSize(horizontal: false, vertical: true)
        .labCard(fill: Lab.hex(0x101731))
        .shadow(color: Color.black.opacity(0.5), radius: 16, y: 6)
        .padding(.top, 44)
    }

    private func slotRow(_ i: Int) -> some View {
        let slot = store.progress.sandboxSlots[safe: i] ?? SandboxSlot()
        let used = slot.savedAt > 0
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Slot \(i + 1)")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.ivory)
                Text(used ? "\(slot.components.count) parts" : "empty")
                    .font(.system(size: 10.5, weight: .regular, design: .rounded))
                    .foregroundColor(Lab.dim)
            }
            Spacer()
            Button {
                var s = SandboxSlot()
                s.name = "Slot \(i + 1)"
                s.components = session.placed
                s.emitterX = session.sandboxEmitter.x
                s.emitterY = session.sandboxEmitter.y
                s.emitterAngle = session.sandboxEmitter.angle
                s.emitterBandRaw = session.sandboxEmitter.band?.rawValue ?? -1
                s.savedAt = Date().timeIntervalSince1970
                if store.progress.sandboxSlots.indices.contains(i) {
                    store.progress.sandboxSlots[i] = s
                    store.saveNow()
                }
                store.tapFeedback()
                flash("Saved to slot \(i + 1)")
            } label: { slotButton("Save", Lab.cyan) }

            Button {
                guard used else { return }
                session.loadSandbox(slot)
                store.tapFeedback()
                flash("Loaded slot \(i + 1)")
                showSlots = false
            } label: { slotButton("Load", used ? Lab.ok : Lab.dim) }
                .disabled(!used)

            Button {
                guard used else { return }
                if store.progress.sandboxSlots.indices.contains(i) {
                    store.progress.sandboxSlots[i] = SandboxSlot()
                    store.saveNow()
                }
                store.tapFeedback()
            } label: { slotButton("Clear", used ? Lab.danger : Lab.dim) }
                .disabled(!used)
        }
        .padding(.vertical, 4)
    }

    private func slotButton(_ title: String, _ colour: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(colour)
            .frame(width: 50, height: 28)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 8).fill(colour.opacity(0.14)))
    }
}
