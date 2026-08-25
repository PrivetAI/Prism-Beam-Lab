//  CodexView.swift
//  Prism Beam Lab
//
//  14 illustrated optics entries. Every diagram is traced live by the same engine that runs
//  the campaign — there are no picture assets anywhere in this app.

import SwiftUI

// MARK: - Scene + entry model

struct CodexScene {
    let side: Double
    let emitters: [EmitterSpec]
    let components: [PlacedComponent]
    let receptors: [ReceptorSpec]

    init(side: Double = 220, emitters: [EmitterSpec],
         components: [PlacedComponent] = [], receptors: [ReceptorSpec] = []) {
        self.side = side
        self.emitters = emitters
        self.components = components
        self.receptors = receptors
    }
}

struct CodexEntry: Identifiable {
    let id: Int
    let title: String
    let tagline: String
    let paragraphs: [String]
    let scene: CodexScene
}

enum CodexLibrary {

    static func em(_ x: Double, _ y: Double, _ deg: Double, _ band: Band? = nil, pol: Double = 0) -> EmitterSpec {
        EmitterSpec(x: x, y: y, angle: pblDeg(deg), band: band,
                    polarisation: OpticsEngine.normalisedAxis(pblDeg(pol)))
    }

    static func cp(_ kind: ComponentKind, _ x: Double, _ y: Double, _ deg: Double = 0,
                   band: Band? = nil, pair: Int? = nil) -> PlacedComponent {
        PlacedComponent(kind: kind, x: x, y: y, angle: pblDeg(deg), band: band, pairID: pair, isLocked: true)
    }

    static func rec(_ x: Double, _ y: Double, _ bands: [Band], _ minI: Double,
                    pol: Double? = nil, r: Double = 13) -> ReceptorSpec {
        ReceptorSpec(x: x, y: y, bands: bands, minIntensity: minI,
                     polarisation: pol.map { OpticsEngine.normalisedAxis(pblDeg($0)) }, pure: false, radius: r)
    }

