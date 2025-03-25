//
//  OnboardingView.swift
//  Hokkabaz
//
//  Created by Silvia Esposito on 25/03/25.
//

import SwiftUI

struct OnboardingModalView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 40)

                Text("Welcome to SonaStroke!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Text("Discover a simple, creative way to connect through color, music, and drawing.")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)

                VStack(spacing: 48) {
                    OnboardingItemView(
                        icon: Image(systemName: "music.note"),
                        iconColor: .purple,
                        title: "Choose color and instrument",
                        description: "Color sets the pitch. The instrument defines its sound."
                    )

                    OnboardingItemView(
                        icon: Image(systemName: "pencil.and.outline"),
                        iconColor: .purple,
                        title: "Draw on the canvas",
                        description: "Each stroke becomes a musical note."
                    )

                    OnboardingItemView(
                        icon: Image(systemName: "repeat.circle"),
                        iconColor: .purple,
                        title: "Replay your creation",
                        description: "Tap “Replay” to hear your drawing come to life."
                    )
                }
                .padding(.top, 40)

                Spacer(minLength: 20)

                Button(action: {
                    isPresented = false
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }) {
                    Text("Start")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(14)
                }
                .padding(.vertical, 30)
            }
            .frame(maxWidth: 700)
            .padding(.horizontal, 20)
        }
    }
}

struct OnboardingItemView: View {
    let icon: Image
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(iconColor)
                .padding(.bottom, 4)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingModalView(isPresented: .constant(true))
}
