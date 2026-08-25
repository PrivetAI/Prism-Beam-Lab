//  LevelBuilder.swift
//  Prism Beam Lab
//
//  Turns a compact, FORWARD-authored recipe into a playable level.
//
//  Authoring contract (BATCH_BRIEF §7.18): a recipe describes the intended optical PATH first
//  (emitter -> waypoints), the builder computes the component placements that realise it, then
//  the beam is traced and the receptors are sited where light actually lands. Nothing here
//  "undoes" a solved board, and `LevelAudit` asserts that the stripped board never already
//  satisfies the goal.

import Foundation
import CoreGraphics

// MARK: - Recipe DSL

public enum ChainStep {
    /// Reflective waypoint: the beam arrives here and leaves toward the next waypoint.
    case mirror(CGPoint)
    case lockedMirror(CGPoint)
    /// Reflects toward the next waypoint AND lets half the light carry straight on.
    case splitter(CGPoint)
    case lockedSplitter(CGPoint)
    /// Pass-through elements: the beam continues in a straight line.
    case filter(CGPoint, Band)
    case lockedFilter(CGPoint, Band)
    case polariser(CGPoint, Double)          // axis in degrees
    case lockedPolariser(CGPoint, Double)
    case amplifier(CGPoint)
    case lockedAmplifier(CGPoint)
    /// Lens that bends the beam toward the next waypoint (solved for its off-axis offset).
    case lens(CGPoint, Bool)                 // point, converging
    case lockedLens(CGPoint, Bool)
    /// Prism: fixed angle, terminates the exact chain. Receptors after it are discovered.
    case prism(CGPoint, Double)
    case lockedPrism(CGPoint, Double)
    /// Fibre portal pair: the beam enters at `a`, leaves at `b` with the same heading.
    case portal(CGPoint, CGPoint, Int)
    case lockedPortal(CGPoint, CGPoint, Int)
    /// Terminates the chain at a plain point (usually where a receptor goes).
    case finish(CGPoint)
}

/// How a receptor is positioned.
public enum ReceptorSite {
    /// Explicit bench coordinate — always a point the exact chain passes through.
    case at(CGPoint)
    /// Discovered: back off `d` units from the end of the `ordinal`-th terminal leg of `band`.
    case onBeam(Band, Int, Double)
}

public struct ReceptorRecipe {
    public let site: ReceptorSite
    public let bands: [Band]
    public let minIntensity: Double
    public let polarisationDeg: Double?
    public let pure: Bool
    public let radius: Double

    public init(_ site: ReceptorSite, bands: [Band], minIntensity: Double,
                polarisationDeg: Double? = nil, pure: Bool = false,
                radius: Double = Optics.defaultReceptorRadius) {
        self.site = site
        self.bands = bands
        self.minIntensity = minIntensity
        self.polarisationDeg = polarisationDeg
        self.pure = pure
        self.radius = radius
    }
}

/// A component placed on a beam leg that was DISCOVERED by tracing (used after a prism fan).
public struct BeamRoute {
    public let band: Band
    public let ordinal: Int
    public let distance: Double
    public let kind: ComponentKind
    public let toward: CGPoint?
    public let band2: Band?
    public let locked: Bool

    public init(band: Band, ordinal: Int = 0, distance: Double, kind: ComponentKind,
                toward: CGPoint? = nil, filterBand: Band? = nil, locked: Bool = false) {
        self.band = band
        self.ordinal = ordinal
        self.distance = distance
        self.kind = kind
        self.toward = toward
        self.band2 = filterBand
        self.locked = locked
    }
}

public struct LevelRecipe {
    public let id: Int
    public let chapter: Int
    public let name: String
    public let brief: String
    public let benchSide: Double
    public let emitters: [EmitterSpec]
    public let chain: [ChainStep]
    /// Extra passes of discovered routing (applied in order, re-tracing between passes).
    public let routes: [[BeamRoute]]
    public let obstacles: [PlacedComponent]
    /// Components placed by absolute coordinate rather than derived from the chain — used for
    /// parts that sit on a branch the chain does not walk (e.g. a splitter's straight-through arm).
    public let extras: [PlacedComponent]
    public let receptors: [ReceptorRecipe]
    /// Spare parts added to the tray beyond what the reference solution needs.
    public let spares: [(ComponentKind, Band?, Int)]

