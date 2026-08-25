//  LabIcons.swift
//  Prism Beam Lab
//
//  Every glyph in the app is a hand-drawn SwiftUI Shape. No SF Symbols, no system images,
//  no emoji anywhere.

import SwiftUI

// MARK: - Primitive shapes

struct StarShape: Shape {
    var points: Int = 5
    var inner: CGFloat = 0.44
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? r : r * inner
            let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            let pt = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct LensLentil: Shape {
    /// 1 = converging (bulging), -1 = diverging (waisted)
    var sign: CGFloat = 1
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let bulge = w * 0.5 * sign
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                       control: CGPoint(x: rect.midX + bulge, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                       control: CGPoint(x: rect.midX - bulge, y: rect.midY))
        p.closeSubpath()
        _ = h
        return p
    }
}

struct ChevronShape: Shape {
    var pointsRight: Bool = true
    func path(in rect: CGRect) -> Path {
        var p = Path()
        if pointsRight {
            p.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.maxY))
        }
        return p
    }
}

struct LockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let bodyH = rect.height * 0.55
        let body = CGRect(x: rect.minX + rect.width * 0.12, y: rect.maxY - bodyH,
                          width: rect.width * 0.76, height: bodyH)
        p.addRoundedRect(in: body, cornerSize: CGSize(width: rect.width * 0.14, height: rect.width * 0.14))
        let shackleR = rect.width * 0.26
        let cx = rect.midX
        let cy = rect.maxY - bodyH
        p.move(to: CGPoint(x: cx - shackleR, y: cy))
        p.addArc(center: CGPoint(x: cx, y: cy), radius: shackleR,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return p
    }
}

struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.2))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.22))
        return p
    }
}

struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

struct PlusShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

struct MinusShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

struct UndoArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.36
        let c = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.06)
        p.addArc(center: c, radius: r, startAngle: .degrees(160), endAngle: .degrees(-40), clockwise: false)
        let tip = CGPoint(x: c.x + cos(CGFloat.pi * 160 / 180) * r, y: c.y + sin(CGFloat.pi * 160 / 180) * r)
        p.move(to: CGPoint(x: tip.x - r * 0.05, y: tip.y - r * 0.55))
        p.addLine(to: tip)
        p.addLine(to: CGPoint(x: tip.x + r * 0.55, y: tip.y + r * 0.1))
        return p
    }
}

struct ResetShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.36
        let c = CGPoint(x: rect.midX, y: rect.midY)
        p.addArc(center: c, radius: r, startAngle: .degrees(-60), endAngle: .degrees(210), clockwise: false)
        let a = CGFloat.pi * -60 / 180
        let tip = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        p.move(to: CGPoint(x: tip.x - r * 0.5, y: tip.y - r * 0.15))
        p.addLine(to: tip)
        p.addLine(to: CGPoint(x: tip.x + r * 0.1, y: tip.y + r * 0.52))
        return p
    }
}

struct BulbShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.34
        let c = CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.1)
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        p.move(to: CGPoint(x: c.x - r * 0.55, y: c.y + r * 0.92))
        p.addLine(to: CGPoint(x: c.x - r * 0.45, y: rect.maxY - rect.height * 0.06))
        p.addLine(to: CGPoint(x: c.x + r * 0.45, y: rect.maxY - rect.height * 0.06))
        p.addLine(to: CGPoint(x: c.x + r * 0.55, y: c.y + r * 0.92))
        return p
    }
}

struct GearShape: Shape {
    var teeth: Int = 8
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.72
        let steps = teeth * 2
        for i in 0..<steps {
            let radius = i % 2 == 0 ? outer : inner
            let a = CGFloat(i) * .pi * 2 / CGFloat(steps)
            let pt = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        let hole = outer * 0.34
        p.addEllipse(in: CGRect(x: c.x - hole, y: c.y - hole, width: hole * 2, height: hole * 2))
        return p
    }
}

