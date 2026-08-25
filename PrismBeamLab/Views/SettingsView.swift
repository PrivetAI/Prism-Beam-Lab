//  SettingsView.swift
//  Prism Beam Lab

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: LabStore
    @State private var showPrivacy = false
    @State private var confirmReset = false

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            ScrollView {
                VStack(spacing: 12) {
                    group(width: width, title: "BENCH") {
                        toggleRow("Sound effects", isOn: Binding(
                            get: { store.progress.soundOn },
                            set: { store.progress.soundOn = $0 }))
                        divider
                        toggleRow("Haptics", isOn: Binding(
                            get: { store.progress.hapticsOn },
                            set: { store.progress.hapticsOn = $0 }))
                        divider
                        toggleRow("Start rotation in 1° fine mode", isOn: Binding(
                            get: { store.progress.fineSnapDefault },
                            set: { store.progress.fineSnapDefault = $0 }))
                    }

                    group(width: width, title: "ACCESSIBILITY") {
                        toggleRow("Colour-blind mode", isOn: Binding(
                            get: { store.progress.colourBlind },
                            set: { store.progress.colourBlind = $0 }))
                        Text("Tags every beam and receptor with its band letter (R, G, B) so colour is never the only cue.")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(Lab.dim)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                        divider
                        toggleRow("Always label beams", isOn: Binding(
                            get: { store.progress.showBeamLabels },
                            set: { store.progress.showBeamLabels = $0 }))
                    }

                    group(width: width, title: "DATA") {
                        Button {
                            confirmReset = true
                            store.tapFeedback()
                        } label: {
                            HStack {
                                Text("Reset all progress")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Lab.danger)
                                Spacer()
                                ChevronShape()
                                    .stroke(Lab.danger.opacity(0.6),
                                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .frame(width: 7, height: 12)
                            }
                            .frame(height: 38)
                            .contentShape(Rectangle())
                        }
                        divider
                        Button {
                            showPrivacy = true
                            store.tapFeedback()
                        } label: {
                            HStack {
                                Text("Privacy Policy")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Lab.ivory)
                                Spacer()
                                ChevronShape()
                                    .stroke(Lab.dim, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .frame(width: 7, height: 12)
                            }
                            .frame(height: 38)
                            .contentShape(Rectangle())
                        }
                    }

                    group(width: width, title: "ABOUT") {
                        infoRow("Levels", "\(LevelLibrary.count) across \(Chapters.all.count) chapters")
                        divider
                        infoRow("Components", "\(ComponentKind.allCases.count) optical parts")
                        divider
                        infoRow("Codex", "\(CodexLibrary.entries.count) illustrated entries")
                        divider
                        infoRow("Storage", "On this device only")
                        Text("Prism Beam Lab traces every beam with a continuous-angle ray model: Snell refraction with a per-band refractive index, Malus's law for polarisation, thin-lens deflection and exponential intensity falloff. Nothing is on a grid.")
                            .font(.system(size: 11.5, weight: .regular, design: .rounded))
                            .foregroundColor(Lab.dim)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                }
                .frame(width: width)
                .padding(.top, 8)
                .padding(.bottom, 34)
            }
            .frame(width: geo.size.width)
        }
        .background(Lab.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .navigationTitle("Settings")
        .alert(isPresented: $confirmReset) {
            Alert(title: Text("Reset all progress?"),
                  message: Text("Every star, hint token, codex mark and sandbox slot will be erased. This cannot be undone."),
                  primaryButton: .destructive(Text("Erase")) {
                      store.resetEverything()
                  },
                  secondaryButton: .cancel(Text("Keep")))
        }
        // Exactly ONE .sheet on this view — iOS 15 honours only the last one declared.
        .sheet(isPresented: $showPrivacy) {
            PrismWebPanel(urlString: "https://crazylights.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
                .preferredColorScheme(.dark)
        }
    }

    private var divider: some View {
        Rectangle().fill(Lab.hex(0x1E2743)).frame(height: 1)
    }

    private func group<C: View>(width: CGFloat, title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.dim).tracking(1.6)
            VStack(alignment: .leading, spacing: 4) { content() }
        }
        .padding(16)
        .frame(width: width - 24, alignment: .leading)
        .labCard()
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Lab.ivory)
            Spacer(minLength: 8)
            LabToggle(isOn: isOn)
        }
        .frame(height: 38)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundColor(Lab.ivory)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundColor(Lab.muted)
        }
        .frame(height: 34)
    }
}

/// Custom switch — the system Toggle would follow the device appearance.
struct LabToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Lab.cyan : Lab.hex(0x27314F))
                    .frame(width: 46, height: 27)
                Circle()
                    .fill(isOn ? Lab.background : Lab.muted)
                    .frame(width: 21, height: 21)
                    .padding(.horizontal, 3)
            }
            .frame(width: 46, height: 27)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
