//  PrismProgress.swift
//  Prism Beam Lab
//
//  One Codable blob under a single UserDefaults key. EVERY field decodes through
//  `decodeIfPresent ?? default`, so adding a field in a future build can never throw and
//  wipe a player's campaign.

import Foundation
import CoreGraphics

// MARK: - Per level record

struct LevelRecord: Codable, Hashable {
    var solved: Bool
    var stars: Int
    var bestComponents: Int
    var bestRotations: Int
    var bestSeconds: Double
    var hintsUsed: Int

    init(solved: Bool = false, stars: Int = 0, bestComponents: Int = 0,
         bestRotations: Int = 0, bestSeconds: Double = 0, hintsUsed: Int = 0) {
        self.solved = solved
        self.stars = stars
        self.bestComponents = bestComponents
        self.bestRotations = bestRotations
        self.bestSeconds = bestSeconds
        self.hintsUsed = hintsUsed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        solved = (try? c.decodeIfPresent(Bool.self, forKey: .solved) ?? false) ?? false
        stars = (try? c.decodeIfPresent(Int.self, forKey: .stars) ?? 0) ?? 0
        bestComponents = (try? c.decodeIfPresent(Int.self, forKey: .bestComponents) ?? 0) ?? 0
        bestRotations = (try? c.decodeIfPresent(Int.self, forKey: .bestRotations) ?? 0) ?? 0
        bestSeconds = (try? c.decodeIfPresent(Double.self, forKey: .bestSeconds) ?? 0) ?? 0
        hintsUsed = (try? c.decodeIfPresent(Int.self, forKey: .hintsUsed) ?? 0) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case solved, stars, bestComponents, bestRotations, bestSeconds, hintsUsed
    }
}

// MARK: - Sandbox slot

struct SandboxSlot: Codable, Hashable {
    var name: String
    var components: [PlacedComponent]
    var emitterX: Double
    var emitterY: Double
    var emitterAngle: Double
    var emitterBandRaw: Int          // -1 == white
    var savedAt: Double

    init(name: String = "", components: [PlacedComponent] = [],
         emitterX: Double = 20, emitterY: Double = 200, emitterAngle: Double = 0,
         emitterBandRaw: Int = -1, savedAt: Double = 0) {
        self.name = name
        self.components = components
        self.emitterX = emitterX
        self.emitterY = emitterY
        self.emitterAngle = emitterAngle
        self.emitterBandRaw = emitterBandRaw
        self.savedAt = savedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decodeIfPresent(String.self, forKey: .name) ?? "") ?? ""
        components = (try? c.decodeIfPresent([PlacedComponent].self, forKey: .components) ?? []) ?? []
        emitterX = (try? c.decodeIfPresent(Double.self, forKey: .emitterX) ?? 20) ?? 20
        emitterY = (try? c.decodeIfPresent(Double.self, forKey: .emitterY) ?? 200) ?? 200
        emitterAngle = (try? c.decodeIfPresent(Double.self, forKey: .emitterAngle) ?? 0) ?? 0
        emitterBandRaw = (try? c.decodeIfPresent(Int.self, forKey: .emitterBandRaw) ?? -1) ?? -1
        savedAt = (try? c.decodeIfPresent(Double.self, forKey: .savedAt) ?? 0) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case name, components, emitterX, emitterY, emitterAngle, emitterBandRaw, savedAt
    }

    var emitter: EmitterSpec {
        EmitterSpec(x: emitterX, y: emitterY, angle: emitterAngle,
                    band: Band(rawValue: emitterBandRaw), polarisation: 0)
    }
}

// MARK: - The whole save file

struct PrismProgress: Codable {
    var records: [String: LevelRecord]
    var hintTokensSpent: Int
    var codexRead: [Int]
    var sandboxSlots: [SandboxSlot]
    var soundOn: Bool
    var hapticsOn: Bool
    var fineSnapDefault: Bool
    var colourBlind: Bool
    var showBeamLabels: Bool
    var lastLevelPlayed: Int
    var totalSolves: Int

    static let slotCount = 6

