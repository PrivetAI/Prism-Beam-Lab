//  OpticsEngine.swift
//  Prism Beam Lab
//
//  Pure-Swift, UIKit-free ray optics core. This file is compiled BOTH into the app and
//  into the headless audit binary (plain `swiftc`), so it must never import SwiftUI/UIKit.

import Foundation
import CoreGraphics

// MARK: - Bands

public enum Band: Int, Codable, CaseIterable, Hashable {
    case red = 0
    case green = 1
    case blue = 2

    public var letter: String {
        switch self {
        case .red: return "R"
        case .green: return "G"
        case .blue: return "B"
        }
    }

    public var title: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        }
    }

    /// Nominal wavelength in nanometres — used for Codex copy only.
    public var nanometres: Int {
        switch self {
        case .red: return 660
        case .green: return 540
        case .blue: return 450
        }
    }
}

// MARK: - Component kinds

public enum ComponentKind: Int, Codable, CaseIterable, Hashable {
    case flatMirror = 0
    case prism = 1
    case convergingLens = 2
    case divergingLens = 3
    case colourFilter = 4
    case beamSplitter = 5
    case polariser = 6
    case amplifier = 7
    case fibrePortal = 8
    case absorber = 9
    case receptor = 10

    public var title: String {
        switch self {
        case .flatMirror: return "Flat Mirror"
        case .prism: return "Prism"
        case .convergingLens: return "Converging Lens"
        case .divergingLens: return "Diverging Lens"
        case .colourFilter: return "Colour Filter"
        case .beamSplitter: return "Beam Splitter"
        case .polariser: return "Polariser"
        case .amplifier: return "Amplifier Crystal"
        case .fibrePortal: return "Fibre Portal"
        case .absorber: return "Absorber Block"
        case .receptor: return "Receptor"
        }
    }

    public var shortTitle: String {
        switch self {
        case .flatMirror: return "Mirror"
        case .prism: return "Prism"
        case .convergingLens: return "Conv Lens"
        case .divergingLens: return "Div Lens"
        case .colourFilter: return "Filter"
        case .beamSplitter: return "Splitter"
        case .polariser: return "Polariser"
        case .amplifier: return "Amplifier"
        case .fibrePortal: return "Portal"
        case .absorber: return "Absorber"
        case .receptor: return "Receptor"
        }
    }

    public var blurb: String {
        switch self {
        case .flatMirror: return "Reflects a beam. Angle in equals angle out."
        case .prism: return "Refracts each colour by a different amount. Splits white light."
        case .convergingLens: return "Bends off-axis rays toward the optical axis."
        case .divergingLens: return "Bends off-axis rays away from the optical axis."
        case .colourFilter: return "Passes one colour band, absorbs the rest."
        case .beamSplitter: return "Half the light reflects, half passes straight through."
        case .polariser: return "Attenuates by Malus's law and re-polarises the beam."
        case .amplifier: return "Boosts a beam once. A beam can never be amplified twice."
        case .fibrePortal: return "Paired portals: light entering one leaves the other."
        case .absorber: return "Swallows any beam that touches it."
        case .receptor: return "The target. Needs the right colour, intensity and angle."
        }
    }

    /// Whether the component's rotation matters to the player.
    public var rotatable: Bool {
        switch self {
        case .fibrePortal, .absorber, .receptor, .amplifier, .colourFilter: return false
        default: return true
        }
    }
}

// MARK: - Tunables

public enum Optics {
    /// Half-length of the flat bar style components (mirror, filter, splitter, polariser, lens).
    public static let mirrorHalf: Double = 32.0        // mirror bar length 64
    public static let lensHalf: Double = 36.0          // lens aperture 72
    public static let splitterHalf: Double = 32.0
    /// Round elements — orientation does not change how the beam meets them.
    public static let filterRadius: Double = 20.0
    public static let polariserRadius: Double = 22.0
    public static let amplifierRadius: Double = 20.0
    public static let prismSide: Double = 72.0
    public static let portalRadius: Double = 15.0
    public static let absorberHalf: Double = 21.0      // 42 x 42 block
    public static let defaultReceptorRadius: Double = 13.0

    public static let focalLength: Double = 140.0

    // Interaction losses
    public static let mirrorLoss: Double = 0.98
    public static let filterPass: Double = 0.95
    public static let splitterShare: Double = 0.5
    public static let prismSurfaceLoss: Double = 0.98
    public static let lensLoss: Double = 0.93
    public static let portalLoss: Double = 0.90
    public static let amplifierGain: Double = 1.8

