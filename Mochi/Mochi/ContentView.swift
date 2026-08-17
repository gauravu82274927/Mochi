//
//  ContentView.swift
//  Mochi
//
//  Created by Gaurav on 17/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var health = 100
    @State private var sessionStartTime: Date? = nil
    
    private var petMood: String {
        if health >= 80 {
            return "Mochi is feeling great! 😊"
        } else if health >= 50 {
            return "Mochi is feeling okay 🙂"
        } else if health >= 20 {
            return "Mochi is getting tired 😟"
        } else {
            return "Mochi needs a break! 😭"
        }
    }
    
    private var petEmoji: String {
        if health >= 80 {
            return "🐣"
        } else if health >= 50 {
            return "🐥"
        } else if health >= 20 {
            return "🥺"
        } else {
            return "😭"
        }
    }
    
    private func changeHealth(by amount: Int) {
        health = min(100, max(0, health + amount))
    }
    
    private func startSession() {
        sessionStartTime = Date()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
    
    var body: some View {
        VStack(spacing: 25) {
            
            Text("Mochi")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your screen-time pet")
                .foregroundStyle(.secondary)
            
            Text(petEmoji)
                .font(.system(size: 150))
            
            Text("❤️ \(health) / 100")
                .font(.title2)
                .fontWeight(.semibold)
            
            ProgressView(value: Double(health) / 100.0)
                .padding(.horizontal, 40)
            
            Text(petMood)
                .font(.headline)
            
            if let startTime = sessionStartTime {
                VStack(spacing: 10) {
                    
                    Text("📱 Using Phone")
                        .font(.headline)
                    
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let elapsed = context.date.timeIntervalSince(startTime)
                        
                        Text(formatTime(elapsed))
                            .font(.title)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    
                    Button("I'm Putting My Phone Down") {
                        sessionStartTime = nil
                    }
                    .buttonStyle(.borderedProminent)
                    
                }
            } else {
                Button("Start Using Phone") {
                    startSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
