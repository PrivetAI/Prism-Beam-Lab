//  ProgressDashboardView.swift
//  Prism Beam Lab
//
//  Stars, per-chapter breakdown, a hand-drawn Canvas bar chart (no Charts framework — it is
//  iOS 16+), fastest solves and hint usage.

import SwiftUI

struct ProgressDashboardView: View {
    @EnvironmentObject var store: LabStore

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            ScrollView {
                VStack(spacing: 12) {
                    summaryCard(width: width)
                    chartCard(width: width)
                    chapterCard(width: width)
                    fastestCard(width: width)
                    hintCard(width: width)
                }
                .frame(width: width)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .frame(width: geo.size.width)
        }
        .background(Lab.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .navigationTitle("Progress")
    }

    // MARK: cards

    private func summaryCard(width: CGFloat) -> some View {
        let stars = store.progress.totalStars
        let maxStars = LevelLibrary.maxStars
        return VStack(spacing: 10) {
            HStack(spacing: 18) {
                bigStat("\(stars)", "STARS", Lab.amber)
                bigStat("\(store.progress.solvedCount)", "SOLVED", Lab.cyan)
                bigStat("\(store.progress.hintTokensAvailable)", "HINTS", Lab.ok)
            }
            ZStack(alignment: .leading) {
                Capsule().fill(Lab.hex(0x1E2743)).frame(height: 8)
                Capsule().fill(LinearGradient(colors: [Lab.cyan, Lab.amber],
                                              startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, (width - 60) * CGFloat(Double(stars) / Double(maxStars))), height: 8)
            }
            .frame(width: width - 60)
            Text("\(stars) of \(maxStars) stars  ·  \(percent(Double(stars) / Double(maxStars))) complete")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Lab.muted)
        }
        .padding(16)
        .frame(width: width - 24)
        .labCard()
    }

    private func bigStat(_ value: String, _ label: String, _ colour: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(colour)
            Text(label)
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundColor(Lab.dim).tracking(1.4)
        }
        .frame(minWidth: 74)
    }

    private func chartCard(width: CGFloat) -> some View {
        let w = width - 24
        let chartW = w - 32
        let chartH: CGFloat = 130
        let data = Chapters.all.map { info -> (String, Double, Int, Int) in
            let earned = store.progress.stars(inChapter: info.index)
            let total = info.range.count * 3
            return ("\(info.index)", Double(earned) / Double(total), earned, total)
        }
        return VStack(alignment: .leading, spacing: 8) {
            Text("STARS BY CHAPTER")
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.dim).tracking(1.6)
            Canvas { ctx, _ in
                let n = data.count
                let gap: CGFloat = 12
                let barW = (chartW - gap * CGFloat(n - 1)) / CGFloat(n)
                // baseline + gridlines
                for f in [0.0, 0.25, 0.5, 0.75, 1.0] {
                    var p = Path()
                    let y = chartH - CGFloat(f) * (chartH - 18)
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: chartW, y: y))
                    ctx.stroke(p, with: .color(Lab.grid), lineWidth: f == 0 ? 1.2 : 0.6)
                }
                for (i, d) in data.enumerated() {
                    let x = CGFloat(i) * (barW + gap)
                    let h = max(2, CGFloat(d.1) * (chartH - 18))
                    let rect = CGRect(x: x, y: chartH - h, width: barW, height: h)
                    let path = Path(roundedRect: rect, cornerRadius: min(5, barW / 3))
                    ctx.fill(path, with: .linearGradient(
                        Gradient(colors: [Lab.cyan, Lab.hex(0x2A6FA8)]),
                        startPoint: CGPoint(x: rect.midX, y: rect.minY),
                        endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
                    ctx.draw(Text("\(d.2)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Lab.ivory),
                             at: CGPoint(x: rect.midX, y: rect.minY - 9), anchor: .center)
                    ctx.draw(Text("Ch \(d.0)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(Lab.dim),
                             at: CGPoint(x: rect.midX, y: chartH + 10), anchor: .center)
                }
            }
            .frame(width: chartW, height: chartH + 22)
        }
        .padding(16)
        .frame(width: w, alignment: .leading)
        .labCard()
    }

    private func chapterCard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("CHAPTER BREAKDOWN")
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.dim).tracking(1.6)
            ForEach(Chapters.all, id: \.index) { info in
                let solved = store.progress.solved(inChapter: info.index)
                let stars = store.progress.stars(inChapter: info.index)
                HStack(spacing: 8) {
                    Text("\(info.index)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(Lab.cyan)
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(info.name)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Lab.ivory)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Lab.hex(0x1E2743)).frame(height: 5)
                            Capsule().fill(Lab.cyan)
                                .frame(width: max(3, (width - 130) * CGFloat(Double(solved) / Double(info.range.count))),
                                       height: 5)
                        }
                        .frame(width: width - 130)
                    }
                    Spacer(minLength: 2)
                    HStack(spacing: 3) {
                        StarShape().fill(Lab.amber).frame(width: 9, height: 9)
                        Text("\(stars)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Lab.amber)
                    }
                    .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .frame(width: width - 24, alignment: .leading)
        .labCard()
    }

    private func fastestCard(width: CGFloat) -> some View {
        let solved = (1...LevelLibrary.count)
            .map { ($0, store.progress.record($0)) }
            .filter { $0.1.solved && $0.1.bestSeconds > 0 }
            .sorted { $0.1.bestSeconds < $1.1.bestSeconds }
            .prefix(6)
        return VStack(alignment: .leading, spacing: 8) {
            Text("FASTEST SOLVES")
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.dim).tracking(1.6)
            if solved.isEmpty {
                Text("Solve a bench to start the clock.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Lab.dim)
            } else {
                ForEach(Array(solved), id: \.0) { id, rec in
                    HStack(spacing: 8) {
                        Text("L\(id)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Lab.cyan)
                            .frame(width: 32, alignment: .leading)
                        Text(LevelLibrary.level(id: id).name)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Lab.ivory)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(rec.bestComponents)p")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Lab.dim)
                        Text(timeString(rec.bestSeconds))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Lab.amber)
                            .frame(width: 46, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: width - 24, alignment: .leading)
        .labCard()
    }

    private func hintCard(width: CGFloat) -> some View {
        let used = store.progress.totalHintsUsed
        let levelsWithHints = (1...LevelLibrary.count).filter { store.progress.record($0).hintsUsed > 0 }
        return VStack(alignment: .leading, spacing: 8) {
            Text("HINT LOG")
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.dim).tracking(1.6)
            HStack(spacing: 18) {
                bigStat("\(store.progress.hintTokensEarned)", "EARNED", Lab.cyan)
                bigStat("\(used)", "USED", Lab.amber)
                bigStat("\(store.progress.hintTokensAvailable)", "LEFT", Lab.ok)
            }
            Text(levelsWithHints.isEmpty
                 ? "No hints used yet. One token appears for every three stars you earn."
                 : "Hints used on levels: " + levelsWithHints.map { "\($0)" }.joined(separator: ", "))
                .font(.system(size: 11.5, weight: .regular, design: .rounded))
                .foregroundColor(Lab.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: width - 24, alignment: .leading)
        .labCard()
    }

    // MARK: helpers

    private func timeString(_ s: Double) -> String {
        let t = Int(s.rounded())
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    private func percent(_ f: Double) -> String {
        String(format: "%.0f%%", max(0, min(1, f)) * 100)
    }
}
