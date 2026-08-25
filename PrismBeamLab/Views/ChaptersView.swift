//  ChaptersView.swift
//  Prism Beam Lab
//
//  Chapter cards with progress rings, pushing to a grid of level tiles.

import SwiftUI

struct ChaptersView: View {
    @EnvironmentObject var store: LabStore

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let width = min(geo.size.width, UIScreen.main.bounds.width)
                ScrollView {
                    VStack(spacing: 12) {
                        header
                        ForEach(Chapters.all, id: \.index) { info in
                            chapterCard(info, width: width)
                        }
                    }
                    .frame(width: width)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .frame(width: geo.size.width)
            }
            .background(Lab.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("CAMPAIGN")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundColor(Lab.dim).tracking(2.2)
            HStack(spacing: 6) {
                StarShape().fill(Lab.amber).frame(width: 15, height: 15)
                Text("\(store.progress.totalStars) / \(LevelLibrary.maxStars)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Lab.ivory)
            }
            Text("\(store.progress.solvedCount) of \(LevelLibrary.count) benches solved  ·  \(store.progress.hintTokensAvailable) hint tokens")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Lab.muted)
        }
        .padding(.vertical, 10)
    }

    private func chapterCard(_ info: ChapterInfo, width: CGFloat) -> some View {
        let total = info.range.count
        let solved = store.progress.solved(inChapter: info.index)
        let stars = store.progress.stars(inChapter: info.index)
        let unlocked = store.progress.isChapterUnlocked(info.index)
        let fraction = Double(solved) / Double(total)

        return NavigationLink(destination: LevelGridView(info: info)) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Lab.hex(0x243258), lineWidth: 5)
                    ArcProgressShape(fraction: fraction)
                        .stroke(unlocked ? Lab.cyan : Lab.dim,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    VStack(spacing: -1) {
                        Text("\(solved)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(Lab.ivory)
                        Text("/\(total)")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(Lab.dim)
                    }
                }
                .frame(width: 52, height: 52)
                .padding(.leading, 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text("CHAPTER \(info.index)")
                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Lab.cyan).tracking(1.6)
                    Text(info.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(unlocked ? Lab.ivory : Lab.muted)
                    Text(info.subtitle)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(Lab.dim)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 4) {
                        StarShape().fill(Lab.amber).frame(width: 10, height: 10)
                        Text("\(stars) / \(total * 3)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Lab.amber)
                    }
                }
                Spacer(minLength: 4)

                if unlocked {
                    ChevronShape()
                        .stroke(Lab.dim, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 8, height: 14)
                } else {
                    LockShape().stroke(Lab.dim, lineWidth: 1.5)
                        .frame(width: 15, height: 17)
                }
            }
            .padding(14)
            .frame(width: width - 24)
            .labCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!unlocked)
        .opacity(unlocked ? 1 : 0.55)
    }
}

// MARK: - Level grid

struct LevelGridView: View {
    let info: ChapterInfo
    @EnvironmentObject var store: LabStore

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let columns = width > 500 ? 6 : 4
            let spacing: CGFloat = 10
            let tile = (width - 28 - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 3) {
                        Text(info.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Lab.ivory)
                        Text(info.subtitle)
                            .font(.system(size: 11.5, weight: .regular, design: .rounded))
                            .foregroundColor(Lab.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 6)

                    // Rows are padded to a fixed width with 0 sentinels so no ForEach ever
                    // gets a range whose length changes between renders.
                    let ids = Array(info.range)
                    let rows: [[Int]] = stride(from: 0, to: ids.count, by: columns).map { start -> [Int] in
                        var row = Array(ids[start..<min(start + columns, ids.count)])
                        while row.count < columns { row.append(0) }
                        return row
                    }
                    VStack(spacing: spacing) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            HStack(spacing: spacing) {
                                ForEach(Array(row.enumerated()), id: \.offset) { _, id in
                                    if id > 0 {
                                        levelTile(id: id, side: tile)
                                    } else {
                                        Color.clear.frame(width: tile, height: tile)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 30)
                }
                .frame(width: width)
            }
            .frame(width: geo.size.width)
        }
        .background(Lab.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .navigationTitle("Levels")
    }

    private func levelTile(id: Int, side: CGFloat) -> some View {
        let rec = store.progress.record(id)
        let unlocked = store.progress.isUnlocked(id)
        return Button {
            guard unlocked else { return }
            store.tapFeedback()
            store.openLevel(id)
        } label: {
            VStack(spacing: 3) {
                Text("\(id)")
                    .font(.system(size: side * 0.30, weight: .heavy, design: .rounded))
                    .foregroundColor(unlocked ? (rec.solved ? Lab.cyan : Lab.ivory) : Lab.dim)
                if unlocked {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            StarShape()
                                .fill(i < rec.stars ? Lab.amber : Lab.hex(0x2A3352))
                                .frame(width: side * 0.15, height: side * 0.15)
                        }
                    }
                } else {
                    LockShape().stroke(Lab.dim, lineWidth: 1.3)
                        .frame(width: side * 0.20, height: side * 0.24)
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(rec.solved ? Lab.hex(0x16244A) : Lab.panel)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(rec.solved ? Lab.cyan.opacity(0.55) : Lab.hex(0x243258), lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(unlocked ? 1 : 0.5)
    }
}