    /// Free-space intensity falloff: I *= exp(-distance / falloffLength)
    public static let falloffLength: Double = 1400.0

    // Termination
    public static let minIntensity: Double = 0.02
    public static let maxBounces: Int = 48
    public static let maxSegments: Int = 400

    public static let polarisationTolerance: Double = 12.0 * .pi / 180.0

    /// Highly dispersive lab glass. Deliberately wider than crown glass so the rainbow
    /// fan separates at bench scale (see Codex entry "Refractive Index").
    public static func refractiveIndex(_ band: Band) -> Double {
        switch band {
        case .red: return 1.500
        case .green: return 1.560
        case .blue: return 1.640
        }
    }
}

// MARK: - Small vector helpers

@inline(__always) public func pblDot(_ a: CGVector, _ b: CGVector) -> Double {
    Double(a.dx * b.dx + a.dy * b.dy)
}

@inline(__always) public func pblCross(_ a: CGVector, _ b: CGVector) -> Double {
    Double(a.dx * b.dy - a.dy * b.dx)
}

@inline(__always) public func pblNorm(_ v: CGVector) -> CGVector {
    let l = (v.dx * v.dx + v.dy * v.dy).squareRoot()
    if l < 1e-12 { return CGVector(dx: 1, dy: 0) }
    return CGVector(dx: v.dx / l, dy: v.dy / l)
}

@inline(__always) public func pblVec(_ a: CGPoint, _ b: CGPoint) -> CGVector {
    CGVector(dx: b.x - a.x, dy: b.y - a.y)
}

@inline(__always) public func pblDist(_ a: CGPoint, _ b: CGPoint) -> Double {
    let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
    return (dx * dx + dy * dy).squareRoot()
}

@inline(__always) public func pblAngleVec(_ radians: Double) -> CGVector {
    CGVector(dx: CGFloat(cos(radians)), dy: CGFloat(sin(radians)))
}

@inline(__always) public func pblDeg(_ d: Double) -> Double { d * .pi / 180.0 }

/// Smallest absolute difference between two angles, modulo pi (axis-like comparison).
public func pblAxisDelta(_ a: Double, _ b: Double) -> Double {
    var d = (a - b).truncatingRemainder(dividingBy: .pi)
    if d > .pi / 2 { d -= .pi }
    if d < -.pi / 2 { d += .pi }
    return abs(d)
}

/// Smallest absolute difference between two headings, modulo 2*pi.
public func pblHeadingDelta(_ a: Double, _ b: Double) -> Double {
    var d = (a - b).truncatingRemainder(dividingBy: 2 * .pi)
    if d > .pi { d -= 2 * .pi }
    if d < -(.pi) { d += 2 * .pi }
    return abs(d)
}

// MARK: - Placed component

public struct PlacedComponent: Codable, Hashable {
    public var kind: ComponentKind
    public var x: Double
    public var y: Double
    public var angle: Double          // radians
    public var band: Band?            // colour filters
    public var pairID: Int?           // fibre portals
    public var isLocked: Bool

    public init(kind: ComponentKind, x: Double, y: Double, angle: Double = 0,
                band: Band? = nil, pairID: Int? = nil, isLocked: Bool = false) {
        self.kind = kind
        self.x = x
        self.y = y
        self.angle = angle
        self.band = band
        self.pairID = pairID
        self.isLocked = isLocked
    }

    public var position: CGPoint { CGPoint(x: x, y: y) }

    // Defensive decoding — a missing key must never wipe a saved sandbox slot.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = ComponentKind(rawValue: (try? c.decodeIfPresent(Int.self, forKey: .kind) ?? 0) ?? 0) ?? .flatMirror
        x = (try? c.decodeIfPresent(Double.self, forKey: .x) ?? 0) ?? 0
        y = (try? c.decodeIfPresent(Double.self, forKey: .y) ?? 0) ?? 0
        angle = (try? c.decodeIfPresent(Double.self, forKey: .angle) ?? 0) ?? 0
        let rawBand = (try? c.decodeIfPresent(Int.self, forKey: .band) ?? -1) ?? -1
        band = Band(rawValue: rawBand)
        let rawPair = (try? c.decodeIfPresent(Int.self, forKey: .pairID) ?? -1) ?? -1
        pairID = rawPair >= 0 ? rawPair : nil
        isLocked = (try? c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kind.rawValue, forKey: .kind)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(angle, forKey: .angle)
        try c.encodeIfPresent(band?.rawValue, forKey: .band)
        try c.encodeIfPresent(pairID, forKey: .pairID)
        try c.encode(isLocked, forKey: .isLocked)
    }

    enum CodingKeys: String, CodingKey {
        case kind, x, y, angle, band, pairID, isLocked
    }
}