    public init(id: Int, chapter: Int, name: String, brief: String, benchSide: Double = 400,
                emitters: [EmitterSpec], chain: [ChainStep], routes: [[BeamRoute]] = [],
                obstacles: [PlacedComponent] = [], extras: [PlacedComponent] = [],
                receptors: [ReceptorRecipe],
                spares: [(ComponentKind, Band?, Int)] = []) {
        self.id = id
        self.chapter = chapter
        self.name = name
        self.brief = brief
        self.benchSide = benchSide
        self.emitters = emitters
        self.chain = chain
        self.routes = routes
        self.obstacles = obstacles
        self.extras = extras
        self.receptors = receptors
        self.spares = spares
    }
}

// MARK: - Built level

public struct InventoryEntry: Hashable {
    public let kind: ComponentKind
    public let band: Band?
    public let count: Int
    public init(kind: ComponentKind, band: Band?, count: Int) {
        self.kind = kind; self.band = band; self.count = count
    }
}

public struct LevelSpec {
    public let id: Int
    public let chapter: Int
    public let name: String
    public let brief: String
    public let benchSide: Double
    public let emitters: [EmitterSpec]
    public let receptors: [ReceptorSpec]
    public let fixed: [PlacedComponent]          // locked, on the board from the start
    public let inventory: [InventoryEntry]       // the player's tray
    public let solution: [PlacedComponent]       // reference solution (unlocked parts only)
    public let parComponents: Int
    public let parRotations: Int
    public let buildIssues: [String]             // non-empty means the recipe is broken

    public var allStartingComponents: [PlacedComponent] { fixed }
}

// MARK: - The builder

public enum LevelBuilder {

