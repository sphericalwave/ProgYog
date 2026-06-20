//
//  TEDDescription.swift
//  ProgYog
//
//  Plain-language descriptions for the TACFIT "TED Compass" 1–10 ratings —
//  Technique, Exertion, Discomfort. Wording from the Cradle System Ring
//  Start-Up Guide (p.21).
//

import Foundation

enum TEDDescription {
    /// Holding the power-chamber form, 10 = best possible form.
    static func technique(_ value: Int) -> String {
        switch value {
        case ...2:  return "very sloppy form"
        case 3...4: return "poor form"
        case 5...6: return "adequate form"
        case 7...8: return "good form"
        default:    return "extremely good form"
        }
    }

    /// Stress expressed/resisted, 10 = hardest you've ever worked.
    static func exertion(_ value: Int) -> String {
        switch value {
        case ...2:  return "very easy"
        case 3...4: return "somewhat easy"
        case 5...6: return "hard"
        case 7...8: return "very difficult"
        default:    return "extremely difficult"
        }
    }

    /// Pain level, 10 = worst pain you've ever experienced.
    static func discomfort(_ value: Int) -> String {
        switch value {
        case ...2:  return "no discomfort"
        case 3...4: return "mild discomfort"
        case 5...6: return "uncomfortable"
        case 7...8: return "very uncomfortable"
        default:    return "extremely painful"
        }
    }
}