// MARK: - Emitter & receptor

public struct EmitterSpec: Codable, Hashable {
    public var x: Double
    public var y: Double
    public var angle: Double
    public var band: Band?         // nil == white (all three bands)
    public var polarisation: Double

    public init(x: Double, y: Double, angle: Double, band: Band? = nil, polarisation: Double = 0) {
        self.x = x; self.y = y; self.angle = angle; self.band = band; self.polarisation = polarisation
    }

    public var position: CGPoint { CGPoint(x: x, y: y) }
    public var isWhite: Bool { band == nil }
}

public struct ReceptorSpec: Codable, Hashable {
    public var x: Double
    public var y: Double
    public var bands: [Band]           // required bands (all must be met)
    public var minIntensity: Double
    public var polarisation: Double?   // required polarisation axis, +/- 12 degrees
    public var pure: Bool              // rejects contamination from non-required bands
    public var radius: Double

    public init(x: Double, y: Double, bands: [Band], minIntensity: Double,
                polarisation: Double? = nil, pure: Bool = false,
                radius: Double = Optics.defaultReceptorRadius) {
        self.x = x; self.y = y; self.bands = bands; self.minIntensity = minIntensity
        self.polarisation = polarisation; self.pure = pure; self.radius = radius
    }

    public var position: CGPoint { CGPoint(x: x, y: y) }

    public var isWhiteTarget: Bool { bands.count == 3 }

    public var label: String {
        if isWhiteTarget { return "W" }
        return bands.map { $0.letter }.joined()
    }
}

// MARK: - Ray & segments

public struct Ray {
    public var origin: CGPoint
    public var direction: CGVector
    public var band: Band
    public var intensity: Double
    public var polarisation: Double
    public var bounces: Int
    public var amplified: Bool

    public init(origin: CGPoint, direction: CGVector, band: Band, intensity: Double,
                polarisation: Double, bounces: Int = 0, amplified: Bool = false) {
        self.origin = origin
        self.direction = direction
        self.band = band
        self.intensity = intensity
        self.polarisation = polarisation
        self.bounces = bounces
        self.amplified = amplified
    }
}

public struct BeamSegment {
    public let ax: Double
    public let ay: Double
    public let bx: Double
    public let by: Double
    public let band: Band
    public let intensity: Double

    public var a: CGPoint { CGPoint(x: ax, y: ay) }
    public var b: CGPoint { CGPoint(x: bx, y: by) }

    public init(a: CGPoint, b: CGPoint, band: Band, intensity: Double) {
        self.ax = Double(a.x); self.ay = Double(a.y)
        self.bx = Double(b.x); self.by = Double(b.y)
        self.band = band
        self.intensity = intensity
    }
}

/// Where a beam finally ended, used by the level builder to site receptors.
public struct BeamTerminal {
    public let start: CGPoint
    public let point: CGPoint
    public let direction: CGVector
    public let band: Band
    public let intensity: Double
    public let polarisation: Double
    public let hitWall: Bool
}

// MARK: - Receptor accumulation

public struct ReceptorReading {
    public var perBand: [Double] = [0, 0, 0]
    public var contaminated: Bool = false
    public var bestPolarisation: Double? = nil

    public func intensity(_ band: Band) -> Double { perBand[band.rawValue] }
}

public struct TraceResult {
    public var segments: [BeamSegment] = []
    public var readings: [ReceptorReading] = []
    public var terminals: [BeamTerminal] = []
    public var maxRayIntensity: Double = 0
    public var segmentCount: Int = 0
    public var hitSegmentBudget: Bool = false

    public func isSatisfied(_ index: Int, _ spec: ReceptorSpec) -> Bool {
        guard index < readings.count else { return false }
        let r = readings[index]
        if spec.pure && r.contaminated { return false }
        for b in spec.bands {
            if r.perBand[b.rawValue] < spec.minIntensity - 1e-9 { return false }
        }
        return true
    }
}

// MARK: - The engine