    static let entries: [CodexEntry] = [

        CodexEntry(id: 1, title: "Reflection", tagline: "Angle in equals angle out",
                   paragraphs: [
                    "A flat mirror sends a beam away at exactly the angle it arrived, measured from the line perpendicular to the surface. Turn the mirror by one degree and the beam turns by two.",
                    "That doubling is the single most useful fact on this bench. When a target sits just off the beam, the mirror only needs half of the correction you think it does.",
                    "Every reflection in this lab costs two percent of the beam's intensity, so a route with six folds arrives noticeably dimmer than a route with two."
                   ],
                   scene: CodexScene(emitters: [em(8, 55, 0, .green)],
                                     components: [cp(.flatMirror, 150, 55, 45)],
                                     receptors: [rec(150, 190, [.green], 0.2)])),

        CodexEntry(id: 2, title: "Snell's Law", tagline: "n1 sin θ1 = n2 sin θ2",
                   paragraphs: [
                    "When light crosses from air into glass it slows down, and the part of the wavefront that enters first is held back. The beam bends toward the perpendicular.",
                    "Snell's law puts a number on it: the product of the refractive index and the sine of the angle is the same on both sides of the surface.",
                    "A prism refracts twice — once going in, once coming out — which is why a small turn of the glass swings the exit beam a long way."
                   ],
                   scene: CodexScene(emitters: [em(8, 70, 15, .green)],
                                     components: [cp(.prism, 110, 97, 40)])),

        CodexEntry(id: 3, title: "Refractive Index", tagline: "How much a material slows light",
                   paragraphs: [
                    "Refractive index n is the ratio of the speed of light in vacuum to its speed in the material. Air is about 1.0003, water 1.33, ordinary window glass about 1.5.",
                    "The index is not one number for a material — it depends on colour. Blue light is slowed more than red light, so it bends more at every surface.",
                    "The lab glass here uses 1.500 for red, 1.560 for green and 1.640 for blue. That spread is wider than a real flint glass, deliberately: it makes the rainbow separate over a bench you can see rather than over ten metres of optical table."
                   ],
                   scene: CodexScene(emitters: [em(8, 70, 15)],
                                     components: [cp(.prism, 110, 97, 40)])),

        CodexEntry(id: 4, title: "Dispersion", tagline: "One beam in, a rainbow out",
                   paragraphs: [
                    "Because index varies with colour, a prism refracts each band by a different amount. White light enters as one beam and leaves as a fan.",
                    "The fan keeps widening the further it travels. Close to the glass the three bands are almost on top of each other; a hundred units later they are clearly separate targets.",
                    "That is the whole trick of Chapter 2: if a receptor demands one pure colour, give the fan enough room to spread before it arrives."
                   ],
                   scene: CodexScene(side: 240, emitters: [em(8, 60, 0)],
                                     components: [cp(.prism, 70, 60, 25)])),

        CodexEntry(id: 5, title: "Total Internal Reflection", tagline: "When glass becomes a mirror",
                   paragraphs: [
                    "Going from glass back out into air, the beam bends away from the perpendicular. Past a critical angle there is no exit angle that satisfies Snell's law at all.",
                    "At that point none of the light escapes: the surface behaves as a perfect mirror. This is total internal reflection, and it loses nothing to transmission.",
                    "Reflection does not care about colour, so a beam that bounces internally comes out with its bands still stacked together. If your prism produces no rainbow, it is probably reflecting rather than refracting — turn it."
                   ],
                   scene: CodexScene(emitters: [em(8, 80, 0)],
                                     components: [cp(.prism, 100, 80, 90)])),

        CodexEntry(id: 6, title: "Focal Length", tagline: "Where parallel rays meet",
                   paragraphs: [
                    "A converging lens deflects each ray by an amount proportional to how far off the optical axis it strikes the glass: the change in angle is minus h over f.",
                    "Rays that arrive parallel therefore all cross at one point, a distance f behind the lens. That distance is the focal length — 140 units for every lens on this bench.",
                    "A ray through the exact centre of a lens is not bent at all, which makes a lens a precision tool: slide it sideways and you dial the deflection continuously from zero to about fourteen degrees."
                   ],
                   scene: CodexScene(side: 240,
                                     emitters: [em(8, 60, 0, .green), em(8, 90, 0, .green), em(8, 120, 0, .green)],
                                     components: [cp(.convergingLens, 90, 90, 90)])),

        CodexEntry(id: 7, title: "Real vs Virtual Image", tagline: "Light that meets, and light that only seems to",
                   paragraphs: [
                    "A converging lens brings rays to a real crossing point: put a card there and an image appears on it. That is a real image.",
                    "A diverging lens does the opposite — the rays spread apart. Traced backwards they appear to come from a point on the near side of the lens, but no light ever passes through it. That is a virtual image, and no card will catch it.",
                    "On this bench only real light counts. A diverging lens is still useful: it widens an angle you overshot, and it is the only part that can push a beam away from the axis."
                   ],
                   scene: CodexScene(side: 240,
                                     emitters: [em(8, 60, 0, .blue), em(8, 90, 0, .blue), em(8, 120, 0, .blue)],
                                     components: [cp(.divergingLens, 90, 90, 90)])),

        CodexEntry(id: 8, title: "Beam Splitting", tagline: "Half through, half aside",
                   paragraphs: [
                    "A half-silvered mirror reflects part of the light and transmits the rest. The splitters here are an even 50/50, so each branch leaves with half the arriving intensity.",
                    "Both branches keep the colour and the polarisation they came in with. Only the brightness is divided.",
                    "Split twice and each of the three outputs carries a quarter or a half — which is why the multi-target levels set their thresholds so low. Watch the numbers, not the picture."
                   ],
                   scene: CodexScene(emitters: [em(8, 60, 0)],
                                     components: [cp(.beamSplitter, 110, 60, 45)],
                                     receptors: [rec(110, 190, [.red, .green, .blue], 0.15),
                                                 rec(200, 60, [.red, .green, .blue], 0.15)])),

        CodexEntry(id: 9, title: "Polarisation", tagline: "The direction a light wave shakes",
                   paragraphs: [
                    "Light is a transverse wave: its electric field oscillates at right angles to the direction it travels. The angle of that oscillation is the polarisation.",
                    "A polariser passes only the component of the field lying along its own axis. Whatever comes out is polarised along that axis, whatever it was before.",
                    "The emitters on this bench start out polarised at zero degrees. A receptor with an angle marked on it counts only light that arrives within twelve degrees of that angle."
                   ],
                   scene: CodexScene(emitters: [em(8, 80, 0, .green)],
                                     components: [cp(.polariser, 110, 80, 45)],
                                     receptors: [rec(200, 80, [.green], 0.1, pol: 45)])),

        CodexEntry(id: 10, title: "Malus's Law", tagline: "I = I₀ cos²θ",
                   paragraphs: [
                    "Pass polarised light through a polariser and the surviving intensity is the cosine squared of the angle between them. Aligned axes cost nothing; crossed axes pass nothing at all.",
                    "That leads to a result that looks impossible. Two polarisers at ninety degrees are dark. Slide a third one in between at forty five degrees and light appears — because each step is only a forty five degree turn, and cos²45° is one half.",
                    "Two crossed filters give zero. Three give a quarter. Chapter 5 is built on that one surprise."
                   ],
                   scene: CodexScene(emitters: [em(8, 80, 0, .green)],
                                     components: [cp(.polariser, 80, 80, 45), cp(.polariser, 150, 80, 90)],
                                     receptors: [rec(205, 80, [.green], 0.05, pol: 90)])),

        CodexEntry(id: 11, title: "Optical Fibre", tagline: "Light in a pipe",
                   paragraphs: [
                    "A fibre traps light by total internal reflection: the core has a higher index than the cladding, so every ray that enters within the acceptance cone keeps bouncing back inside.",
                    "The fibre portals on this bench are the idealised version. Light entering one end leaves the other with the same heading and ninety percent of its intensity.",
                    "That makes them the only part that can move a beam without changing where it is pointing — perfect for stepping past an absorber that blocks every straight route."
                   ],
                   scene: CodexScene(emitters: [em(8, 60, 0)],
                                     components: [cp(.fibrePortal, 90, 60, 0, pair: 0),
                                                  cp(.fibrePortal, 60, 160, 0, pair: 0)],
                                     receptors: [rec(190, 160, [.red, .green, .blue], 0.2)])),

        CodexEntry(id: 12, title: "Intensity Falloff", tagline: "Distance is not free",
                   paragraphs: [
                    "A real beam loses energy to scattering and absorption as it travels. This lab models that as a simple exponential: intensity is multiplied by e to the minus distance over 1400.",
                    "A straight crossing of a 400-unit bench keeps about seventy five percent. Fold the route three times and you are down near half before any component has taken its cut.",
                    "So when a receptor demands a high intensity, the answer is almost never another mirror. It is a shorter path — or the amplifier crystal."
                   ],
                   scene: CodexScene(emitters: [em(8, 30, 0)],
                                     components: [cp(.flatMirror, 190, 30, 45), cp(.flatMirror, 190, 190, 135)],
                                     receptors: [rec(30, 190, [.red, .green, .blue], 0.2)])),

        CodexEntry(id: 13, title: "Additive Colour", tagline: "Light adds, it does not mix",
                   paragraphs: [
                    "Paint subtracts: each pigment removes wavelengths. Light does the opposite — two beams landing on the same detector simply add.",
                    "Red plus green reads as yellow, green plus blue as cyan, red plus blue as magenta. All three together read as white.",
                    "Receptors here keep a separate running total for each band, so two half-strength beams of the same colour add up to one full-strength reading. That is how the multi-branch levels clear their thresholds."
                   ],
                   scene: CodexScene(emitters: [em(8, 50, 20.3, .red), em(8, 110, 0, .green), em(8, 170, -20.3, .blue)],
                                     receptors: [rec(170, 110, [.red, .green, .blue], 0.3, r: 14)])),

        CodexEntry(id: 14, title: "White Light", tagline: "Three bands travelling together",
                   paragraphs: [
                    "The white emitters here fire three coincident rays, one red, one green, one blue, each at full intensity. Until something separates them they behave as a single white beam.",
                    "A colour filter proves the point: put a green filter in a white beam and green comes out the other side, because the green was there all along.",
                    "Real white light is a continuous spectrum rather than three lines, but three bands are enough to make every rule on this bench — dispersion, filtering, purity, recombination — behave the way the real thing does."
                   ],
                   scene: CodexScene(emitters: [em(8, 80, 0)],
                                     components: [cp(.colourFilter, 110, 80, 0, band: .green)],
                                     receptors: [rec(200, 80, [.green], 0.2)]))
    ]
}