struct BookShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.16))
        p.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.1),
                       control: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY - rect.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.04),
                       control: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.maxY - rect.height * 0.16))
        p.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.maxY - rect.height * 0.1),
                       control: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.maxY - rect.height * 0.16))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.16),
                       control: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.minY))
        p.closeSubpath()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.16))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.04))
        return p
    }
}

struct GridIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let gap = rect.width * 0.14
        let s = (rect.width - gap) / 2
        for r in 0..<2 {
            for c in 0..<2 {
                p.addRoundedRect(in: CGRect(x: rect.minX + CGFloat(c) * (s + gap),
                                            y: rect.minY + CGFloat(r) * (s + gap),
                                            width: s, height: s),
                                 cornerSize: CGSize(width: s * 0.22, height: s * 0.22))
            }
        }
        return p
    }
}

struct FlaskShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let neckW = rect.width * 0.26
        p.move(to: CGPoint(x: rect.midX - neckW / 2, y: rect.minY + rect.height * 0.06))
        p.addLine(to: CGPoint(x: rect.midX - neckW / 2, y: rect.minY + rect.height * 0.4))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY - rect.height * 0.08))
        p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.maxY - rect.height * 0.08))
        p.addLine(to: CGPoint(x: rect.midX + neckW / 2, y: rect.minY + rect.height * 0.4))
        p.addLine(to: CGPoint(x: rect.midX + neckW / 2, y: rect.minY + rect.height * 0.06))
        p.closeSubpath()
        return p
    }
}

struct DotsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width * 0.11
        for i in 0..<3 {
            let x = rect.minX + r + CGFloat(i) * (rect.width - r * 2) / 2
            p.addEllipse(in: CGRect(x: x - r, y: rect.midY - r, width: r * 2, height: r * 2))
        }
        return p
    }
}

struct WaveShape: Shape {
    var cycles: Int = 2
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let n = 48
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let x = rect.minX + t * rect.width
            let y = rect.midY - sin(t * .pi * 2 * CGFloat(cycles)) * rect.height * 0.38
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        return p
    }
}

struct TargetRingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        p.addEllipse(in: CGRect(x: c.x - r * 0.45, y: c.y - r * 0.45, width: r * 0.9, height: r * 0.9))
        return p
    }
}

struct RingShape: Shape {
    var thickness: CGFloat = 0.2
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        let ir = r * (1 - thickness)
        p.addEllipse(in: CGRect(x: c.x - ir, y: c.y - ir, width: ir * 2, height: ir * 2))
        return p
    }
}

struct ArcProgressShape: Shape {
    var fraction: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        p.addArc(center: c, radius: r, startAngle: .degrees(-90),
                 endAngle: .degrees(-90 + 360 * max(0, min(1, fraction))), clockwise: false)
        return p
    }
}

// MARK: - Component glyph

/// A component drawn to scale, in its own local box. `size` is the box side in points.
struct ComponentGlyph: View {
    let kind: ComponentKind
    let band: Band?
    var size: CGFloat
    var angle: Double = 0            // radians
    var tint: Color? = nil
    var locked: Bool = false
    var pairLabel: String? = nil
    var colourBlind: Bool = false

    private var colour: Color { tint ?? Lab.componentTint(kind) }