public enum OpticsEngine {

    /// Trace a whole bench.
    /// - Parameters:
    ///   - benchSide: square bench side length in bench units.
    ///   - emitters: light sources.
    ///   - components: every component on the bench (locked + player placed).
    ///   - receptors: goal discs. Pass an empty array while authoring to discover terminals.
    public static func trace(benchSide: Double,
                             emitters: [EmitterSpec],
                             components: [PlacedComponent],
                             receptors: [ReceptorSpec],
                             collectSegments: Bool = true,
                             collectTerminals: Bool = false) -> TraceResult {

        var result = TraceResult()
        result.readings = Array(repeating: ReceptorReading(), count: receptors.count)

        // Pre-compute component geometry once.
        let geo = components.map { Geometry(component: $0) }

        // Portal partner lookup.
        var portalPartner = [Int](repeating: -1, count: components.count)
        for i in components.indices where components[i].kind == .fibrePortal {
            guard let pid = components[i].pairID else { continue }
            for j in components.indices where j != i {
                if components[j].kind == .fibrePortal && components[j].pairID == pid {
                    portalPartner[i] = j
                    break
                }
            }
        }

        var stack: [Ray] = []
        stack.reserveCapacity(64)
        for e in emitters {
            let dir = pblAngleVec(e.angle)
            let bands: [Band] = e.band.map { [$0] } ?? Band.allCases
            for b in bands {
                stack.append(Ray(origin: e.position, direction: dir, band: b,
                                 intensity: 1.0, polarisation: e.polarisation))
            }
        }

        while let ray = stack.popLast() {
            if result.segmentCount >= Optics.maxSegments {
                result.hitSegmentBudget = true
                break
            }
            if ray.intensity < Optics.minIntensity { continue }
            if ray.bounces > Optics.maxBounces { continue }
            result.maxRayIntensity = max(result.maxRayIntensity, ray.intensity)

            // Nearest hit search.
            var bestT = Double.greatestFiniteMagnitude
            var bestKind = HitTarget.wall
            var bestIndex = -1
            var bestNormal = CGVector(dx: 0, dy: 0)

            // Bench walls.
            let wallT = wallDistance(origin: ray.origin, direction: ray.direction, side: benchSide)
            if wallT > 0 { bestT = wallT }

            // Components.
            for i in geo.indices {
                if let hit = geo[i].intersect(origin: ray.origin, direction: ray.direction) {
                    if hit.t < bestT - 1e-9 {
                        bestT = hit.t
                        bestNormal = hit.normal
                        bestIndex = i
                        bestKind = .component
                    }
                }
            }

            // Receptors.
            for i in receptors.indices {
                if let t = discIntersect(origin: ray.origin, direction: ray.direction,
                                         centre: receptors[i].position, radius: receptors[i].radius) {
                    if t < bestT - 1e-9 {
                        bestT = t
                        bestIndex = i
                        bestKind = .receptor
                    }
                }
            }

            if bestT >= Double.greatestFiniteMagnitude || bestT <= 0 { continue }

            let hitPoint = CGPoint(x: ray.origin.x + ray.direction.dx * CGFloat(bestT),
                                   y: ray.origin.y + ray.direction.dy * CGFloat(bestT))
            let arriving = ray.intensity * exp(-bestT / Optics.falloffLength)

            if collectSegments {
                result.segments.append(BeamSegment(a: ray.origin, b: hitPoint,
                                                   band: ray.band,
                                                   intensity: max(arriving, ray.intensity * 0.35)))
            }
            result.segmentCount += 1

            if arriving < Optics.minIntensity {
                if collectTerminals {
                    result.terminals.append(BeamTerminal(start: ray.origin, point: hitPoint,
                                                         direction: ray.direction,
                                                         band: ray.band, intensity: arriving,
                                                         polarisation: ray.polarisation, hitWall: false))
                }
                continue
            }

            switch bestKind {
            case .wall:
                if collectTerminals {
                    result.terminals.append(BeamTerminal(start: ray.origin, point: hitPoint,
                                                         direction: ray.direction,
                                                         band: ray.band, intensity: arriving,
                                                         polarisation: ray.polarisation, hitWall: true))
                }
                continue

            case .receptor:
                var reading = result.readings[bestIndex]
                let spec = receptors[bestIndex]
                var counts = true
                if let requiredAxis = spec.polarisation {
                    counts = pblAxisDelta(ray.polarisation, requiredAxis) <= Optics.polarisationTolerance
                }
                if counts {
                    if spec.bands.contains(ray.band) {
                        reading.perBand[ray.band.rawValue] += arriving
                        if reading.bestPolarisation == nil { reading.bestPolarisation = ray.polarisation }
                    } else if arriving > 0.10 {
                        reading.contaminated = true
                    }
                } else if spec.bands.contains(ray.band) && arriving > 0.10 {
                    // Right colour, wrong polarisation angle — it still lands, it just does not count.
                    reading.bestPolarisation = reading.bestPolarisation ?? ray.polarisation
                }
                result.readings[bestIndex] = reading
                continue

            case .component:
                let comp = components[bestIndex]
                var next = ray
                next.origin = hitPoint
                next.intensity = arriving
                next.bounces = ray.bounces + 1

                switch comp.kind {

                case .absorber, .receptor:
                    continue

                case .flatMirror:
                    let d = reflect(ray.direction, bestNormal)
                    next.direction = d
                    next.intensity = arriving * Optics.mirrorLoss
                    next.origin = advance(hitPoint, d)
                    stack.append(next)

                case .beamSplitter:
                    let reflected = reflect(ray.direction, bestNormal)
                    var r1 = next
                    r1.direction = reflected
                    r1.intensity = arriving * Optics.splitterShare
                    r1.origin = advance(hitPoint, reflected)
                    var r2 = next
                    r2.direction = ray.direction
                    r2.intensity = arriving * Optics.splitterShare
                    r2.origin = advance(hitPoint, ray.direction)
                    stack.append(r1)
                    stack.append(r2)

                case .colourFilter:
                    guard let band = comp.band, band == ray.band else { continue }
                    next.intensity = arriving * Optics.filterPass
                    next.origin = exitDisc(hitPoint, ray.direction, comp.position, Optics.filterRadius)
                    stack.append(next)

                case .polariser:
                    let delta = ray.polarisation - comp.angle
                    let c = cos(delta)
                    next.intensity = arriving * c * c
                    next.polarisation = normalisedAxis(comp.angle)
                    next.origin = exitDisc(hitPoint, ray.direction, comp.position, Optics.polariserRadius)
                    if next.intensity >= Optics.minIntensity { stack.append(next) }

                case .amplifier:
                    if !ray.amplified {
                        next.intensity = arriving * Optics.amplifierGain
                        next.amplified = true          // hard guard against loop farming
                    }
                    next.origin = exitDisc(hitPoint, ray.direction, comp.position, Optics.amplifierRadius)
                    stack.append(next)

                case .convergingLens, .divergingLens:
                    let f = comp.kind == .convergingLens ? Optics.focalLength : -Optics.focalLength
                    let u = pblAngleVec(comp.angle)                       // lens plane
                    let n = CGVector(dx: -u.dy, dy: u.dx)                 // optical axis
                    let rel = pblVec(comp.position, hitPoint)
                    let h = pblDot(rel, u)
                    let dn = pblDot(ray.direction, n)
                    let du = pblDot(ray.direction, u)
                    let duNew = du - (h / f) * abs(dn)
                    let d = pblNorm(CGVector(dx: CGFloat(dn) * n.dx + CGFloat(duNew) * u.dx,
                                             dy: CGFloat(dn) * n.dy + CGFloat(duNew) * u.dy))
                    next.direction = d
                    next.intensity = arriving * Optics.lensLoss
                    next.origin = advance(hitPoint, d)
                    stack.append(next)

                case .fibrePortal:
                    let partner = portalPartner[bestIndex]
                    if partner < 0 { continue }
                    let exit = components[partner].position
                    next.direction = ray.direction
                    next.intensity = arriving * Optics.portalLoss
                    next.origin = CGPoint(x: exit.x + ray.direction.dx * CGFloat(Optics.portalRadius + 1.0),
                                          y: exit.y + ray.direction.dy * CGFloat(Optics.portalRadius + 1.0))
                    if collectSegments {
                        // Portals are drawn as a jump; no visible segment inside the fibre.
                    }
                    stack.append(next)

                case .prism:
                    let nGlass = Optics.refractiveIndex(ray.band)
                    var nn = bestNormal
                    var cosI = -pblDot(ray.direction, nn)
                    var eta: Double
                    if cosI < 0 {
                        nn = CGVector(dx: -nn.dx, dy: -nn.dy)
                        cosI = -pblDot(ray.direction, nn)
                        eta = nGlass                                 // glass -> air
                    } else {
                        eta = 1.0 / nGlass                           // air -> glass
                    }
                    let k = 1.0 - eta * eta * (1.0 - cosI * cosI)
                    if k < 0 {
                        // Total internal reflection.
                        let d = reflect(ray.direction, nn)
                        next.direction = d
                        next.intensity = arriving * Optics.prismSurfaceLoss
                        next.origin = advance(hitPoint, d)
                        stack.append(next)
                    } else {
                        let coeff = eta * cosI - k.squareRoot()
                        let d = pblNorm(CGVector(dx: CGFloat(eta) * ray.direction.dx + CGFloat(coeff) * nn.dx,
                                                 dy: CGFloat(eta) * ray.direction.dy + CGFloat(coeff) * nn.dy))
                        next.direction = d
                        next.intensity = arriving * Optics.prismSurfaceLoss
                        next.origin = advance(hitPoint, d)
                        stack.append(next)
                    }
                }
            }
        }

        return result
    }