// MARK: - Static diagram

struct StaticBench: View {
    let scene: CodexScene
    let boardSide: CGFloat
    var colourBlind: Bool = false

    var body: some View {
        let t = BenchTransform(benchSide: scene.side, boardSide: boardSide)
        let trace = OpticsEngine.trace(benchSide: scene.side, emitters: scene.emitters,
                                       components: scene.components, receptors: scene.receptors,
                                       collectSegments: true)
        ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                var glow = ctx
                glow.blendMode = .plusLighter
                for s in trace.segments {
                    var p = Path()
                    p.move(to: t.toScreen(s.a))
                    p.addLine(to: t.toScreen(s.b))
                    let inten = min(1.4, max(0.05, s.intensity))
                    let (r, g, b) = Lab.beamRGB(s.band)
                    glow.stroke(p, with: .color(Color(.sRGB, red: r, green: g, blue: b, opacity: 0.18 * inten)),
                                style: StrokeStyle(lineWidth: 3 + 7 * CGFloat(inten), lineCap: .round))
                    glow.stroke(p, with: .color(Color(.sRGB, red: min(1, r + 0.25), green: min(1, g + 0.25),
                                                      blue: min(1, b + 0.25), opacity: 0.95)),
                                style: StrokeStyle(lineWidth: 0.9 + 2 * CGFloat(inten), lineCap: .round))
                }
            }
            .frame(width: boardSide, height: boardSide)