    init() {
        records = [:]
        hintTokensSpent = 0
        codexRead = []
        sandboxSlots = Array(repeating: SandboxSlot(), count: PrismProgress.slotCount)
        soundOn = true
        hapticsOn = true
        fineSnapDefault = false
        colourBlind = false
        showBeamLabels = false
        lastLevelPlayed = 1
        totalSolves = 0
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        records = (try? c.decodeIfPresent([String: LevelRecord].self, forKey: .records) ?? [:]) ?? [:]
        hintTokensSpent = (try? c.decodeIfPresent(Int.self, forKey: .hintTokensSpent) ?? 0) ?? 0
        codexRead = (try? c.decodeIfPresent([Int].self, forKey: .codexRead) ?? []) ?? []
        var slots = (try? c.decodeIfPresent([SandboxSlot].self, forKey: .sandboxSlots) ?? []) ?? []
        while slots.count < PrismProgress.slotCount { slots.append(SandboxSlot()) }
        if slots.count > PrismProgress.slotCount { slots = Array(slots.prefix(PrismProgress.slotCount)) }
        sandboxSlots = slots
        soundOn = (try? c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? true) ?? true
        hapticsOn = (try? c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? true) ?? true
        fineSnapDefault = (try? c.decodeIfPresent(Bool.self, forKey: .fineSnapDefault) ?? false) ?? false
        colourBlind = (try? c.decodeIfPresent(Bool.self, forKey: .colourBlind) ?? false) ?? false
        showBeamLabels = (try? c.decodeIfPresent(Bool.self, forKey: .showBeamLabels) ?? false) ?? false
        lastLevelPlayed = (try? c.decodeIfPresent(Int.self, forKey: .lastLevelPlayed) ?? 1) ?? 1
        totalSolves = (try? c.decodeIfPresent(Int.self, forKey: .totalSolves) ?? 0) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case records, hintTokensSpent, codexRead, sandboxSlots, soundOn, hapticsOn
        case fineSnapDefault, colourBlind, showBeamLabels, lastLevelPlayed, totalSolves
    }

    // MARK: derived

    func record(_ id: Int) -> LevelRecord {
        records["\(id)"] ?? LevelRecord()
    }

    mutating func setRecord(_ id: Int, _ r: LevelRecord) {
        records["\(id)"] = r
    }

    var totalStars: Int {
        records.values.reduce(0) { $0 + $1.stars }
    }

    var solvedCount: Int {
        records.values.reduce(0) { $0 + ($1.solved ? 1 : 0) }
    }

    var totalHintsUsed: Int {
        records.values.reduce(0) { $0 + $1.hintsUsed }
    }

    func stars(inChapter chapter: Int) -> Int {
        let range = Chapters.all.first { $0.index == chapter }?.range ?? 1...1
        return range.reduce(0) { $0 + record($1).stars }
    }

    func solved(inChapter chapter: Int) -> Int {
        let range = Chapters.all.first { $0.index == chapter }?.range ?? 1...1
        return range.reduce(0) { $0 + (record($1).solved ? 1 : 0) }
    }

    /// 1 hint token for every 3 stars earned.
    var hintTokensEarned: Int { totalStars / 3 }
    var hintTokensAvailable: Int { max(0, hintTokensEarned - hintTokensSpent) }

    /// A level is playable when the one before it is solved (level 1 is always open).
    func isUnlocked(_ id: Int) -> Bool {
        if id <= 1 { return true }
        if record(id).solved { return true }
        return record(id - 1).solved
    }

    func isChapterUnlocked(_ chapter: Int) -> Bool {
        guard let info = Chapters.all.first(where: { $0.index == chapter }) else { return false }
        return isUnlocked(info.range.lowerBound)
    }

    /// Sandbox opens once Chapter 2 is finished, or at 25 stars for players who skipped stars.
    var sandboxUnlocked: Bool {
        if totalStars >= 25 { return true }
        return (1...29).allSatisfy { record($0).solved }
    }

    var nextUnsolvedLevel: Int {
        for i in 1...LevelLibrary.count where !record(i).solved { return i }
        return LevelLibrary.count
    }
}

// MARK: - Store

enum PrismStore {
    static let key = "pbl.state.v1"

    static func load() -> PrismProgress {
        guard let data = UserDefaults.standard.data(forKey: key) else { return PrismProgress() }
        if let decoded = try? JSONDecoder().decode(PrismProgress.self, from: data) { return decoded }
        return PrismProgress()
    }

    static func save(_ p: PrismProgress) {
        if let data = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func wipe() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
