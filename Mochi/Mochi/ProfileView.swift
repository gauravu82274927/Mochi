//
//  ProfileView.swift
//  Mochi
//
//  Created by Gaurav on 19/08/26.
//

import SwiftUI

struct ProfileView: View {

    let userName: String
    @Binding var isDarkMode: Bool
    @AppStorage("secondaryTheme") private var secondaryTheme = "blue"
    
    private var secondaryColor: Color {
        switch secondaryTheme {
        case "purple":
            return .purple
        case "green":
            return .green
        case "orange":
            return .orange
        case "pink":
            return .pink
        case "red":
            return .red
        default:
            return .blue
        }
    }
    
    private var themeName: String {
        secondaryTheme.capitalized
    }

    var body: some View {
        VStack(spacing: 25) {

            // Profile header
            VStack(spacing: 10) {
                Text(
                    userName
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .prefix(1)
                        .uppercased()
                )
                .font(.system(size: 55, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 90, height: 90)
                .background(secondaryColor)
                .clipShape(Circle())

                Text(userName)
                    .font(.title)
                    .fontWeight(.bold)

                Text("Mochi user")
                    .foregroundStyle(.secondary)
            }
            

            Divider()

            // Theme
            HStack {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .frame(width: 30)

                Text("Primary Theme")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: $isDarkMode)
                    .labelsHidden()
            }
            Menu {
                Button {
                    secondaryTheme = "blue"
                } label: {
                    Label("Blue", systemImage: secondaryTheme == "blue" ? "checkmark" : "")
                }

                Button {
                    secondaryTheme = "purple"
                } label: {
                    Label("Purple", systemImage: secondaryTheme == "purple" ? "checkmark" : "")
                }

                Button {
                    secondaryTheme = "green"
                } label: {
                    Label("Green", systemImage: secondaryTheme == "green" ? "checkmark" : "")
                }

                Button {
                    secondaryTheme = "orange"
                } label: {
                    Label("Orange", systemImage: secondaryTheme == "orange" ? "checkmark" : "")
                }

                Button {
                    secondaryTheme = "pink"
                } label: {
                    Label("Pink", systemImage: secondaryTheme == "pink" ? "checkmark" : "")
                }

                Button {
                    secondaryTheme = "red"
                } label: {
                    Label("Red", systemImage: secondaryTheme == "red" ? "checkmark" : "")
                }
            } label: {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(.primary)

                    Text("Secondary Theme")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(themeName)
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView(
        userName: "Gaurav",
        isDarkMode: .constant(true)
    )
}
