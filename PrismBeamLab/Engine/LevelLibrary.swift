//  LevelLibrary.swift
//  Prism Beam Lab
//
//  Builds every level once and answers "is this board solved?". Pure Swift — the headless
//  audit binary compiles this file too, so the levels it checks are literally the shipped ones.

import Foundation
import CoreGraphics

public struct BoardEvaluation {
    public let trace: TraceResult
    public let satisfied: [Bool]
    public let solved: Bool
    public let usedComponents: Int
}

public enum LevelLibrary {

    public static let levels: [LevelSpec] = LevelRecipes.all().map { LevelBuilder.build($0) }

    public static var count: Int { levels.count }

    public static func level(id: Int) -> LevelSpec {
        if id >= 1 && id <= levels.count { return levels[id - 1] }
        return levels[0]
    }

    public static func levels(inChapter chapter: Int) -> [LevelSpec] {
        levels.filter { $0.chapter == chapter }
    }

    /// Trace a board made of the level's locked parts plus whatever the player has placed.
    public static func evaluate(_ level: LevelSpec, placed: [PlacedComponent]) -> BoardEvaluation {
        var components = level.fixed
        components.append(contentsOf: placed)
        let trace = OpticsEngine.trace(benchSide: level.benchSide,
                                       emitters: level.emitters,
                                       components: components,
                                       receptors: level.receptors,
                                       collectSegments: true)
        var flags: [Bool] = []
        flags.reserveCapacity(level.receptors.count)
        for (i, spec) in level.receptors.enumerated() {
            flags.append(trace.isSatisfied(i, spec))
        }
        let solved = !flags.isEmpty && !flags.contains(false)
        return BoardEvaluation(trace: trace, satisfied: flags, solved: solved,
                               usedComponents: placed.count)
    }

    /// Same trace but without collecting the render segments — used by the audit's hot loop.
    public static func isSolved(_ level: LevelSpec, placed: [PlacedComponent]) -> Bool {
        var components = level.fixed
        components.append(contentsOf: placed)
        let trace = OpticsEngine.trace(benchSide: level.benchSide,
                                       emitters: level.emitters,
                                       components: components,
                                       receptors: level.receptors,
                                       collectSegments: false)
        for (i, spec) in level.receptors.enumerated() where !trace.isSatisfied(i, spec) {
            return false
        }
        return !level.receptors.isEmpty
    }

    /// Total stars available across the campaign.
    public static var maxStars: Int { levels.count * 3 }
}