    // MARK: helpers

    private enum HitTarget { case wall, component, receptor }

    @inline(__always) private static func advance(_ p: CGPoint, _ d: CGVector) -> CGPoint {
        CGPoint(x: p.x + d.dx * 0.05, y: p.y + d.dy * 0.05)
    }

    /// Round pass-through elements are solid discs: leave from the FAR side so the ray does
    /// not immediately re-enter the same element and pay its loss twice.
    @inline(__always) private static func exitDisc(_ hit: CGPoint, _ d: CGVector,
                                                   _ centre: CGPoint, _ radius: Double) -> CGPoint {
        if let t = discIntersect(origin: CGPoint(x: hit.x + d.dx * 0.001, y: hit.y + d.dy * 0.001),
                                 direction: d, centre: centre, radius: radius) {
            return CGPoint(x: hit.x + d.dx * CGFloat(t + 0.05), y: hit.y + d.dy * CGFloat(t + 0.05))
        }
        return advance(hit, d)
    }

    @inline(__always) public static func reflect(_ d: CGVector, _ n: CGVector) -> CGVector {
        let dn = pblDot(d, n)
        return pblNorm(CGVector(dx: d.dx - CGFloat(2 * dn) * n.dx,
                                dy: d.dy - CGFloat(2 * dn) * n.dy))
    }