    var body: some View {
        ZStack {
            switch kind {
            case .flatMirror:
                barBody(fill: LinearGradient(colors: [Lab.hex(0xEAF6FF), Lab.hex(0x6FA8C4)],
                                             startPoint: .top, endPoint: .bottom),
                        widthFraction: 0.90, thickness: 0.14)
            case .beamSplitter:
                ZStack {
                    barBody(fill: LinearGradient(colors: [Lab.hex(0xBFF6E6, 0.95), Lab.hex(0x2E7F70, 0.95)],
                                                 startPoint: .top, endPoint: .bottom),
                            widthFraction: 0.90, thickness: 0.14)
                    Rectangle()
                        .fill(Lab.hex(0x0A0E1F, 0.55))
                        .frame(width: size * 0.90, height: size * 0.04)
                        .rotationEffect(.radians(angle))
                }
            case .convergingLens:
                lensBody(sign: 1)
            case .divergingLens:
                lensBody(sign: -1)
            case .prism:
                prismBody
            case .colourFilter:
                filterBody
            case .polariser:
                polariserBody
            case .amplifier:
                amplifierBody
            case .fibrePortal:
                portalBody
            case .absorber:
                absorberBody
            case .receptor:
                // Drawn small: the live ReceptorGlyph sits on top of it, this is just the
                // grab handle so a sandbox receptor can be selected, moved and removed.
                Circle()
                    .stroke(Lab.ok.opacity(0.55), style: StrokeStyle(lineWidth: max(1, size * 0.03), dash: [3, 3]))
                    .frame(width: size * 0.40, height: size * 0.40)
            }

            if locked {
                LockShape()
                    .fill(Lab.hex(0x0A0E1F, 0.85))
                    .frame(width: size * 0.26, height: size * 0.26)
                    .offset(x: size * 0.30, y: -size * 0.30)
                    .overlay(
                        LockShape()
                            .stroke(Lab.amber, lineWidth: 1.2)
                            .frame(width: size * 0.26, height: size * 0.26)
                            .offset(x: size * 0.30, y: -size * 0.30)
                    )
            }
        }
        .frame(width: size, height: size)
    }

    private func barBody<S: ShapeStyle>(fill: S, widthFraction: CGFloat, thickness: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * thickness * 0.4)
            .fill(fill)
            .frame(width: size * widthFraction, height: size * thickness)
            .overlay(
                RoundedRectangle(cornerRadius: size * thickness * 0.4)
                    .stroke(Lab.hex(0x0A0E1F, 0.6), lineWidth: 0.8)
                    .frame(width: size * widthFraction, height: size * thickness)
            )
            .rotationEffect(.radians(angle))
    }

    private func lensBody(sign: CGFloat) -> some View {
        LensLentil(sign: sign)
            .fill(LinearGradient(colors: [colour.opacity(0.85), colour.opacity(0.35)],
                                 startPoint: .leading, endPoint: .trailing))
            .overlay(LensLentil(sign: sign).stroke(colour, lineWidth: 1.2))
            .frame(width: size * 0.30, height: size * 0.92)
            .rotationEffect(.radians(angle + .pi / 2))
    }

    private var prismBody: some View {
        TriangleShape()
            .fill(LinearGradient(colors: [Lab.hex(0xBFEFFF, 0.55), Lab.hex(0x2A5B8C, 0.75)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(TriangleShape().stroke(Lab.hex(0xBFEFFF), lineWidth: 1.4))
            .frame(width: size * 0.92, height: size * 0.80)
            .rotationEffect(.radians(angle + .pi / 2))
    }

    private var filterBody: some View {
        let c = band.map { Lab.beam($0) } ?? Lab.ivory
        return ZStack {
            Circle().fill(c.opacity(0.30))
            Circle().stroke(c, lineWidth: size * 0.07)
            if colourBlind, let b = band {
                Text(b.letter)
                    .font(.system(size: size * 0.34, weight: .heavy, design: .rounded))
                    .foregroundColor(c)
            }
        }
        .frame(width: size * 0.88, height: size * 0.88)
    }

    private var polariserBody: some View {
        ZStack {
            Circle().fill(Lab.hex(0x1B2647, 0.9))
            Circle().stroke(Lab.amber, lineWidth: size * 0.06)
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Rectangle()
                        .fill(Lab.amber.opacity(0.75))
                        .frame(width: size * 0.72, height: size * 0.035)
                        .offset(y: CGFloat(i - 2) * size * 0.15)
                }
            }
            .rotationEffect(.radians(angle))
            .mask(Circle().frame(width: size * 0.82, height: size * 0.82))
        }
        .frame(width: size * 0.88, height: size * 0.88)
    }

    private var amplifierBody: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Lab.hex(0xFFE9A8), Lab.hex(0x8A6410)],
                                         center: .center, startRadius: 0, endRadius: size * 0.44))
            Circle().stroke(Lab.amber, lineWidth: size * 0.06)
            ForEach(0..<3, id: \.self) { i in
                ChevronShape()
                    .stroke(Lab.hex(0x2A1E00), style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.26, height: size * 0.40)
                    .offset(x: CGFloat(i - 1) * size * 0.20)
            }
        }
        .frame(width: size * 0.88, height: size * 0.88)
    }

    private var portalBody: some View {
        ZStack {
            Circle().fill(Lab.hex(0x2A1030, 0.9))
            Circle().stroke(Lab.hex(0xFF8FD0), lineWidth: size * 0.09)
            Circle().stroke(Lab.hex(0xFF8FD0, 0.5), lineWidth: size * 0.04)
                .frame(width: size * 0.48, height: size * 0.48)
            if let label = pairLabel {
                Text(label)
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.hex(0xFFD3EC))
            }
        }
        .frame(width: size * 0.86, height: size * 0.86)
    }

    private var absorberBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(Lab.hex(0x2A3352))
            RoundedRectangle(cornerRadius: size * 0.08)
                .stroke(Lab.hex(0x475782), lineWidth: 1.2)
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(Lab.hex(0x151C33))
                    .frame(width: size * 0.86, height: size * 0.045)
                    .offset(y: CGFloat(i) * size * 0.16 - size * 0.24)
            }
        }
        .frame(width: size * 0.86, height: size * 0.86)
        .rotationEffect(.radians(angle))
    }
}

