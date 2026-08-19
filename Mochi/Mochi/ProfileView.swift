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
                .background(Color.blue)
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

                Text("Dark Mode")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: $isDarkMode)
                    .labelsHidden()
            }
            .padding(.horizontal)

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
