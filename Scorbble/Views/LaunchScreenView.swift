//
//  LaunchScreenView.swift
//  Scorbble
//
//  Created by Kieran James on 08.12.25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showHome = false
    
    // Letter animations - staggered appearance
    @State private var letterOpacities: [Double] = [0, 0, 0, 0, 0, 0, 0, 0]
    @State private var letterScales: [Double] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    
    let letters = ["S", "C", "O", "R", "B", "B", "L", "E"]
    let points = [1, 3, 1, 1, 3, 3, 1, 1] // Scrabble point values
    
    var body: some View {
        ZStack {
            // Background - same as home screen
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if showHome {
                // Transition to home
                HomeView()
                    .transition(.opacity)
            } else {
                // Launch screen content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo tiles
                    HStack(spacing: 6) {
                        ForEach(0..<8, id: \.self) { index in
                            LaunchTileView(
                                letter: letters[index],
                                points: points[index]
                            )
                            .opacity(letterOpacities[index])
                            .scaleEffect(letterScales[index])
                        }
                    }
                    
                    // Tagline
                    Text("Score Keeper & Word Checker")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(isAnimating ? 0.6 : 0))
                        .animation(.easeIn(duration: 0.5).delay(1.0), value: isAnimating)
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    func startAnimations() {
        // Animate each letter with staggered timing
        for index in 0..<8 {
            let delay = Double(index) * 0.08
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                letterOpacities[index] = 1.0
                letterScales[index] = 1.0
            }
        }
        
        isAnimating = true
        
        // Transition to home after animations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showHome = true
            }
        }
    }
}

// MARK: - Launch Tile View

struct LaunchTileView: View {
    let letter: String
    let points: Int
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "f5deb3"), Color(hex: "deb887")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 2)
            
            Text(letter)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "2d2d2d"))
                .frame(width: 36, height: 36)
            
            Text("\(points)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(hex: "5d4e37"))
                .padding(.trailing, 3)
                .padding(.bottom, 2)
        }
    }
}

#Preview {
    LaunchScreenView()
}

