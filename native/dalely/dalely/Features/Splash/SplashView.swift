import SwiftUI

struct SplashView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0.0

    private var isDark: Bool {
        colorScheme == .dark
    }

    var body: some View {
        ZStack {
            // Background: Primary color on light mode, dark on dark mode
            (isDark ? AppColors.darkBackground : AppColors.lightPrimary)
                .ignoresSafeArea()

            // Centered App Logo
            Image("logo-outlined")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isPresented = false
            }
        }
        .onAppear {
            // Elegant entrance micro-animation
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                scale = 1.0
                opacity = 1.0
            }

            // Smooth automatic transition into the app
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isPresented = false
                }
            }
        }
    }
}
