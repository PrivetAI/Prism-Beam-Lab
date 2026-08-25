//  LevelRecipes.swift
//  Prism Beam Lab
//
//  90 hand-authored levels across 6 chapters.
//
//  AUTHORING METHOD (forward, never reverse — BATCH_BRIEF §7.18):
//  every level starts from a `Pen` walking the optical path the designer intends. The pen's
//  waypoints become components (the builder solves each mirror/lens for the exact turn), the
//  engine is then run to find out where the light actually lands, and only then is the receptor
//  planted there. No level is produced by "undoing" a finished board, and `LevelAudit` proves
//  that stripping the player's parts leaves the goal unlit.

import Foundation
import CoreGraphics

// MARK: - Authoring pen

public final class Pen {
    public let origin: CGPoint
    public let originHeading: Double
    private(set) public var p: CGPoint
    private(set) public var heading: Double        // degrees, y grows downward

    public init(_ x: Double, _ y: Double, _ headingDeg: Double) {
        origin = P(x, y)
        originHeading = headingDeg
        p = origin
        heading = headingDeg
    }

    @discardableResult public func go(_ d: Double) -> CGPoint {
        let r = pblDeg(heading)
        p = P(Double(p.x) + cos(r) * d, Double(p.y) + sin(r) * d)
        return p
    }

    /// Point `d` ahead on the current heading without moving the pen.
    public func peek(_ d: Double) -> CGPoint {
        let r = pblDeg(heading)
        return P(Double(p.x) + cos(r) * d, Double(p.y) + sin(r) * d)
    }

    public func turn(_ newHeadingDeg: Double) { heading = newHeadingDeg }

    /// Follow a fibre portal: the beam re-appears just outside the exit portal, same heading.
    @discardableResult public func jump(_ exit: CGPoint) -> CGPoint {
        let r = pblDeg(heading)
        p = P(Double(exit.x) + cos(r) * (Optics.portalRadius + 2),
              Double(exit.y) + sin(r) * (Optics.portalRadius + 2))
        return p
    }

    @discardableResult public func goTurn(_ d: Double, _ newHeadingDeg: Double) -> CGPoint {
        let q = go(d)
        heading = newHeadingDeg
        return q
    }

    public func source(_ band: Band? = nil, pol: Double = 0) -> EmitterSpec {
        EmitterSpec(x: Double(origin.x), y: Double(origin.y), angle: pblDeg(originHeading),
                    band: band, polarisation: OpticsEngine.normalisedAxis(pblDeg(pol)))
    }
}

// MARK: - Compact recipe helpers

let W: [Band] = [.red, .green, .blue]

func rc(_ p: CGPoint, _ bands: [Band], _ minI: Double,
        pol: Double? = nil, pure: Bool = false,
        r: Double = Optics.defaultReceptorRadius) -> ReceptorRecipe {
    ReceptorRecipe(.at(p), bands: bands, minIntensity: minI, polarisationDeg: pol, pure: pure, radius: r)
}

func rb(_ band: Band, _ ord: Int, _ back: Double, _ bands: [Band], _ minI: Double,
        pol: Double? = nil, pure: Bool = false,
        r: Double = Optics.defaultReceptorRadius) -> ReceptorRecipe {
    ReceptorRecipe(.onBeam(band, ord, back), bands: bands, minIntensity: minI,
                   polarisationDeg: pol, pure: pure, radius: r)
}

func blk(_ x: Double, _ y: Double, _ deg: Double = 0) -> PlacedComponent {
    PlacedComponent(kind: .absorber, x: x, y: y, angle: pblDeg(deg), isLocked: true)
}

// MARK: - Chapter metadata

public struct ChapterInfo {
    public let index: Int
    public let name: String
    public let subtitle: String
    public let range: ClosedRange<Int>
}

public enum Chapters {
    public static let all: [ChapterInfo] = [
        ChapterInfo(index: 1, name: "First Light", subtitle: "Mirrors, absorbers and a steady hand", range: 1...14),
        ChapterInfo(index: 2, name: "Split Spectrum", subtitle: "Prisms, filters and pure colour", range: 15...29),
        ChapterInfo(index: 3, name: "Focal Point", subtitle: "Lenses and the cost of a long path", range: 30...44),
        ChapterInfo(index: 4, name: "Half Silvered", subtitle: "Beam splitters and parallel targets", range: 45...59),
        ChapterInfo(index: 5, name: "Wave Angle", subtitle: "Polarisers, Malus's law and gain", range: 60...74),
        ChapterInfo(index: 6, name: "Deep Optics", subtitle: "Fibre portals and white recombination", range: 75...90)
    ]

    public static func chapter(of level: Int) -> ChapterInfo {
        all.first { $0.range.contains(level) } ?? all[0]
    }
}

// MARK: - The recipes

public enum LevelRecipes {

    public static func all() -> [LevelRecipe] {
        var out: [LevelRecipe] = []
        out.append(contentsOf: chapter1())
        out.append(contentsOf: chapter2())
        out.append(contentsOf: chapter3())
        out.append(contentsOf: chapter4())
        out.append(contentsOf: chapter5())
        out.append(contentsOf: chapter6())
        return out
    }

    // MARK: Chapter 1 — First Light (mirror, absorber)