    public static func normalisedAxis(_ a: Double) -> Double {
        var v = a.truncatingRemainder(dividingBy: .pi)
        if v < 0 { v += .pi }
        return v
    }

    /// Distance to the bench boundary along the ray (always positive for a ray starting inside).
    static func wallDistance(origin: CGPoint, direction: CGVector, side: Double) -> Double {
        var best = Double.greatestFiniteMagnitude
        let ox = Double(origin.x), oy = Double(origin.y)
        let dx = Double(direction.dx), dy = Double(direction.dy)
        if abs(dx) > 1e-12 {
            let t1 = (0 - ox) / dx
            let t2 = (side - ox) / dx
            if t1 > 1e-6 { best = min(best, t1) }
            if t2 > 1e-6 { best = min(best, t2) }
        }
        if abs(dy) > 1e-12 {
            let t1 = (0 - oy) / dy
            let t2 = (side - oy) / dy
            if t1 > 1e-6 { best = min(best, t1) }
            if t2 > 1e-6 { best = min(best, t2) }
        }
        return best == Double.greatestFiniteMagnitude ? -1 : best
    }

    static func discIntersect(origin: CGPoint, direction: CGVector, centre: CGPoint, radius: Double) -> Double? {
        let ox = Double(origin.x - centre.x), oy = Double(origin.y - centre.y)
        let dx = Double(direction.dx), dy = Double(direction.dy)
        let b = ox * dx + oy * dy
        let c = ox * ox + oy * oy - radius * radius
        let disc = b * b - c
        if disc < 0 { return nil }
        let s = disc.squareRoot()
        let t1 = -b - s
        if t1 > 1e-6 { return t1 }
        let t2 = -b + s
        if t2 > 1e-6 { return t2 }
        return nil
    }

    // MARK: geometry cache

    struct Hit { let t: Double; let normal: CGVector }

    struct Geometry {
        enum Shape {
            case bar(CGPoint, CGPoint)              // a single segment
            case poly([CGPoint], CGPoint)           // closed polygon + centroid
            case disc(CGPoint, Double)
            case none
        }
        let shape: Shape

