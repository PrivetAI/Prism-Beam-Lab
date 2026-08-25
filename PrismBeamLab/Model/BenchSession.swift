//  BenchSession.swift
//  Prism Beam Lab
//
//  Mutable state for one bench: what the player has placed, the live trace, undo history,
//  star bookkeeping and hints.

import SwiftUI
import CoreGraphics

final class BenchSession: ObservableObject {

    let level: LevelSpec
    let isSandbox: Bool

    @Published private(set) var placed: [PlacedComponent] = []
    @Published var selection: Int? = nil
    @Published private(set) var evaluation: BoardEvaluation
    @Published private(set) var rotationCount: Int = 0
    @Published var hintGhosts: [PlacedComponent] = []
    @Published var fineMode: Bool = false
    @Published var armed: InventoryEntry? = nil

    /// Sandbox-only: the movable emitter.
    @Published var sandboxEmitter: EmitterSpec

    private var undoStack: [[PlacedComponent]] = []
    private(set) var startedAt = Date()

    init(level: LevelSpec, isSandbox: Bool = false, fineDefault: Bool = false,
         initialPlaced: [PlacedComponent] = [], emitter: EmitterSpec? = nil) {
        self.level = level
        self.isSandbox = isSandbox
        self.placed = initialPlaced
        self.fineMode = fineDefault
        self.sandboxEmitter = emitter ?? level.emitters.first
            ?? EmitterSpec(x: 20, y: 200, angle: 0)
        self.evaluation = BoardEvaluation(trace: TraceResult(), satisfied: [], solved: false, usedComponents: 0)
        recompute()
    }

    // MARK: derived

    var emitters: [EmitterSpec] {
        isSandbox ? [sandboxEmitter] : level.emitters
    }

    var receptors: [ReceptorSpec] {
        if isSandbox {
            return placed.filter { $0.kind == .receptor }.map {
                ReceptorSpec(x: $0.x, y: $0.y, bands: [.red, .green, .blue], minIntensity: 0.15)
            }
        }
        return level.receptors
    }

    var componentsUsed: Int { placed.count }

    func remaining(_ entry: InventoryEntry) -> Int {
        if isSandbox { return 99 }
        let used = placed.filter { $0.kind == entry.kind && $0.band == entry.band }.count
        return max(0, entry.count - used)
    }

    var starsEarned: Int {
        guard evaluation.solved else { return 0 }
        var s = 1
        if placed.count <= level.parComponents { s += 1 }
        if placed.count <= level.parComponents && rotationCount <= level.parRotations { s += 1 }
        return s
    }

    var elapsedSeconds: Double { Date().timeIntervalSince(startedAt) }

    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: trace

    func recompute() {
        let all = level.fixed + placed.filter { $0.kind != .receptor || !isSandbox }
        let trace = OpticsEngine.trace(benchSide: level.benchSide,
                                       emitters: emitters,
                                       components: all,
                                       receptors: receptors,
                                       collectSegments: true)
        let specs = receptors
        var flags: [Bool] = []
        for (i, spec) in specs.enumerated() { flags.append(trace.isSatisfied(i, spec)) }
        let nowSolved = !flags.isEmpty && !flags.contains(false)
        evaluation = BoardEvaluation(trace: trace, satisfied: flags,
                                     solved: nowSolved, usedComponents: placed.count)
    }

    // MARK: editing

    private func pushUndo() {
        undoStack.append(placed)
        if undoStack.count > 40 { undoStack.removeFirst() }
    }

    func snapshotForDrag() { pushUndo() }

    @discardableResult
    func place(kind: ComponentKind, band: Band?, at point: CGPoint) -> Bool {
        let margin = 14.0
        let x = min(max(margin, Double(point.x)), level.benchSide - margin)
        let y = min(max(margin, Double(point.y)), level.benchSide - margin)
        pushUndo()
        var pair: Int? = nil
        if kind == .fibrePortal {
            let existing = placed.filter { $0.kind == .fibrePortal }.count
            pair = existing / 2
        }
        let defaultAngle: Double = {
            switch kind {
            case .flatMirror, .beamSplitter: return pblDeg(45)
            case .convergingLens, .divergingLens: return pblDeg(90)
            case .polariser: return 0
            default: return 0
            }
        }()
        placed.append(PlacedComponent(kind: kind, x: x, y: y, angle: defaultAngle,
                                      band: band, pairID: pair, isLocked: false))
        selection = placed.count - 1
        recompute()
        return true
    }

    func move(index: Int, to point: CGPoint) {
        guard placed.indices.contains(index) else { return }
        let margin = 10.0
        placed[index].x = min(max(margin, Double(point.x)), level.benchSide - margin)
        placed[index].y = min(max(margin, Double(point.y)), level.benchSide - margin)
        recompute()
    }

    func setAngle(index: Int, radians: Double) {
        guard placed.indices.contains(index) else { return }
        let step = fineMode ? 1.0 : 5.0
        var deg = radians * 180 / .pi
        deg = (deg / step).rounded() * step
        placed[index].angle = pblDeg(deg)
        recompute()
    }

    func nudgeAngle(index: Int, by degrees: Double) {
        guard placed.indices.contains(index) else { return }
        pushUndo()
        placed[index].angle += pblDeg(degrees)
        rotationCount += 1
        recompute()
    }

    func beginRotate(index: Int) {
        guard placed.indices.contains(index) else { return }
        pushUndo()
    }

    func endRotate() {
        rotationCount += 1
    }

    func remove(index: Int) {
        guard placed.indices.contains(index) else { return }
        pushUndo()
        placed.remove(at: index)
        selection = nil
        // Portals renumber so pairs stay consistent.
        var portalIndex = 0
        for i in placed.indices where placed[i].kind == .fibrePortal {
            placed[i].pairID = portalIndex / 2
            portalIndex += 1
        }
        recompute()
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        placed = last
        selection = nil
        recompute()
    }

    func reset() {
        pushUndo()
        placed = []
        selection = nil
        hintGhosts = []
        rotationCount = 0
        startedAt = Date()
        recompute()
    }

    func loadSandbox(_ slot: SandboxSlot) {
        pushUndo()
        placed = slot.components
        sandboxEmitter = slot.emitter
        selection = nil
        recompute()
    }

    // MARK: hints

    /// Reveals the earliest reference component that is not yet correctly placed.
    func nextHintComponent() -> PlacedComponent? {
        for ref in level.solution {
            let matched = placed.contains { c in
                c.kind == ref.kind && c.band == ref.band &&
                pblDist(c.position, ref.position) < 26 &&
                (!c.kind.rotatable || pblAxisDelta(c.angle, ref.angle) < pblDeg(9))
            }
            if !matched { return ref }
        }
        return nil
    }

    func revealHint() -> Bool {
        guard let ghost = nextHintComponent() else { return false }
        if hintGhosts.contains(where: { pblDist($0.position, ghost.position) < 1 && $0.kind == ghost.kind }) {
            return false
        }
        hintGhosts.append(ghost)
        return true
    }
}
