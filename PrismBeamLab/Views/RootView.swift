//  RootView.swift
//  Prism Beam Lab
//
//  Custom tab bar — SwiftUI's TabView only renders Image + Text in .tabItem, so every custom
//  glyph would be invisible. This is an HStack of Buttons plus a switch on the content.

import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: LabStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Lab.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch store.tab {
                    case 0: BenchTab()
                    case 1: ChaptersView()
                    case 2: CodexView()
                    case 3: SandboxView()
                    default: MoreView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
        .onChange(of: scenePhase) { phase in
            // Only .background — .inactive also fires on the way IN and must not be treated
            // as "the app is leaving" (BATCH_BRIEF §7.15).
            if phase == .background { store.saveNow() }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Bench") { active in
                AnyView(ZStack {
                    TriangleShape()
                        .stroke(active ? Lab.cyan : Lab.dim, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                        .frame(width: 19, height: 16)
                    Rectangle()
                        .fill(active ? Lab.amber : Lab.dim)
                        .frame(width: 22, height: 1.6)
                        .offset(y: 2)
                })
            }
            tabButton(1, "Chapters") { active in
                AnyView(GridIconShape().stroke(active ? Lab.cyan : Lab.dim, lineWidth: 1.7)
                    .frame(width: 18, height: 18))
            }
            tabButton(2, "Codex") { active in
                AnyView(BookShape().stroke(active ? Lab.cyan : Lab.dim, lineWidth: 1.5)
                    .frame(width: 19, height: 18))
            }
            tabButton(3, "Sandbox") { active in
                AnyView(FlaskShape().stroke(active ? Lab.cyan : Lab.dim,
                                            style: StrokeStyle(lineWidth: 1.7, lineJoin: .round))
                    .frame(width: 17, height: 19))
            }
            tabButton(4, "More") { active in
                AnyView(DotsShape().fill(active ? Lab.cyan : Lab.dim)
                    .frame(width: 18, height: 6))
            }
        }
        .padding(.top, 7)
        .padding(.bottom, 3)
        .background(
            Lab.panel
                .overlay(Rectangle().fill(Lab.hex(0x222C4B)).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, _ label: String,
                           icon: @escaping (Bool) -> AnyView) -> some View {
        let active = store.tab == index
        return Button {
            if store.tab != index { store.tapFeedback() }
            store.tab = index
        } label: {
            VStack(spacing: 3) {
                icon(active)
                    .frame(height: 20)
                Text(label)
                    .font(.system(size: 9.5, weight: active ? .bold : .medium, design: .rounded))
                    .foregroundColor(active ? Lab.cyan : Lab.dim)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
