//  LabStore.swift
//  Prism Beam Lab
//
//  The single observable object shared by every screen: progress, settings, feedback and the
//  currently selected level.

import SwiftUI
import UIKit
import AudioToolbox

final class LabStore: ObservableObject {

    @Published var progress: PrismProgress {
        didSet { scheduleSave() }
    }

    /// Which tab the custom tab bar is showing.
    @Published var tab: Int = 0
    /// Which campaign level the Bench tab is playing.
    @Published var currentLevelID: Int = 1
    /// Bumped whenever the Bench tab should throw away its session and reload the level.
    @Published var benchEpoch: Int = 0

    private var saveWorkItem: DispatchWorkItem?

    init() {
        let loaded = PrismStore.load()
        progress = loaded
        currentLevelID = min(max(1, loaded.lastLevelPlayed), LevelLibrary.count)
    }

    // MARK: saving

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let snapshot = progress
        let work = DispatchWorkItem { PrismStore.save(snapshot) }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    /// Immediate, unconditional write — used on level completion and when the app backgrounds.
    func saveNow() {
        saveWorkItem?.cancel()
        saveWorkItem = nil
        PrismStore.save(progress)
    }

    // MARK: level flow

    func openLevel(_ id: Int) {
        let clamped = min(max(1, id), LevelLibrary.count)
        currentLevelID = clamped
        progress.lastLevelPlayed = clamped
        benchEpoch += 1
        tab = 0
    }

    func recordSolve(levelID: Int, stars: Int, components: Int, rotations: Int, seconds: Double) {
        var r = progress.record(levelID)
        let firstTime = !r.solved
        r.solved = true
        r.stars = max(r.stars, stars)
        // `firstTime` rather than a zero sentinel: a genuine 0-rotation solve is a real record.
        r.bestComponents = firstTime ? components : min(r.bestComponents, components)
        r.bestRotations = firstTime ? rotations : min(r.bestRotations, rotations)
        r.bestSeconds = firstTime ? seconds : min(r.bestSeconds, seconds)
        progress.setRecord(levelID, r)
        if firstTime { progress.totalSolves += 1 }
        saveNow()
    }

    func spendHint(levelID: Int) -> Bool {
        guard progress.hintTokensAvailable > 0 else { return false }
        progress.hintTokensSpent += 1
        var r = progress.record(levelID)
        r.hintsUsed += 1
        progress.setRecord(levelID, r)
        saveNow()
        return true
    }

    func markCodexRead(_ id: Int) {
        if !progress.codexRead.contains(id) {
            progress.codexRead.append(id)
        }
    }

    func resetEverything() {
        var fresh = PrismProgress()
        fresh.soundOn = progress.soundOn
        fresh.hapticsOn = progress.hapticsOn
        fresh.colourBlind = progress.colourBlind
        fresh.fineSnapDefault = progress.fineSnapDefault
        fresh.showBeamLabels = progress.showBeamLabels
        progress = fresh
        currentLevelID = 1
        benchEpoch += 1
        saveNow()
    }

    // MARK: feedback

    func tapFeedback() {
        if progress.hapticsOn {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }
        if progress.soundOn { AudioServicesPlaySystemSound(1104) }
    }

    func placeFeedback() {
        if progress.hapticsOn {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
        }
        if progress.soundOn { AudioServicesPlaySystemSound(1105) }
    }

    func successFeedback() {
        if progress.hapticsOn {
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
        }
        if progress.soundOn { AudioServicesPlaySystemSound(1057) }
    }
}