// MARK: - Emitter glyph

struct EmitterGlyph: View {
    var size: CGFloat
    var angle: Double
    var band: Band?

    var body: some View {
        let c = band.map { Lab.beam($0) } ?? Lab.beamWhite
        return ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(LinearGradient(colors: [Lab.hex(0x33406B), Lab.hex(0x1A2340)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.86, height: size * 0.62)
            RoundedRectangle(cornerRadius: size * 0.18)
                .stroke(Lab.cyan.opacity(0.8), lineWidth: 1.2)
                .frame(width: size * 0.86, height: size * 0.62)
            Circle()
                .fill(c)
                .frame(width: size * 0.26, height: size * 0.26)
                .offset(x: size * 0.28)
            Circle()
                .fill(c.opacity(0.25))
                .frame(width: size * 0.48, height: size * 0.48)
                .offset(x: size * 0.28)
        }
        .frame(width: size, height: size)
        .rotationEffect(.radians(angle))
    }
}

// MARK: - Receptor glyph

struct ReceptorGlyph: View {
    var diameter: CGFloat
    var spec: ReceptorSpec
    var satisfied: Bool
    var colourBlind: Bool

    private var ringColour: Color {
        if satisfied { return Lab.ok }
        if spec.isWhiteTarget { return Lab.beamWhite.opacity(0.75) }
        if spec.bands.count == 1 { return Lab.beam(spec.bands[0]) }
        return Lab.cyan
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [ringColour.opacity(satisfied ? 0.55 : 0.18), .clear],
                                     center: .center, startRadius: 0, endRadius: diameter * 0.5))
            Circle()
                .stroke(ringColour, lineWidth: max(1.5, diameter * 0.10))
            Circle()
                .stroke(ringColour.opacity(0.55), lineWidth: max(1, diameter * 0.05))
                .frame(width: diameter * 0.48, height: diameter * 0.48)
            if colourBlind {
                Text(spec.label)
                    .font(.system(size: max(7, diameter * 0.30), weight: .heavy, design: .rounded))
                    .foregroundColor(ringColour)
                    .offset(y: diameter * 0.62)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}
