//  PrismLoadingScreen.swift
//  Prism Beam Lab
//
//  Splash shown while the launch check runs. A prism quietly splitting a beam, drawn with the
//  same shapes the game uses.

import SwiftUI

struct PrismLoadingScreen: View {
    @State private var sweep: Double = 0

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let art = min(width * 0.62, 240)
            ZStack {
                Lab.background.ignoresSafeArea()
                VStack(spacing: 22) {
                    Spacer(minLength: 20)

                    ZStack {
                        // incoming white beam
                        Rectangle()
                            .fill(LinearGradient(colors: [Lab.beamWhite.opacity(0), Lab.beamWhite],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: art * 0.44, height: 3)
                            .offset(x: -art * 0.36)

                        // dispersed fan
                        ForEach(0..<3, id: \.self) { i in
                            let band: Band = [.red, .green, .blue][i]
                            Rectangle()
                                .fill(LinearGradient(colors: [Lab.beam(band), Lab.beam(band).opacity(0)],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: art * 0.50, height: 3)
                                .rotationEffect(.degrees(Double(i - 1) * 13), anchor: .leading)
                                .offset(x: art * 0.06)
                                .opacity(0.35 + 0.65 * fanOpacity(i))
                        }

                        TriangleShape()
                            .fill(LinearGradient(colors: [Lab.hex(0xBFEFFF, 0.35), Lab.hex(0x2A5B8C, 0.55)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: art * 0.42, height: art * 0.38)
                            .overlay(
                                TriangleShape()
                                    .stroke(Lab.cyan, lineWidth: 2)
                                    .frame(width: art * 0.42, height: art * 0.38)
                            )
                    }
                    .frame(width: art, height: art * 0.6)

                    VStack(spacing: 6) {
                        Text("PRISM BEAM LAB")
                            .font(.system(size: 21, weight: .heavy, design: .rounded))
                            .foregroundColor(Lab.ivory)
                            .tracking(2.4)
                        Text("Continuous-angle optics puzzles")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Lab.muted)
                    }

                    HStack(spacing: 7) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(Lab.beam([Band.red, .green, .blue][i]))
                                .frame(width: 7, height: 7)
                                .opacity(0.3 + 0.7 * fanOpacity(i))
                        }
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 30)
                }
                .frame(width: width)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: true)) {
                sweep = 1
            }
        }
    }

    private func fanOpacity(_ i: Int) -> Double {
        let phase = sweep + Double(i) * 0.22
        return 0.5 + 0.5 * sin(phase * .pi * 2)
    }
}
