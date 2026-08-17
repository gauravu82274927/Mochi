//
//  ContentView.swift
//  Mochi
//
//  Created by Gaurav on 17/08/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @AppStorage("mochiHealth") private var health = 100
    @State private var sessionStartTime: Date? = nil
    @State private var recoveryStartTime: Date? = nil
    @State private var currentDate = Date()
    
    private var currentHealth: Int {
        if let startTime = sessionStartTime {
            let elapsed = currentDate.timeIntervalSince(startTime)
            return healthForElapsedTime(elapsed)
        }
        
        if let startTime = recoveryStartTime {
            let elapsed = currentDate.timeIntervalSince(startTime)
            return healthForRecovery(elapsed)
        }
        
        return health
    }
    
    private var petMood: String {
        if currentHealth >= 80 {
            return "Mochi is feeling great! 😊"
        } else if currentHealth >= 50 {
            return "Mochi is feeling okay 🙂"
        } else if currentHealth >= 20 {
            return "Mochi is getting tired 😟"
        } else {
            return "Mochi needs a break! 😭"
        }
    }
    
    private var petEmoji: String {
        if currentHealth >= 80 {
            return "🐣"
        } else if currentHealth >= 50 {
            return "🐥"
        } else if currentHealth >= 20 {
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
    
    private func healthForElapsedTime(_ seconds: TimeInterval) -> Int {
        
        if seconds < 10 {
            return 100
        } else if seconds < 20 {
            return 90
        } else if seconds < 30 {
            return 80
        } else if seconds < 40 {
            return 65
        } else if seconds < 60 {
            return 50
        } else if seconds < 90 {
            return 25
        } else {
            return 0
        }
    }
    
    private func healthForRecovery(_ seconds: TimeInterval) -> Int {
        let recoveryPoints = Int(seconds / 10) * 5
        
        return min(100, health + recoveryPoints)
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
            
            Text("❤️ \(currentHealth) / 100")
                .font(.title2)
                .fontWeight(.semibold)
            
            ProgressView(value: Double(currentHealth) / 100.0)
                .padding(.horizontal, 40)
            
            Text(petMood)
                .font(.headline)
            
            if let startTime = sessionStartTime {
                
                VStack(spacing: 10) {
                    
                    Text("📱 Using Phone")
                        .font(.headline)
                    
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let elapsed = context.date.timeIntervalSince(startTime)
                        let sessionHealth = healthForElapsedTime(elapsed)
                        
                        VStack(spacing: 10) {
                            
                            Text(formatTime(elapsed))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                            
                            Text("❤️ \(sessionHealth) / 100")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Button("I'm Putting My Phone Down") {
                        health = currentHealth
                        sessionStartTime = nil
                        recoveryStartTime = Date()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
            } else if let startTime = recoveryStartTime {
                
                VStack(spacing: 10) {
                    
                    Text("🌱 Recovery Mode")
                        .font(.headline)
                    
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let elapsed = context.date.timeIntervalSince(startTime)
                        let recoveredHealth = healthForRecovery(elapsed)

                        VStack(spacing: 10) {
                            
                            Text(formatTime(elapsed))
                                .font(.title)
                                .fontWeight(.bold)
                                .monospacedDigit()
                            
                            Text("❤️ \(recoveredHealth) / 100")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if recoveredHealth >= 100 {
                                Text("Mochi is fully recovered! 🥹✨")
                                    .font(.headline)
                            } else {
                                Text("Mochi is recovering! 🥹")
                                    .font(.headline)
                            }
                        }
                    }
                    
                    Button("I'm Back") {
                        health = currentHealth
                        recoveryStartTime = nil
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
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { date in
            currentDate = date
            
            if let startTime = recoveryStartTime {
                let elapsed = date.timeIntervalSince(startTime)
                
                if healthForRecovery(elapsed) >= 100 {
                    health = 100
                    recoveryStartTime = nil
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