            ForEach(Array(scene.emitters.enumerated()), id: \.offset) { _, e in
                EmitterGlyph(size: t.len(44), angle: e.angle, band: e.band)
                    .position(CGPoint(x: max(t.len(16), t.toScreen(e.position).x),
                                      y: t.toScreen(e.position).y))
            }
            ForEach(Array(scene.components.enumerated()), id: \.offset) { _, c in
                ComponentGlyph(kind: c.kind, band: c.band, size: t.len(76), angle: c.angle,
                               pairLabel: c.kind == .fibrePortal ? (c.pairID == 0 ? "A" : "B") : nil,
                               colourBlind: colourBlind)
                    .position(t.toScreen(c.position))
            }
            ForEach(Array(scene.receptors.enumerated()), id: \.offset) { i, r in
                ReceptorGlyph(diameter: t.len(r.radius * 2.1), spec: r,
                              satisfied: trace.isSatisfied(i, r), colourBlind: colourBlind)
                    .position(t.toScreen(r.position))
            }
        }
        .frame(width: boardSide, height: boardSide)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(Lab.bench)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Lab.benchEdge, lineWidth: 1))
        )
        .clipped()
        .allowsHitTesting(false)
    }
}

// MARK: - List + detail

struct CodexView: View {
    @EnvironmentObject var store: LabStore

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let width = min(geo.size.width, UIScreen.main.bounds.width)
                ScrollView {
                    VStack(spacing: 10) {
                        VStack(spacing: 3) {
                            Text("OPTICS CODEX")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(Lab.dim).tracking(2.2)
                            Text("\(store.progress.codexRead.count) of \(CodexLibrary.entries.count) entries read")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Lab.muted)
                        }
                        .padding(.vertical, 10)

                        ForEach(CodexLibrary.entries) { entry in
                            NavigationLink(destination: CodexDetailView(entry: entry)) {
                                row(entry, width: width)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(width: width)
                    .padding(.bottom, 28)
                }
                .frame(width: geo.size.width)
            }
            .background(Lab.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func row(_ entry: CodexEntry, width: CGFloat) -> some View {
        let read = store.progress.codexRead.contains(entry.id)
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(Lab.hex(0x18213E))
                Text("\(entry.id)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(read ? Lab.cyan : Lab.muted)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.ivory)
                Text(entry.tagline)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(Lab.dim)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if read {
                CheckShape().stroke(Lab.ok, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 13, height: 13)
            }
            ChevronShape()
                .stroke(Lab.dim, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 7, height: 12)
        }
        .padding(12)
        .frame(width: width - 24)
        .labCard()
        .contentShape(Rectangle())
    }
}

struct CodexDetailView: View {
    let entry: CodexEntry
    @EnvironmentObject var store: LabStore

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let board = min(width - 40, 320)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ENTRY \(entry.id)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(Lab.cyan).tracking(1.8)
                        Text(entry.title)
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundColor(Lab.ivory)
                        Text(entry.tagline)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Lab.amber)
                    }

                    HStack {
                        Spacer(minLength: 0)
                        StaticBench(scene: entry.scene, boardSide: board,
                                    colourBlind: store.progress.colourBlind)
                        Spacer(minLength: 0)
                    }

                    Text("Traced live by the same engine that runs the campaign.")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundColor(Lab.dim)
                        .frame(maxWidth: .infinity, alignment: .center)

                    ForEach(Array(entry.paragraphs.enumerated()), id: \.offset) { _, p in
                        Text(p)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(Lab.hex(0xC9D2EC))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 34)
                .frame(width: width, alignment: .leading)
            }
            .frame(width: geo.size.width)
        }
        .background(Lab.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.markCodexRead(entry.id) }
        .navigationBarHidden(false)
        .navigationTitle("Codex")
    }
}