        init(component: PlacedComponent) {
            let p = component.position
            let a = component.angle
            switch component.kind {
            case .flatMirror:
                shape = .bar(Geometry.end(p, a, -Optics.mirrorHalf), Geometry.end(p, a, Optics.mirrorHalf))
            case .colourFilter:
                shape = .disc(p, Optics.filterRadius)
            case .beamSplitter:
                shape = .bar(Geometry.end(p, a, -Optics.splitterHalf), Geometry.end(p, a, Optics.splitterHalf))
            case .polariser:
                shape = .disc(p, Optics.polariserRadius)
            case .amplifier:
                shape = .disc(p, Optics.amplifierRadius)
            case .convergingLens, .divergingLens:
                shape = .bar(Geometry.end(p, a, -Optics.lensHalf), Geometry.end(p, a, Optics.lensHalf))
            case .prism:
                shape = .poly(Geometry.triangle(p, a), p)
            case .absorber:
                shape = .poly(Geometry.square(p, a, Optics.absorberHalf), p)
            case .fibrePortal:
                shape = .disc(p, Optics.portalRadius)
            case .receptor:
                shape = .disc(p, Optics.defaultReceptorRadius)
            }
        }

        static func end(_ p: CGPoint, _ a: Double, _ d: Double) -> CGPoint {
            CGPoint(x: p.x + CGFloat(cos(a) * d), y: p.y + CGFloat(sin(a) * d))
        }

        /// Equilateral triangle, circum-radius derived from the side length, rotated by `a`.
        static func triangle(_ p: CGPoint, _ a: Double) -> [CGPoint] {
            let r = Optics.prismSide / 3.0.squareRoot()      // circumradius of equilateral triangle
            return (0..<3).map { i -> CGPoint in
                let t = a - .pi / 2 + Double(i) * 2 * .pi / 3
                return CGPoint(x: p.x + CGFloat(cos(t) * r), y: p.y + CGFloat(sin(t) * r))
            }
        }

        static func square(_ p: CGPoint, _ a: Double, _ half: Double) -> [CGPoint] {
            let ca = cos(a), sa = sin(a)
            let offs: [(Double, Double)] = [(-half, -half), (half, -half), (half, half), (-half, half)]
            return offs.map { o in
                CGPoint(x: p.x + CGFloat(o.0 * ca - o.1 * sa), y: p.y + CGFloat(o.0 * sa + o.1 * ca))
            }
        }

        func intersect(origin: CGPoint, direction: CGVector) -> Hit? {
            switch shape {
            case .none:
                return nil
            case .bar(let a, let b):
                return Geometry.segmentHit(origin, direction, a, b)
            case .poly(let pts, let centre):
                var best: Hit? = nil
                for i in pts.indices {
                    let a = pts[i], b = pts[(i + 1) % pts.count]
                    if var h = Geometry.segmentHit(origin, direction, a, b) {
                        // Outward normal (away from centroid).
                        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                        let outward = pblVec(centre, mid)
                        if pblDot(h.normal, outward) < 0 {
                            h = Hit(t: h.t, normal: CGVector(dx: -h.normal.dx, dy: -h.normal.dy))
                        }
                        if best == nil || h.t < best!.t { best = h }
                    }
                }
                return best
            case .disc(let c, let r):
                guard let t = OpticsEngine.discIntersect(origin: origin, direction: direction, centre: c, radius: r) else { return nil }
                let p = CGPoint(x: origin.x + direction.dx * CGFloat(t), y: origin.y + direction.dy * CGFloat(t))
                return Hit(t: t, normal: pblNorm(pblVec(c, p)))
            }
        }

        static func segmentHit(_ o: CGPoint, _ d: CGVector, _ a: CGPoint, _ b: CGPoint) -> Hit? {
            let e = pblVec(a, b)
            let denom = pblCross(d, e)
            if abs(denom) < 1e-12 { return nil }
            let ao = pblVec(o, a)
            let t = pblCross(ao, e) / denom
            let s = pblCross(ao, d) / denom
            if t <= 1e-6 || s < 0 || s > 1 { return nil }
            var n = pblNorm(CGVector(dx: -e.dy, dy: e.dx))
            if pblDot(d, n) > 0 { n = CGVector(dx: -n.dx, dy: -n.dy) }
            return Hit(t: t, normal: n)
        }
    }
}
