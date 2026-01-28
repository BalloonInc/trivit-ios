//
//  EasterEggs.swift
//  Trivit
//
//  Fun easter egg messages for special counts
//

import Foundation

struct EasterEggs {
    static func message(for count: Int) -> String? {
        switch count {
        case 42:
            return "The answer to life, the universe, and everything!"
        case 69:
            return "Nice."
        case 100:
            return "Century! 🎉"
        case 404:
            return "Count not found"
        case 420:
            return "Blaze it!"
        case 666:
            return "The number of the beast 😈"
        case 777:
            return "Jackpot! 🎰"
        case 1000:
            return "Grand millennium!"
        case 1337:
            return "L33T!"
        case 9000:
            return "It's over 9000!"
        case 9001:
            return "What, 9001?!"
        default:
            return nil
        }
    }
}
