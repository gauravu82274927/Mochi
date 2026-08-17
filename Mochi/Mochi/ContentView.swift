//
//  ContentView.swift
//  Mochi
//
//  Created by Gaurav on 17/08/26.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack(spacing: 25) {
            
            Text("Mochi")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your screen-time pet")
                .foregroundStyle(.secondary)
            
            Text("🐣")
                .font(.system(size: 150))
            
            Text("❤️ 100 / 100")
                .font(.title2)
                .fontWeight(.semibold)
            
            ProgressView(value: 1.0)
                .padding(.horizontal, 40)
            
            Text("Mochi is feeling great! 😊")
                .font(.headline)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