    static func chapter1() -> [LevelRecipe] {
        var v: [LevelRecipe] = []

        do {  // 1
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(294, 90)
            let b = pen.go(150)
            v.append(LevelRecipe(id: 1, chapter: 1, name: "First Light",
                                 brief: "Drop one mirror on the beam and fold it into the receptor.",
                                 emitters: [pen.source()], chain: [.mirror(a), .finish(b)],
                                 receptors: [rc(b, W, 0.35)]))
        }
        do {  // 2
            let pen = Pen(6, 332, 0)
            let a = pen.goTurn(300, -90)
            let b = pen.go(250)
            v.append(LevelRecipe(id: 2, chapter: 1, name: "Rising Ray",
                                 brief: "Same idea, other way up.",
                                 emitters: [pen.source()], chain: [.mirror(a), .finish(b)],
                                 receptors: [rc(b, W, 0.35)]))
        }
        do {  // 3
            let pen = Pen(200, 6, 90)
            let a = pen.goTurn(258, 180)
            let b = pen.go(158)
            v.append(LevelRecipe(id: 3, chapter: 1, name: "Overhead Lamp",
                                 brief: "The emitter looks down. Turn the beam to the left wall.",
                                 emitters: [pen.source()], chain: [.mirror(a), .finish(b)],
                                 receptors: [rc(b, W, 0.35)]))
        }
        do {  // 4
            let pen = Pen(6, 340, 0)
            let a = pen.goTurn(240, -60)
            let b = pen.go(258)
            v.append(LevelRecipe(id: 4, chapter: 1, name: "Off Square",
                                 brief: "Not every fold is a right angle.",
                                 emitters: [pen.source()], chain: [.mirror(a), .finish(b)],
                                 receptors: [rc(b, W, 0.35)]))
        }
        do {  // 5
            let pen = Pen(6, 60, 0)
            let a = pen.goTurn(120, 90)
            let b = pen.goTurn(270, 0)
            let c = pen.go(240)
            v.append(LevelRecipe(id: 5, chapter: 1, name: "Two Corners",
                                 brief: "Two mirrors, one long staircase.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.3)]))
        }
        do {  // 6
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(120, -45)
            let b = pen.goTurn(180, 45)
            let c = pen.go(170)
            v.append(LevelRecipe(id: 6, chapter: 1, name: "Blocked Line",
                                 brief: "A block sits on the straight path. Go around it.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .finish(c)],
                                 obstacles: [blk(230, 200)],
                                 receptors: [rc(c, W, 0.3)]))
        }
        do {  // 7
            let pen = Pen(6, 120, 0)
            let a = pen.goTurn(180, 90)
            let b = pen.goTurn(140, 180)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 7, chapter: 1, name: "Hairpin",
                                 brief: "Send the beam back the way it came.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.3)]))
        }
        do {  // 8
            let pen = Pen(6, 60, 0)
            let a = pen.goTurn(300, 90)
            let b = pen.goTurn(280, 180)
            let c = pen.go(250)
            v.append(LevelRecipe(id: 8, chapter: 1, name: "Bench Fixture",
                                 brief: "One mirror is already bolted down. Add the other.",
                                 emitters: [pen.source()], chain: [.lockedMirror(a), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.3)]))
        }
        do {  // 9
            let pen = Pen(6, 40, 0)
            let a = pen.goTurn(100, 90)
            let b = pen.goTurn(110, 0)
            let c = pen.goTurn(130, 90)
            let d = pen.go(190)
            v.append(LevelRecipe(id: 9, chapter: 1, name: "Step Ladder",
                                 brief: "Three folds, each one shorter than the last.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .mirror(c), .finish(d)],
                                 receptors: [rc(d, W, 0.3)]))
        }
        do {  // 10
            let pen = Pen(6, 300, 0)
            let a = pen.goTurn(150, -90)
            let b = pen.goTurn(200, 0)
            let c = pen.go(210)
            v.append(LevelRecipe(id: 10, chapter: 1, name: "Two Blocks",
                                 brief: "Two absorbers, one narrow way through.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .finish(c)],
                                 obstacles: [blk(285, 300), blk(255, 185)],
                                 receptors: [rc(c, W, 0.3)]))
        }
        do {  // 11
            let pen = Pen(6, 240, 0)
            let a = pen.goTurn(160, -30)
            let b = pen.goTurn(200, -135)
            let c = pen.go(148)
            v.append(LevelRecipe(id: 11, chapter: 1, name: "Shallow Angle",
                                 brief: "Thirty degrees in, thirty degrees out.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.3)]))
        }
        do {  // 12
            let pen = Pen(360, 6, 90)
            let a = pen.goTurn(120, 180)
            let b = pen.goTurn(220, 90)
            let c = pen.goTurn(180, 0)
            let d = pen.go(180)
            v.append(LevelRecipe(id: 12, chapter: 1, name: "Around The Slab",
                                 brief: "Three mirrors, one slab of graphite in the middle.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .mirror(c), .finish(d)],
                                 obstacles: [blk(250, 200)],
                                 receptors: [rc(d, W, 0.3)]))
        }
        do {  // 13
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(90, -60)
            let b = pen.goTurn(150, 30)
            let c = pen.goTurn(200, 90)
            let d = pen.go(186)
            v.append(LevelRecipe(id: 13, chapter: 1, name: "Zig Corridor",
                                 brief: "Thread the corridor between the blocks.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .mirror(c), .finish(d)],
                                 obstacles: [blk(70, 96), blk(250, 300)],
                                 receptors: [rc(d, W, 0.28)]))
        }
        do {  // 14
            let pen = Pen(6, 370, 0)
            let a = pen.goTurn(80, -90)
            let b = pen.goTurn(300, 0)
            let c = pen.goTurn(230, 90)
            let d = pen.goTurn(220, 180)
            let e = pen.go(180)
            v.append(LevelRecipe(id: 14, chapter: 1, name: "Full Circuit",
                                 brief: "Four mirrors. Walk the beam right around the bench.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .mirror(b), .mirror(c), .mirror(d), .finish(e)],
                                 receptors: [rc(e, W, 0.25)]))
        }
        return v
    }

    // MARK: Chapter 2 — Split Spectrum (prism, colour filter)

    static func chapter2() -> [LevelRecipe] {
        var v: [LevelRecipe] = []

        do {  // 15
            let pen = Pen(6, 200, 0)
            let a = pen.go(150)
            v.append(LevelRecipe(id: 15, chapter: 2, name: "White Is Three",
                                 brief: "A prism bends each colour by a different amount. Catch the green one.",
                                 emitters: [pen.source()], chain: [.prism(a, 20)],
                                 receptors: [rb(.green, 0, 95, [.green], 0.3)]))
        }
        do {  // 16
            let pen = Pen(6, 120, 0)
            let a = pen.go(180)
            let b = pen.go(180)
            v.append(LevelRecipe(id: 16, chapter: 2, name: "Colour Gate",
                                 brief: "This receptor rejects any stray colour. Clean the beam first.",
                                 emitters: [pen.source()], chain: [.filter(a, .red), .finish(b)],
                                 receptors: [rc(b, [.red], 0.5, pure: true)]))
        }
        do {  // 17
            let pen = Pen(6, 100, 0)
            let a = pen.go(150)
            v.append(LevelRecipe(id: 17, chapter: 2, name: "Blue Shift",
                                 brief: "Blue bends hardest of all. Find where it lands.",
                                 emitters: [pen.source()], chain: [.prism(a, 26)],
                                 receptors: [rb(.blue, 0, 80, [.blue], 0.28)]))
        }
        do {  // 18
            let pen = Pen(6, 330, 0)
            let a = pen.goTurn(200, -55)
            let b = pen.go(120)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 18, chapter: 2, name: "Green Only",
                                 brief: "Fold first, then strip the beam down to one band.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .filter(b, .green), .finish(c)],
                                 receptors: [rc(c, [.green], 0.45, pure: true)]))
        }
        do {  // 19
            let pen = Pen(6, 70, 0)
            let a = pen.goTurn(170, 60)
            let b = pen.go(150)
            v.append(LevelRecipe(id: 19, chapter: 2, name: "Angled Glass",
                                 brief: "Aim the white beam down before it meets the glass.",
                                 emitters: [pen.source()], chain: [.mirror(a), .prism(b, 85)],
                                 receptors: [rb(.red, 0, 40, [.red], 0.28)]))
        }
        do {  // 20
            let pen = Pen(6, 210, 0)
            let a = pen.go(140)
            v.append(LevelRecipe(id: 20, chapter: 2, name: "Rainbow Tap",
                                 brief: "Split the beam, then bounce one band across the bench.",
                                 emitters: [pen.source()], chain: [.prism(a, 22)],
                                 routes: [[BeamRoute(band: .red, distance: 130, kind: .flatMirror, toward: P(40, 360))]],
                                 receptors: [rb(.red, 0, 60, [.red], 0.25, pure: true)]))
        }
        do {  // 21
            let pen = Pen(6, 300, 0)
            let a = pen.goTurn(160, -40)
            let b = pen.go(170)
            let c = pen.go(140)
            v.append(LevelRecipe(id: 21, chapter: 2, name: "Twice Filtered",
                                 brief: "The blue channel needs a clear run.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .filter(b, .blue), .finish(c)],
                                 obstacles: [blk(250, 300)],
                                 receptors: [rc(c, [.blue], 0.42, pure: true)]))
        }
        do {  // 22
            let pen = Pen(200, 6, 90)
            let a = pen.go(150)
            v.append(LevelRecipe(id: 22, chapter: 2, name: "Downward Fan",
                                 brief: "The lamp points down. Where does green go?",
                                 emitters: [pen.source()], chain: [.prism(a, 110)],
                                 receptors: [rb(.green, 0, 85, [.green], 0.28)]))
        }
        do {  // 23
            let pen = Pen(6, 150, 0)
            let a = pen.goTurn(140, 45)
            let b = pen.goTurn(150, 0)
            let c = pen.go(160)
            v.append(LevelRecipe(id: 23, chapter: 2, name: "Diagonal Wash",
                                 brief: "Two mirrors and a red gate.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .mirror(b), .filter(P(Double(pen.peek(0).x) - 80, Double(pen.peek(0).y)), .red), .finish(c)],
                                 receptors: [rc(c, [.red], 0.4, pure: true)]))
        }
        do {  // 24
            let pen = Pen(6, 250, 0)
            let a = pen.go(160)
            v.append(LevelRecipe(id: 24, chapter: 2, name: "Upward Split",
                                 brief: "Turn the prism until blue climbs to the target.",
                                 emitters: [pen.source()], chain: [.prism(a, 160)],
                                 receptors: [rb(.blue, 0, 90, [.blue], 0.26)]))
        }
        do {  // 25
            let pen = Pen(6, 90, 0)
            let a = pen.goTurn(150, 50)
            let b = pen.go(160)
            v.append(LevelRecipe(id: 25, chapter: 2, name: "Steep Entry",
                                 brief: "Steer down into the glass and take the red exit.",
                                 emitters: [pen.source()], chain: [.mirror(a), .prism(b, 75)],
                                 obstacles: [blk(120, 300)],
                                 receptors: [rb(.red, 0, 26, [.red], 0.25, pure: true, r: 10)]))
        }
        do {  // 26
            let pen = Pen(394, 120, 180)
            let a = pen.goTurn(170, 55)
            let b = pen.go(120)
            let c = pen.go(120)
            v.append(LevelRecipe(id: 26, chapter: 2, name: "Right To Left",
                                 brief: "The lamp faces the other way this time.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .filter(b, .green), .finish(c)],
                                 receptors: [rc(c, [.green], 0.4, pure: true)]))
        }
        do {  // 27
            let pen = Pen(6, 340, 0)
            let a = pen.goTurn(100, -50)
            let b = pen.go(70)
            v.append(LevelRecipe(id: 27, chapter: 2, name: "Long Fan",
                                 brief: "The further the fan runs, the wider it spreads.",
                                 emitters: [pen.source()], chain: [.mirror(a), .prism(b, -25)],
                                 receptors: [rb(.green, 0, 24, [.green], 0.24, pure: true, r: 12)]))
        }
        do {  // 28
            let pen = Pen(6, 60, 0)
            let a = pen.goTurn(140, 45)
            let b = pen.go(150)
            v.append(LevelRecipe(id: 28, chapter: 2, name: "Bounce And Bend",
                                 brief: "Fold, split, then reflect the red band home.",
                                 emitters: [pen.source()], chain: [.mirror(a), .prism(b, 70)],
                                 routes: [[BeamRoute(band: .blue, distance: 110, kind: .flatMirror, toward: P(60, 200))]],
                                 receptors: [rb(.blue, 0, 55, [.blue], 0.2, pure: true)]))
        }
        do {  // 29
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(130, -35)
            let b = pen.go(150)
            let c = pen.go(140)
            v.append(LevelRecipe(id: 29, chapter: 2, name: "Clean Channel",
                                 brief: "Two blocks, one filter, no contamination allowed.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .filter(b, .blue), .finish(c)],
                                 obstacles: [blk(230, 210), blk(120, 60)],
                                 receptors: [rc(c, [.blue], 0.38, pure: true)]))
        }
        return v
    }

    // MARK: Chapter 3 — Focal Point (lenses, intensity thresholds)

    static func chapter3() -> [LevelRecipe] {
        var v: [LevelRecipe] = []

        do {  // 30
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(180, 10)
            let b = pen.go(200)
            v.append(LevelRecipe(id: 30, chapter: 3, name: "Gentle Bend",
                                 brief: "A lens nudges the beam. Off-centre light bends toward the axis.",
                                 emitters: [pen.source()], chain: [.lens(a, true), .finish(b)],
                                 receptors: [rc(b, W, 0.4)]))
        }
        do {  // 31
            let pen = Pen(6, 120, 0)
            let a = pen.goTurn(200, -9)
            let b = pen.go(180)
            v.append(LevelRecipe(id: 31, chapter: 3, name: "Away From Axis",
                                 brief: "A diverging lens pushes light the other way.",
                                 emitters: [pen.source()], chain: [.lens(a, false), .finish(b)],
                                 receptors: [rc(b, W, 0.4)]))
        }
        do {  // 32
            let pen = Pen(6, 300, 0)
            let a = pen.goTurn(150, -60)
            let b = pen.go(180)
            v.append(LevelRecipe(id: 32, chapter: 3, name: "Bright Enough",
                                 brief: "This receptor is fussy about brightness. Keep the path short.",
                                 emitters: [pen.source()], chain: [.mirror(a), .finish(b)],
                                 receptors: [rc(b, W, 0.62)]))
        }
        do {  // 33
            let pen = Pen(6, 80, 0)
            let a = pen.goTurn(160, 12)
            let b = pen.goTurn(150, 70)
            let c = pen.go(160)
            v.append(LevelRecipe(id: 33, chapter: 3, name: "Lens And Fold",
                                 brief: "Lens first for the fine angle, mirror second for the big one.",
                                 emitters: [pen.source()],
                                 chain: [.lens(a, true), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.35)]))
        }
        do {  // 34
            let pen = Pen(6, 340, 0)
            let a = pen.goTurn(170, -8)
            let b = pen.goTurn(160, -70)
            let c = pen.go(170)
            v.append(LevelRecipe(id: 34, chapter: 3, name: "Diverge Then Climb",
                                 brief: "Two small corrections and one hard turn.",
                                 emitters: [pen.source()],
                                 chain: [.lens(a, false), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.35)]))
        }
        do {  // 35
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(110, 11)
            let b = pen.goTurn(130, 0)
            let c = pen.go(120)
            v.append(LevelRecipe(id: 35, chapter: 3, name: "Twin Lenses",
                                 brief: "Bend one way, then straighten out again.",
                                 emitters: [pen.source()],
                                 chain: [.lens(a, true), .lens(b, false), .finish(c)],
                                 obstacles: [blk(300, 320)],
                                 receptors: [rc(c, W, 0.42)]))
        }
        do {  // 36
            let pen = Pen(6, 260, 0)
            let a = pen.goTurn(130, -45)
            let b = pen.goTurn(160, -55)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 36, chapter: 3, name: "Tight Budget",
                                 brief: "Every reflection costs light. Two folds is all you can afford.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .lens(b, true), .finish(c)],
                                 receptors: [rc(c, W, 0.5)]))
        }
        do {  // 37
            let pen = Pen(200, 6, 90)
            let a = pen.goTurn(160, 100)
            let b = pen.go(190)
            v.append(LevelRecipe(id: 37, chapter: 3, name: "Sag",
                                 brief: "Ten degrees is all a lens can give you at this aperture.",
                                 emitters: [pen.source()], chain: [.lens(a, true), .finish(b)],
                                 receptors: [rc(b, W, 0.45)]))
        }
        do {  // 38
            let pen = Pen(6, 150, 0)
            let a = pen.goTurn(150, 55)
            let b = pen.goTurn(130, 45)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 38, chapter: 3, name: "Fine Correction",
                                 brief: "The mirror gets you close. The lens finishes the job.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .lens(b, false), .finish(c)],
                                 receptors: [rc(c, W, 0.4)]))
        }
        do {  // 39
            let pen = Pen(6, 360, 0)
            let a = pen.goTurn(140, -70)
            let b = pen.goTurn(200, -80)
            let c = pen.go(120)
            v.append(LevelRecipe(id: 39, chapter: 3, name: "Steep Climb",
                                 brief: "Fold up, then trim the angle with glass.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .lens(b, true), .finish(c)],
                                 obstacles: [blk(240, 200)],
                                 receptors: [rc(c, W, 0.4)]))
        }
        do {  // 40
            let pen = Pen(6, 100, 0)
            let a = pen.go(160)
            let b = pen.go(140)
            v.append(LevelRecipe(id: 40, chapter: 3, name: "Bright Red",
                                 brief: "A pure red target that still demands a strong signal.",
                                 emitters: [pen.source()], chain: [.filter(a, .red), .finish(b)],
                                 receptors: [rc(b, [.red], 0.65, pure: true)]))
        }
        do {  // 41
            let pen = Pen(6, 210, 0)
            let a = pen.goTurn(120, -12)
            let b = pen.goTurn(130, -60)
            let c = pen.goTurn(120, 0)
            let d = pen.go(60)
            v.append(LevelRecipe(id: 41, chapter: 3, name: "Three Stage",
                                 brief: "Lens, mirror, mirror. Watch the light drain away.",
                                 emitters: [pen.source()],
                                 chain: [.lens(a, true), .mirror(b), .mirror(c), .finish(d)],
                                 receptors: [rc(d, W, 0.35)]))
        }
        do {  // 42
            let pen = Pen(394, 320, 180)
            let a = pen.goTurn(170, -120)
            let b = pen.goTurn(150, -110)
            let c = pen.go(140)
            v.append(LevelRecipe(id: 42, chapter: 3, name: "Left Hand Bench",
                                 brief: "Mirror then lens, running right to left.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .lens(b, false), .finish(c)],
                                 receptors: [rc(c, W, 0.38)]))
        }
        do {  // 43
            let pen = Pen(6, 60, 0)
            let a = pen.goTurn(180, 9)
            let b = pen.goTurn(150, 75)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 43, chapter: 3, name: "Threaded Drop",
                                 brief: "Two blocks narrow the aperture. Line it up exactly.",
                                 emitters: [pen.source()],
                                 chain: [.lens(a, true), .mirror(b), .finish(c)],
                                 obstacles: [blk(300, 210), blk(190, 300)],
                                 receptors: [rc(c, W, 0.35)]))
        }
        do {  // 44
            let pen = Pen(6, 340, 0)
            let a = pen.goTurn(120, -10)
            let b = pen.goTurn(150, -70)
            let c = pen.goTurn(150, -60)
            let d = pen.go(110)
            v.append(LevelRecipe(id: 44, chapter: 3, name: "Focal Finale",
                                 brief: "Lens, mirror, lens. Every degree matters.",
                                 emitters: [pen.source()],
                                 chain: [.lens(a, true), .mirror(b), .lens(c, false), .finish(d)],
                                 receptors: [rc(d, W, 0.3)]))
        }
        return v
    }

    // MARK: Chapter 4 — Half Silvered (beam splitter, multi-receptor)

    static func chapter4() -> [LevelRecipe] {
        var v: [LevelRecipe] = []

        do {  // 45
            let pen = Pen(6, 200, 0)
            let a = pen.go(180)
            let through = pen.peek(190)
            pen.turn(90)
            let b = pen.go(160)
            v.append(LevelRecipe(id: 45, chapter: 4, name: "Half And Half",
                                 brief: "A splitter sends half the light on and reflects the rest.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 receptors: [rc(b, W, 0.2), rc(through, W, 0.2)]))
        }
        do {  // 46
            let pen = Pen(6, 300, 0)
            let a = pen.go(170)
            let through = pen.peek(200)
            pen.turn(-90)
            let b = pen.go(220)
            v.append(LevelRecipe(id: 46, chapter: 4, name: "Two Targets",
                                 brief: "Both receptors have to light up at once.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 receptors: [rc(b, W, 0.18), rc(through, W, 0.18)]))
        }
        do {  // 47
            let pen = Pen(6, 120, 0)
            let a = pen.go(150)
            let through = pen.peek(230)
            pen.turn(60)
            let b = pen.go(200)
            v.append(LevelRecipe(id: 47, chapter: 4, name: "Sixty Split",
                                 brief: "The reflected half does not have to leave at a right angle.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 receptors: [rc(b, W, 0.18), rc(through, W, 0.18)]))
        }
        do {  // 48
            let pen = Pen(6, 210, 0)
            let a = pen.goTurn(140, -40)
            let b = pen.go(150)
            let through = pen.peek(120)
            pen.turn(50)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 48, chapter: 4, name: "Fold Then Split",
                                 brief: "Get the beam up first, then halve it.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .splitter(b), .finish(c)],
                                 receptors: [rc(c, W, 0.16), rc(through, W, 0.16)]))
        }
        do {  // 49
            let pen = Pen(6, 90, 0)
            let a = pen.go(160)
            let through = pen.peek(210)
            pen.turn(75)
            let b = pen.goTurn(150, 160)
            let c = pen.go(140)
            v.append(LevelRecipe(id: 49, chapter: 4, name: "Long Branch",
                                 brief: "One half runs straight on, the other takes the long way.",
                                 emitters: [pen.source()],
                                 chain: [.splitter(a), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.14), rc(through, W, 0.16)]))
        }
        do {  // 50
            let pen = Pen(6, 330, 0)
            let a = pen.go(170)
            let through = pen.peek(200)
            pen.turn(-70)
            let b = pen.go(190)
            v.append(LevelRecipe(id: 50, chapter: 4, name: "Split The Blocks",
                                 brief: "Two absorbers, two receptors, one splitter.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 obstacles: [blk(300, 260), blk(110, 200)],
                                 receptors: [rc(b, W, 0.16), rc(through, W, 0.16)]))
        }
        do {  // 51
            let pen = Pen(200, 6, 90)
            let a = pen.go(150)
            let through = pen.peek(200)
            pen.turn(180)
            let b = pen.go(150)
            v.append(LevelRecipe(id: 51, chapter: 4, name: "Down And Across",
                                 brief: "The lamp is overhead. Split it sideways.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 receptors: [rc(b, W, 0.18), rc(through, W, 0.18)]))
        }
        do {  // 52
            let pen = Pen(6, 200, 0)
            let a = pen.go(140)
            let through = pen.peek(160)
            pen.turn(-65)
            let b = pen.go(170)
            v.append(LevelRecipe(id: 52, chapter: 4, name: "Colour And Half",
                                 brief: "One branch has to arrive perfectly clean.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 extras: [PlacedComponent(kind: .colourFilter, x: 230, y: 200, band: .red)],
                                 receptors: [rc(b, W, 0.25), rc(through, [.red], 0.25, pure: true)]))
        }
        do {  // 53
            let pen = Pen(6, 260, 0)
            let a = pen.goTurn(150, -50)
            let b = pen.go(150)
            let through = pen.peek(130)
            pen.turn(40)
            let c = pen.go(160)
            v.append(LevelRecipe(id: 53, chapter: 4, name: "Wide Wedge",
                                 brief: "Mirror in, splitter out, two ways home.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .splitter(b), .finish(c)],
                                 receptors: [rc(c, W, 0.15), rc(through, W, 0.15)]))
        }
        do {  // 54
            let pen = Pen(6, 60, 0)
            let a = pen.go(150)
            let through = pen.peek(220)
            pen.turn(80)
            let b = pen.go(180)
            let through2 = pen.peek(120)
            pen.turn(170)
            let c = pen.go(130)
            v.append(LevelRecipe(id: 54, chapter: 4, name: "Split Twice",
                                 brief: "Two splitters. Three targets. Quarter light each.",
                                 emitters: [pen.source()],
                                 chain: [.splitter(a), .splitter(b), .finish(c)],
                                 receptors: [rc(c, W, 0.08), rc(through, W, 0.16), rc(through2, W, 0.08)]))
        }
        do {  // 55
            let pen = Pen(394, 90, 180)
            let a = pen.go(160)
            let through = pen.peek(190)
            pen.turn(90)
            let b = pen.go(200)
            v.append(LevelRecipe(id: 55, chapter: 4, name: "Mirror Image",
                                 brief: "Right to left, and still both targets.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 obstacles: [blk(120, 200)],
                                 receptors: [rc(b, W, 0.17), rc(through, W, 0.17)]))
        }
        do {  // 56
            let pen = Pen(6, 350, 0)
            let a = pen.goTurn(130, -55)
            let b = pen.go(140)
            let through = pen.peek(130)
            pen.turn(10)
            let c = pen.goTurn(140, 90)
            let d = pen.go(110)
            v.append(LevelRecipe(id: 56, chapter: 4, name: "Bent Branch",
                                 brief: "The reflected half needs one more fold.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .splitter(b), .mirror(c), .finish(d)],
                                 receptors: [rc(d, W, 0.12), rc(through, W, 0.14)]))
        }
        do {  // 57
            let pen = Pen(6, 200, 0)
            let a = pen.go(130)
            let through = pen.peek(200)
            pen.turn(-60)
            let b = pen.go(150)
            v.append(LevelRecipe(id: 57, chapter: 4, name: "Bright Half",
                                 brief: "Half the light still has to clear a high threshold.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 receptors: [rc(b, W, 0.3), rc(through, W, 0.3)]))
        }
        do {  // 58
            let pen = Pen(6, 140, 0)
            let a = pen.go(150)
            let through = pen.peek(210)
            pen.turn(70)
            let b = pen.goTurn(160, 175)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 58, chapter: 4, name: "Return Branch",
                                 brief: "Send the reflected half back across the bench.",
                                 emitters: [pen.source()],
                                 chain: [.splitter(a), .mirror(b), .finish(c)],
                                 obstacles: [blk(300, 300)],
                                 receptors: [rc(c, W, 0.12), rc(through, W, 0.16)]))
        }
        do {  // 59
            let pen = Pen(6, 250, 0)
            let a = pen.goTurn(120, -35)
            let b = pen.go(150)
            let through = pen.peek(150)
            pen.turn(55)
            let c = pen.goTurn(140, 150)
            let d = pen.go(130)
            v.append(LevelRecipe(id: 59, chapter: 4, name: "Silvered Finale",
                                 brief: "Mirror, splitter, mirror. Both halves must land.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .splitter(b), .mirror(c), .finish(d)],
                                 receptors: [rc(d, W, 0.11), rc(through, W, 0.13)]))
        }
        return v
    }

    // MARK: Chapter 5 — Wave Angle (polariser, amplifier)

    static func chapter5() -> [LevelRecipe] {
        var v: [LevelRecipe] = []

        do {  // 60
            let pen = Pen(6, 200, 0)
            let a = pen.go(170)
            let b = pen.go(180)
            v.append(LevelRecipe(id: 60, chapter: 5, name: "Wave Angle",
                                 brief: "This receptor only counts light polarised near forty degrees.",
                                 emitters: [pen.source()], chain: [.polariser(a, 40), .finish(b)],
                                 receptors: [rc(b, W, 0.28, pol: 40)]))
        }
        do {  // 61
            let pen = Pen(6, 110, 0)
            let a = pen.goTurn(160, 50)
            let b = pen.go(130)
            let c = pen.go(120)
            v.append(LevelRecipe(id: 61, chapter: 5, name: "Turn The Axis",
                                 brief: "Fold the beam, then twist its wave.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .polariser(b, 65), .finish(c)],
                                 receptors: [rc(c, W, 0.11, pol: 65)]))
        }
        do {  // 62
            let pen = Pen(6, 300, 0)
            let a = pen.go(150)
            let b = pen.go(150)
            let c = pen.go(90)
            v.append(LevelRecipe(id: 62, chapter: 5, name: "Crystal Gain",
                                 brief: "A polariser costs light. The crystal gives some back — once.",
                                 emitters: [pen.source()],
                                 chain: [.polariser(a, 55), .amplifier(b), .finish(c)],
                                 receptors: [rc(c, W, 0.35, pol: 55)]))
        }
        do {  // 63
            let pen = Pen(6, 200, 0)
            let a = pen.go(130)
            let b = pen.go(130)
            let c = pen.go(120)
            v.append(LevelRecipe(id: 63, chapter: 5, name: "Three Filters",
                                 brief: "Crossed axes pass nothing. A third one in between changes that.",
                                 emitters: [pen.source()],
                                 chain: [.polariser(a, 45), .polariser(b, 90), .finish(c)],
                                 receptors: [rc(c, W, 0.14, pol: 90)]))
        }
        do {  // 64
            let pen = Pen(6, 340, 0)
            let a = pen.goTurn(150, -55)
            let b = pen.go(140)
            let c = pen.go(120)
            v.append(LevelRecipe(id: 64, chapter: 5, name: "Steep And Twisted",
                                 brief: "Climb the bench and land on a thirty degree axis.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .polariser(b, 30), .finish(c)],
                                 receptors: [rc(c, W, 0.4, pol: 30)]))
        }
        do {  // 65
            let pen = Pen(6, 90, 0)
            let a = pen.go(150)
            let b = pen.goTurn(140, 60)
            let c = pen.go(150)
            v.append(LevelRecipe(id: 65, chapter: 5, name: "Amplified Fold",
                                 brief: "Gain first, then a long fold to the target.",
                                 emitters: [pen.source()],
                                 chain: [.amplifier(a), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.95)]))
        }
        do {  // 66
            let pen = Pen(200, 6, 90)
            let a = pen.go(150)
            let b = pen.goTurn(130, 170)
            let c = pen.go(140)
            v.append(LevelRecipe(id: 66, chapter: 5, name: "Vertical Wave",
                                 brief: "Polarise on the way down, then turn hard left.",
                                 emitters: [pen.source()],
                                 chain: [.polariser(a, 60), .mirror(b), .finish(c)],
                                 receptors: [rc(c, W, 0.14, pol: 60)]))
        }
        do {  // 67
            let pen = Pen(6, 250, 0)
            let a = pen.go(140)
            let b = pen.go(130)
            let c = pen.go(110)
            v.append(LevelRecipe(id: 67, chapter: 5, name: "Colour And Wave",
                                 brief: "One band, one axis, one very fussy receptor.",
                                 emitters: [pen.source()],
                                 chain: [.filter(a, .green), .polariser(b, 50), .finish(c)],
                                 receptors: [rc(c, [.green], 0.25, pol: 50, pure: true)]))
        }
        do {  // 68
            let pen = Pen(6, 160, 0)
            let a = pen.go(140)
            let b = pen.goTurn(120, 55)
            let c = pen.go(130)
            let d = pen.go(100)
            v.append(LevelRecipe(id: 68, chapter: 5, name: "Gain Then Twist",
                                 brief: "Boost, fold, polarise. In that order.",
                                 emitters: [pen.source()],
                                 chain: [.amplifier(a), .mirror(b), .polariser(c, 35), .finish(d)],
                                 receptors: [rc(d, W, 0.7, pol: 35)]))
        }
        do {  // 69
            let pen = Pen(6, 200, 0)
            let a = pen.go(130)
            let through = pen.peek(180)
            pen.turn(-60)
            let b = pen.go(160)
            v.append(LevelRecipe(id: 69, chapter: 5, name: "Split Polarity",
                                 brief: "Half the beam gets an axis, half does not.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 routes: [[BeamRoute(band: .green, ordinal: 0, distance: 55, kind: .polariser,
                                                     locked: true)]],
                                 receptors: [rc(b, W, 0.18), rc(through, [.green], 0.1, pol: 0)]))
        }
        do {  // 70
            let pen = Pen(6, 350, 0)
            let a = pen.goTurn(140, -70)
            let b = pen.go(130)
            let c = pen.go(120)
            let d = pen.go(90)
            v.append(LevelRecipe(id: 70, chapter: 5, name: "Steep Gain",
                                 brief: "Climb, twist, boost. Nothing to spare.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .polariser(b, 60), .amplifier(c), .finish(d)],
                                 receptors: [rc(d, W, 0.22, pol: 60)]))
        }
        do {  // 71
            let pen = Pen(394, 200, 180)
            let a = pen.go(150)
            let b = pen.go(130)
            let c = pen.go(100)
            v.append(LevelRecipe(id: 71, chapter: 5, name: "Backwards Wave",
                                 brief: "Two axes in series, running right to left.",
                                 emitters: [pen.source()],
                                 chain: [.polariser(a, 40), .polariser(b, 80), .finish(c)],
                                 receptors: [rc(c, W, 0.24, pol: 80)]))
        }
        do {  // 72
            let pen = Pen(6, 120, 0)
            let a = pen.goTurn(150, 45)
            let b = pen.go(110)
            let c = pen.goTurn(110, -45)
            let d = pen.go(90)
            v.append(LevelRecipe(id: 72, chapter: 5, name: "Zig With Gain",
                                 brief: "Two folds and a crystal between them.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .amplifier(b), .mirror(c), .finish(d)],
                                 obstacles: [blk(300, 120)],
                                 receptors: [rc(d, W, 0.9)]))
        }
        do {  // 73
            let pen = Pen(6, 60, 0)
            let a = pen.go(140)
            let b = pen.goTurn(130, 65)
            let c = pen.go(120)
            let d = pen.go(110)
            v.append(LevelRecipe(id: 73, chapter: 5, name: "Clean And Aligned",
                                 brief: "Blue only, boosted, on a seventy five degree axis.",
                                 emitters: [pen.source()],
                                 chain: [.filter(a, .blue), .mirror(b), .polariser(c, 55), .finish(d)],
                                 receptors: [rc(d, [.blue], 0.15, pol: 55, pure: true)]))
        }
        do {  // 74
            let pen = Pen(6, 220, 0)
            let a = pen.go(120)
            let b = pen.goTurn(120, -50)
            let c = pen.go(120)
            let d = pen.go(110)
            v.append(LevelRecipe(id: 74, chapter: 5, name: "Wave Finale",
                                 brief: "Twist, fold, boost, and still clear the bar.",
                                 emitters: [pen.source()],
                                 chain: [.polariser(a, 25), .mirror(b), .amplifier(c), .finish(d)],
                                 obstacles: [blk(250, 320)],
                                 receptors: [rc(d, W, 0.75, pol: 25)]))
        }
        return v
    }

    // MARK: Chapter 6 — Deep Optics (portals, recombination, everything)

    static func chapter6() -> [LevelRecipe] {
        var v: [LevelRecipe] = []

        do {  // 75
            let pen = Pen(6, 120, 0)
            let a = pen.go(150)
            pen.jump(P(120, 300))
            let b = pen.go(170)
            v.append(LevelRecipe(id: 75, chapter: 6, name: "Fibre Jump",
                                 brief: "Light entering one portal leaves the other, heading unchanged.",
                                 emitters: [pen.source()], chain: [.portal(a, P(120, 300), 0), .finish(b)],
                                 receptors: [rc(b, W, 0.3)]))
        }
        do {  // 76
            let pen = Pen(6, 320, 0)
            let a = pen.go(140)
            pen.jump(P(250, 90))
            let b = pen.go(90)
            v.append(LevelRecipe(id: 76, chapter: 6, name: "Over The Wall",
                                 brief: "The block is unavoidable. Jump past it.",
                                 emitters: [pen.source()], chain: [.portal(a, P(250, 90), 0), .finish(b)],
                                 obstacles: [blk(230, 320), blk(300, 320)],
                                 receptors: [rc(b, W, 0.3)]))
        }
        do {  // 77
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(130, -45)
            let b = pen.go(120)
            pen.jump(P(120, 330))
            let c = pen.go(120)
            v.append(LevelRecipe(id: 77, chapter: 6, name: "Fold And Jump",
                                 brief: "A mirror sets the heading the portal will preserve.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .portal(b, P(120, 330), 0), .finish(c)],
                                 receptors: [rc(c, W, 0.25)]))
        }
        do {  // 78
            let pen = Pen(6, 200, 0)
            let a = pen.goTurn(134, 90)
            let b = pen.goTurn(100, 0)
            let c = pen.goTurn(150, 45)
            let d = pen.go(84.853)
            v.append(LevelRecipe(id: 78, chapter: 6, name: "Recombine",
                                 brief: "Three filtered branches, one white target. Every band must arrive.",
                                 emitters: [pen.source()],
                                 chain: [.lockedSplitter(a), .lockedSplitter(b), .mirror(c), .finish(d)],
                                 extras: [
                                    PlacedComponent(kind: .colourFilter, x: 220, y: 300, band: .red, isLocked: true),
                                    PlacedComponent(kind: .colourFilter, x: 140, y: 330, band: .green, isLocked: true),
                                    PlacedComponent(kind: .colourFilter, x: 250, y: 200, band: .blue, isLocked: true),
                                    PlacedComponent(kind: .flatMirror, x: 140, y: 360, angle: pblDeg(45)),
                                    PlacedComponent(kind: .flatMirror, x: 350, y: 200, angle: pblDeg(45))
                                 ],
                                 receptors: [rc(P(350, 360), W, 0.12, r: 15)]))
        }
        do {  // 79
            let pen = Pen(6, 260, 0)
            let a = pen.goTurn(140, -60)
            let b = pen.go(140)
            pen.jump(P(300, 330))
            let c = pen.go(90)
            let d = pen.go(45)
            v.append(LevelRecipe(id: 79, chapter: 6, name: "Portal Filter",
                                 brief: "Jump the beam, then strip it to a single band.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .portal(b, P(300, 330), 0), .filter(c, .red), .finish(d)],
                                 receptors: [rc(d, [.red], 0.3, pure: true)]))
        }
        do {  // 80
            let pen = Pen(6, 180, 0)
            let a = pen.go(130)
            let through = pen.peek(180)
            pen.turn(70)
            let b = pen.go(150)
            v.append(LevelRecipe(id: 80, chapter: 6, name: "Split And Jump",
                                 brief: "One half goes straight on, the other falls into the fibre.",
                                 emitters: [pen.source()], chain: [.splitter(a), .finish(b)],
                                 receptors: [rc(b, W, 0.15), rc(through, W, 0.15)]))
        }
        do {  // 81
            let pen = Pen(200, 6, 90)
            let a = pen.go(140)
            pen.jump(P(70, 200))
            let b = pen.go(120)
            v.append(LevelRecipe(id: 81, chapter: 6, name: "Down The Pipe",
                                 brief: "Straight down, out the side.",
                                 emitters: [pen.source()], chain: [.portal(a, P(70, 200), 0), .finish(b)],
                                 obstacles: [blk(200, 250)],
                                 receptors: [rc(b, W, 0.3)]))
        }
        do {  // 82
            let pen = Pen(6, 340, 0)
            let a = pen.goTurn(130, -50)
            let b = pen.go(130)
            let c = pen.go(120)
            let d = pen.go(90)
            v.append(LevelRecipe(id: 82, chapter: 6, name: "Everything At Once",
                                 brief: "Mirror, crystal, polariser, target. No spare parts.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .amplifier(b), .polariser(c, 45), .finish(d)],
                                 receptors: [rc(d, W, 0.55, pol: 45)]))
        }
        do {  // 83
            let pen = Pen(6, 130, 0)
            let a = pen.go(160)
            v.append(LevelRecipe(id: 83, chapter: 6, name: "Twin Bands",
                                 brief: "Two pure targets from one white beam.",
                                 emitters: [pen.source()], chain: [.prism(a, 28)],
                                 receptors: [rb(.red, 0, 70, [.red], 0.2, pure: true, r: 12),
                                             rb(.blue, 0, 70, [.blue], 0.2, pure: true, r: 12)]))
        }
        do {  // 84
            let pen = Pen(6, 210, 0)
            let a = pen.go(140)
            pen.jump(P(80, 60))
            let b = pen.go(120)
            let c = pen.go(110)
            v.append(LevelRecipe(id: 84, chapter: 6, name: "Long Fibre",
                                 brief: "The fibre costs ten percent. Budget for it.",
                                 emitters: [pen.source()],
                                 chain: [.portal(a, P(80, 60), 0), .filter(b, .green), .finish(c)],
                                 receptors: [rc(c, [.green], 0.35, pure: true)]))
        }
        do {  // 85
            let pen = Pen(6, 60, 0)
            let a = pen.goTurn(120, 60)
            let b = pen.goTurn(100, 0)
            let c = pen.go(60)
            v.append(LevelRecipe(id: 85, chapter: 6, name: "Angled Fan",
                                 brief: "Two folds set the entry angle. The glass does the rest.",
                                 emitters: [pen.source()], chain: [.mirror(a), .mirror(b), .prism(c, 25)],
                                 receptors: [rb(.green, 0, 22, [.green], 0.18, pure: true, r: 11)]))
        }
        do {  // 86
            let pen = Pen(6, 70, 0)
            let a = pen.go(140)
            let through = pen.peek(200)
            pen.turn(75)
            let b = pen.go(170)
            pen.jump(P(90, 200))
            let c = pen.go(90)
            v.append(LevelRecipe(id: 86, chapter: 6, name: "Half To The Fibre",
                                 brief: "Split, then post one half through the portal.",
                                 emitters: [pen.source()],
                                 chain: [.splitter(a), .portal(b, P(90, 200), 0), .finish(c)],
                                 receptors: [rc(through, W, 0.16), rc(c, W, 0.1)]))
        }
        do {  // 87
            let pen = Pen(394, 340, 180)
            let a = pen.goTurn(150, -125)
            let b = pen.go(130)
            let c = pen.go(120)
            v.append(LevelRecipe(id: 87, chapter: 6, name: "Reverse Everything",
                                 brief: "Right to left, up the bench, boosted and polarised.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .amplifier(b), .polariser(c, 55), .finish(pen.peek(90))],
                                 receptors: [rc(pen.peek(90), W, 0.3, pol: 55)]))
        }
        do {  // 88
            let pen = Pen(6, 160, 0)
            let a = pen.go(150)
            v.append(LevelRecipe(id: 88, chapter: 6, name: "Three Way Split",
                                 brief: "Every band gets its own target.",
                                 emitters: [pen.source()], chain: [.prism(a, 24)],
                                 receptors: [rb(.red, 0, 60, [.red], 0.2, pure: true, r: 11),
                                             rb(.green, 0, 60, [.green], 0.2, pure: true, r: 11),
                                             rb(.blue, 0, 60, [.blue], 0.2, pure: true, r: 11)]))
        }
        do {  // 89
            let pen = Pen(6, 250, 0)
            let a = pen.goTurn(130, -55)
            let b = pen.go(130)
            pen.jump(P(70, 300))
            let c = pen.go(110)
            v.append(LevelRecipe(id: 89, chapter: 6, name: "Fibre And Fan",
                                 brief: "Jump the beam, then let the glass do the rest.",
                                 emitters: [pen.source()],
                                 chain: [.mirror(a), .portal(b, P(70, 300), 0), .prism(c, 200)],
                                 receptors: [rb(.blue, 0, 55, [.blue], 0.15, pure: true, r: 12)]))
        }
        do {  // 90
            let pen = Pen(6, 200, 0)
            let a = pen.go(130)
            let through = pen.peek(190)
            pen.turn(-35)
            let b = pen.go(130)
            let c = pen.go(110)
            let d = pen.peek(45)
            v.append(LevelRecipe(id: 90, chapter: 6, name: "Deep Optics",
                                 brief: "The whole bench: split it, boost it, twist it, land both halves.",
                                 emitters: [pen.source()],
                                 chain: [.splitter(a), .amplifier(b), .polariser(c, 50), .finish(d)],
                                 receptors: [rc(d, W, 0.24, pol: 50), rc(through, W, 0.2)]))
        }
        return v
    }
}
