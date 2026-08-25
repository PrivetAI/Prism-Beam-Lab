//  MoreView.swift
//  Prism Beam Lab
//
//  The fifth tab: progress dashboard, settings and a short how-to-play reference.

import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: LabStore

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let width = min(geo.size.width, UIScreen.main.bounds.width)
                ScrollView {
                    VStack(spacing: 12) {
                        VStack(spacing: 3) {
                            Text("PRISM BEAM LAB")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(Lab.dim).tracking(2.4)
                            Text("\(store.progress.totalStars) stars  ·  \(store.progress.solvedCount) benches solved")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Lab.muted)
                        }
                        .padding(.vertical, 10)

                        NavigationLink(destination: ProgressDashboardView()) {
                            navRow(width: width, title: "Progress", subtitle: "Stars, chapter chart, fastest solves") {
                                AnyView(ArcProgressShape(fraction: 0.72)
                                    .stroke(Lab.cyan, style: StrokeStyle(lineWidth: 2.6, lineCap: .round)))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: SettingsView()) {
                            navRow(width: width, title: "Settings", subtitle: "Sound, haptics, colour-blind mode, privacy") {
                                AnyView(GearShape().stroke(Lab.cyan, lineWidth: 1.6))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: HowToPlayView()) {
                            navRow(width: width, title: "How To Play", subtitle: "Controls, stars and hint tokens") {
                                AnyView(BookShape().stroke(Lab.cyan, lineWidth: 1.5))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
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

    private func navRow(width: CGFloat, title: String, subtitle: String,
                        icon: () -> AnyView) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Lab.hex(0x18213E))
                icon().frame(width: 20, height: 20)
            }
            .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.ivory)
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular, design: .rounded))
                    .foregroundColor(Lab.dim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            ChevronShape()
                .stroke(Lab.dim, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 8, height: 14)
        }
        .padding(14)
        .frame(width: width - 24)
        .labCard()
        .contentShape(Rectangle())
    }
}

struct HowToPlayView: View {
    private let sections: [(String, [String])] = [
        ("The bench", [
            "A lamp fires light across the bench. Your job is to land it on every receptor at once.",
            "Angles are continuous — nothing snaps to a grid. A mirror turned one degree swings the beam by two."
        ]),
        ("Placing parts", [
            "Tap a part in the tray, then tap the bench to drop it there. You can also drag a part straight out of the tray.",
            "Tap a placed part to select it, drag it to move it, and use the dial ring around it to rotate.",
            "Long-press the dial, or use the 5°/1° button, to switch between coarse and fine rotation."
        ]),
        ("Receptors", [
            "A receptor shows the colour it wants. Some also demand a minimum intensity, and some a polarisation angle within twelve degrees.",
            "A receptor marked as pure rejects the reading if any other colour band lands on it — filter or disperse the beam first.",
            "Open the target button in the HUD to see exactly what each receptor is currently receiving."
        ]),
        ("Stars", [
            "One star for solving the bench at all.",
            "A second star for solving it with no more than the par number of parts.",
            "A third for meeting par on parts and on rotation adjustments."
        ]),
        ("Hints", [
            "Every three stars earns one hint token.",
            "Spending a token reveals the position and angle of one part from the reference solution — the earliest one you have not matched yet.",
            "Hint usage is logged per level and shown on the Progress screen."
        ])
    ]

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.0.uppercased())
                                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                .foregroundColor(Lab.cyan).tracking(1.6)
                            ForEach(Array(section.1.enumerated()), id: \.offset) { _, line in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(Lab.dim).frame(width: 4, height: 4).padding(.top, 7)
                                    Text(line)
                                        .font(.system(size: 13.5, weight: .regular, design: .rounded))
                                        .foregroundColor(Lab.hex(0xC9D2EC))
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(14)
                        .frame(width: width - 24, alignment: .leading)
                        .labCard()
                    }
                }
                .frame(width: width)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
            .frame(width: geo.size.width)
        }
        .background(Lab.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .navigationTitle("How To Play")
    }
}