    public static func build(_ r: LevelRecipe) -> LevelSpec {
        var issues: [String] = []
        var placed: [PlacedComponent] = r.obstacles
        var solution: [PlacedComponent] = []
        for e in r.extras {
            placed.append(e)
            if !e.isLocked { solution.append(e) }
        }

        // --- Phase 1: realise the exact chain -------------------------------------------------
        guard let firstEmitter = r.emitters.first else {
            return degenerate(r, issues: ["no emitter"])
        }
        var cur = firstEmitter.position
        var dir = pblAngleVec(firstEmitter.angle)

        func waypoint(_ s: ChainStep) -> CGPoint? {
            switch s {
            case .mirror(let p), .lockedMirror(let p),
                 .splitter(let p), .lockedSplitter(let p),
                 .amplifier(let p), .lockedAmplifier(let p),
                 .prism(let p, _), .lockedPrism(let p, _),
                 .finish(let p):
                return p
            case .filter(let p, _), .lockedFilter(let p, _):
                return p
            case .polariser(let p, _), .lockedPolariser(let p, _):
                return p
            case .lens(let p, _), .lockedLens(let p, _):
                return p
            case .portal(let p, _, _), .lockedPortal(let p, _, _):
                return p
            }
        }

        for (i, step) in r.chain.enumerated() {
            guard let here = waypoint(step) else { continue }
            let dIn = pblNorm(pblVec(cur, here))
            if pblDist(cur, here) < 12 {
                issues.append("step \(i): waypoint too close to previous point")
            }
            // The next waypoint defines the outgoing direction for steering elements.
            let nextPoint: CGPoint? = (i + 1 < r.chain.count) ? waypoint(r.chain[i + 1]) : nil

            func addComponent(_ c: PlacedComponent) {
                placed.append(c)
                if !c.isLocked { solution.append(c) }
            }

            switch step {
            case .mirror, .lockedMirror, .splitter, .lockedSplitter:
                let locked: Bool
                let kind: ComponentKind
                switch step {
                case .mirror: locked = false; kind = .flatMirror
                case .lockedMirror: locked = true; kind = .flatMirror
                case .splitter: locked = false; kind = .beamSplitter
                default: locked = true; kind = .beamSplitter
                }
                guard let np = nextPoint else {
                    issues.append("step \(i): reflective step needs a following waypoint")
                    continue
                }
                let dOut = pblNorm(pblVec(here, np))
                let bis = CGVector(dx: dOut.dx - dIn.dx, dy: dOut.dy - dIn.dy)
                if (bis.dx * bis.dx + bis.dy * bis.dy).squareRoot() < 1e-6 {
                    issues.append("step \(i): reflective step cannot pass light straight through")
                    continue
                }
                let n = pblNorm(bis)
                let surface = atan2(Double(n.dy), Double(n.dx)) + .pi / 2
                addComponent(PlacedComponent(kind: kind, x: Double(here.x), y: Double(here.y),
                                             angle: surface, isLocked: locked))
                cur = here
                dir = dOut

            case .filter(let p, let b), .lockedFilter(let p, let b):
                var locked = false
                if case .lockedFilter = step { locked = true }
                let surface = atan2(Double(dIn.dy), Double(dIn.dx)) + .pi / 2
                addComponent(PlacedComponent(kind: .colourFilter, x: Double(p.x), y: Double(p.y),
                                             angle: surface, band: b, isLocked: locked))
                cur = here
                dir = dIn

            case .polariser(let p, let axisDeg), .lockedPolariser(let p, let axisDeg):
                var locked = false
                if case .lockedPolariser = step { locked = true }
                addComponent(PlacedComponent(kind: .polariser, x: Double(p.x), y: Double(p.y),
                                             angle: pblDeg(axisDeg), isLocked: locked))
                cur = here
                dir = dIn

            case .amplifier(let p), .lockedAmplifier(let p):
                var locked = false
                if case .lockedAmplifier = step { locked = true }
                let surface = atan2(Double(dIn.dy), Double(dIn.dx)) + .pi / 2
                addComponent(PlacedComponent(kind: .amplifier, x: Double(p.x), y: Double(p.y),
                                             angle: surface, isLocked: locked))
                cur = here
                dir = dIn

            case .lens(let p, let converging), .lockedLens(let p, let converging):
                var locked = false
                if case .lockedLens = step { locked = true }
                let f = converging ? Optics.focalLength : -Optics.focalLength
                let u = CGVector(dx: -dIn.dy, dy: dIn.dx)          // lens plane
                var h = 0.0
                var dOut = dIn
                if let np = nextPoint {
                    dOut = pblNorm(pblVec(p, np))
                    let delta = atan2(pblCross(dIn, dOut), pblDot(dIn, dOut))
                    h = -f * tan(delta)
                    if abs(h) > Optics.lensHalf - 4 {
                        issues.append(String(format: "step %d: lens deflection %.1f deg needs offset %.1f > aperture", i, delta * 180 / .pi, h))
                        h = max(-(Optics.lensHalf - 4), min(Optics.lensHalf - 4, h))
                    }
                }
                let centre = CGPoint(x: p.x - CGFloat(h) * u.dx, y: p.y - CGFloat(h) * u.dy)
                let surface = atan2(Double(u.dy), Double(u.dx))
                addComponent(PlacedComponent(kind: converging ? .convergingLens : .divergingLens,
                                             x: Double(centre.x), y: Double(centre.y),
                                             angle: surface, isLocked: locked))
                cur = p
                dir = dOut

            case .prism(let p, let a), .lockedPrism(let p, let a):
                var locked = false
                if case .lockedPrism = step { locked = true }
                addComponent(PlacedComponent(kind: .prism, x: Double(p.x), y: Double(p.y),
                                             angle: pblDeg(a), isLocked: locked))
                cur = p
                dir = dIn

            case .portal(let a, let b, let pid), .lockedPortal(let a, let b, let pid):
                var locked = false
                if case .lockedPortal = step { locked = true }
                addComponent(PlacedComponent(kind: .fibrePortal, x: Double(a.x), y: Double(a.y),
                                             pairID: pid, isLocked: locked))
                addComponent(PlacedComponent(kind: .fibrePortal, x: Double(b.x), y: Double(b.y),
                                             pairID: pid, isLocked: locked))
                cur = CGPoint(x: b.x + dIn.dx * CGFloat(Optics.portalRadius + 2),
                              y: b.y + dIn.dy * CGFloat(Optics.portalRadius + 2))
                dir = dIn

            case .finish:
                cur = here
                dir = dIn
            }
        }
        _ = dir

        // --- Phase 2: discovered routing passes ----------------------------------------------
        for pass in r.routes {
            let probe = OpticsEngine.trace(benchSide: r.benchSide, emitters: r.emitters,
                                           components: placed, receptors: [],
                                           collectSegments: false, collectTerminals: true)
            let sorted = sortTerminals(probe.terminals)
            for route in pass {
                guard let leg = pick(sorted, band: route.band, ordinal: route.ordinal) else {
                    issues.append("route: no terminal for band \(route.band.letter) ordinal \(route.ordinal)")
                    continue
                }
                let legLength = pblDist(leg.start, leg.point)
                if route.distance > legLength - 6 {
                    issues.append(String(format: "route: distance %.0f exceeds leg length %.0f for band %@",
                                         route.distance, legLength, leg.band.letter))
                }
                let at = CGPoint(x: leg.start.x + leg.direction.dx * CGFloat(route.distance),
                                 y: leg.start.y + leg.direction.dy * CGFloat(route.distance))
                var angle = atan2(Double(leg.direction.dy), Double(leg.direction.dx)) + .pi / 2
                if route.kind == .flatMirror || route.kind == .beamSplitter {
                    guard let toward = route.toward else {
                        issues.append("route: reflective route needs a `toward` point")
                        continue
                    }
                    let dOut = pblNorm(pblVec(at, toward))
                    let bis = CGVector(dx: dOut.dx - leg.direction.dx, dy: dOut.dy - leg.direction.dy)
                    if (bis.dx * bis.dx + bis.dy * bis.dy).squareRoot() < 1e-6 {
                        issues.append("route: reflective route is a straight-through")
                        continue
                    }
                    let n = pblNorm(bis)
                    angle = atan2(Double(n.dy), Double(n.dx)) + .pi / 2
                }
                let c = PlacedComponent(kind: route.kind, x: Double(at.x), y: Double(at.y),
                                        angle: angle, band: route.band2, isLocked: route.locked)
                placed.append(c)
                if !route.locked { solution.append(c) }
            }
        }

        // --- Phase 3: site the receptors -----------------------------------------------------
        let probe = OpticsEngine.trace(benchSide: r.benchSide, emitters: r.emitters,
                                       components: placed, receptors: [],
                                       collectSegments: false, collectTerminals: true)
        let sortedTerminals = sortTerminals(probe.terminals)
        var receptors: [ReceptorSpec] = []
        for rec in r.receptors {
            var pos: CGPoint
            switch rec.site {
            case .at(let p):
                pos = p
            case .onBeam(let band, let ordinal, let backoff):
                guard let leg = pick(sortedTerminals, band: band, ordinal: ordinal) else {
                    issues.append("receptor: no terminal for band \(band.letter) ordinal \(ordinal)")
                    pos = CGPoint(x: r.benchSide / 2, y: r.benchSide / 2)
                    break
                }
                let legLength = pblDist(leg.start, leg.point)
                let d = max(10.0, min(legLength - 4, legLength - backoff))
                pos = CGPoint(x: leg.start.x + leg.direction.dx * CGFloat(d),
                              y: leg.start.y + leg.direction.dy * CGFloat(d))
            }
            receptors.append(ReceptorSpec(x: Double(pos.x), y: Double(pos.y),
                                          bands: rec.bands, minIntensity: rec.minIntensity,
                                          polarisation: rec.polarisationDeg.map { OpticsEngine.normalisedAxis(pblDeg($0)) },
                                          pure: rec.pure, radius: rec.radius))
        }

        // --- Phase 4: inventory ---------------------------------------------------------------
        var counts: [InventoryEntry: Int] = [:]
        var order: [InventoryEntry] = []
        func bump(_ kind: ComponentKind, _ band: Band?, _ n: Int) {
            let key = InventoryEntry(kind: kind, band: band, count: 0)
            if counts[key] == nil { order.append(key) }
            counts[key, default: 0] += n
        }
        for c in solution {
            bump(c.kind, c.band, 1)
        }
        for s in r.spares { bump(s.0, s.1, s.2) }
        // Portals were emitted as two components; the tray shows them individually.
        let inventory = order.map { InventoryEntry(kind: $0.kind, band: $0.band, count: counts[$0] ?? 0) }

        let parComponents = solution.count
        let parRotations = max(3, solution.reduce(0) { $0 + ($1.kind.rotatable ? 2 : 0) } + 2)

        let fixed = placed.filter { $0.isLocked }

        return LevelSpec(id: r.id, chapter: r.chapter, name: r.name, brief: r.brief,
                         benchSide: r.benchSide, emitters: r.emitters, receptors: receptors,
                         fixed: fixed, inventory: inventory, solution: solution,
                         parComponents: parComponents, parRotations: parRotations,
                         buildIssues: issues)
    }

    private static func degenerate(_ r: LevelRecipe, issues: [String]) -> LevelSpec {
        LevelSpec(id: r.id, chapter: r.chapter, name: r.name, brief: r.brief, benchSide: r.benchSide,
                  emitters: r.emitters, receptors: [], fixed: [], inventory: [], solution: [],
                  parComponents: 0, parRotations: 0, buildIssues: issues)
    }

    /// Deterministic terminal ordering so `ordinal` selectors are stable.
    static func sortTerminals(_ ts: [BeamTerminal]) -> [BeamTerminal] {
        ts.sorted { a, b in
            if a.band.rawValue != b.band.rawValue { return a.band.rawValue < b.band.rawValue }
            if abs(a.intensity - b.intensity) > 1e-9 { return a.intensity > b.intensity }
            if abs(Double(a.point.x - b.point.x)) > 1e-9 { return a.point.x < b.point.x }
            return a.point.y < b.point.y
        }
    }

    static func pick(_ ts: [BeamTerminal], band: Band, ordinal: Int) -> BeamTerminal? {
        let filtered = ts.filter { $0.band == band }
        guard ordinal >= 0 && ordinal < filtered.count else { return nil }
        return filtered[ordinal]
    }
}

// MARK: - Convenience

public func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
