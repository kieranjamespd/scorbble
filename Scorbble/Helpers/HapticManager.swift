//
//  HapticManager.swift
//  Scorbble
//
//  Created by Kieran James on 12.12.25.
//

import UIKit

/// Simple haptic feedback manager for tactile interactions
enum HapticManager {
    
    // MARK: - Impact Feedback
    
    /// Light tap - for tile taps, toggles, selections
    static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact - for adding scores, confirming actions
    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact - for important actions like ending game
    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success - word validated, score added
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning - almost invalid, caution
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error - invalid word, action failed
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed - cycling through options
    static func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

