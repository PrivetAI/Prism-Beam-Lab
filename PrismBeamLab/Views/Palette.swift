//  Palette.swift
//  Prism Beam Lab
//
//  Every colour in the app is defined here as an explicit RGB constant so the UI looks
//  identical whether the device is in light or dark appearance.

import SwiftUI

enum Lab {
    static func hex(_ v: UInt32, _ alpha: Double = 1) -> Color {
        Color(.sRGB,
              red: Double((v >> 16) & 0xFF) / 255.0,
              green: Double((v >> 8) & 0xFF) / 255.0,
              blue: Double(v & 0xFF) / 255.0,
              opacity: alpha)
    }

    static let background   = hex(0x0A0E1F)
    static let bench        = hex(0x141A33)
    static let benchEdge    = hex(0x243258)
    static let grid         = hex(0x1F2A4A)
    static let panel        = hex(0x121A31)
    static let panelRaised  = hex(0x1A2340)
    static let cyan         = hex(0x4FE3F5)
    static let amber        = hex(0xF5B23B)
    static let ivory        = hex(0xEDEFF7)
    static let muted        = hex(0x8C97BC)
    static let dim          = hex(0x5C688C)
    static let danger       = hex(0xFF6B7A)
    static let ok           = hex(0x3DF08A)

    static let beamRed      = hex(0xFF4D5E)
    static let beamGreen    = hex(0x3DF08A)
    static let beamBlue     = hex(0x4D8BFF)
    static let beamWhite    = hex(0xFFFFFF)

    static func beam(_ band: Band) -> Color {
        switch band {
        case .red: return beamRed
        case .green: return beamGreen
        case .blue: return beamBlue
        }
    }

    /// Raw components for additive Canvas strokes.
    static func beamRGB(_ band: Band) -> (Double, Double, Double) {
        switch band {
        case .red: return (1.0, 0.302, 0.369)
        case .green: return (0.239, 0.941, 0.541)
        case .blue: return (0.302, 0.545, 1.0)
        }
    }

    static func componentTint(_ kind: ComponentKind) -> Color {
        switch kind {
        case .flatMirror:      return cyan
        case .prism:           return hex(0x9CE6FF)
        case .convergingLens:  return hex(0x7FD8FF)
        case .divergingLens:   return hex(0xB08CFF)
        case .colourFilter:    return ivory
        case .beamSplitter:    return hex(0x7FF0D8)
        case .polariser:       return amber
        case .amplifier:       return hex(0xFFD166)
        case .fibrePortal:     return hex(0xFF8FD0)
        case .absorber:        return hex(0x394668)
        case .receptor:        return ok
        }
    }
}

/// Rounded card background used across every screen.
struct LabCard: ViewModifier {
    var fill: Color = Lab.panel
    var stroke: Color = Lab.hex(0x243258)
    var radius: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(stroke, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func labCard(fill: Color = Lab.panel, stroke: Color = Lab.hex(0x243258), radius: CGFloat = 14) -> some View {
        modifier(LabCard(fill: fill, stroke: stroke, radius: radius))
    }

    /// Clamp a layout to the visible screen width and centre it — iPad compatibility mode
    /// reports a wider GeometryReader than is actually on screen.
    func labClampWidth(_ proposed: CGFloat) -> some View {
        self.frame(width: min(proposed, UIScreen.main.bounds.width))
    }
}
