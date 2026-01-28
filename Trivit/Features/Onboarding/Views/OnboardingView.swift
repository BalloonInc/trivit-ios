import SwiftUI

/// Onboarding tutorial view.
struct OnboardingView: View {
    // MARK: - Properties

    @Binding var isComplete: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Trivit",
            description: "The simplest way to count anything",
            imageName: "hand.tap",
            color: .blue
        ),
        OnboardingPage(
            title: "Tap to Count",
            description: "Tap anywhere in the tally zone to add one to your count",
            imageName: "plus.circle.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Collapse & Expand",
            description: "Tap the title bar to collapse a trivit and see just the count",
            imageName: "rectangle.compress.vertical",
            color: .orange
        ),
        OnboardingPage(
            title: "Decrease Count",
            description: "Tap the minus button to decrease your count by one",
            imageName: "minus.circle.fill",
            color: .pink
        ),
        OnboardingPage(
            title: "Reset Counter",
            description: "Long press the minus button to reset your count to zero",
            imageName: "arrow.counterclockwise.circle.fill",
            color: .red
        ),
        OnboardingPage(
            title: "You're Ready!",
            description: "Start counting everything that matters to you",
            imageName: "checkmark.circle.fill",
            color: .purple
        )
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .padding()
            }

            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        isComplete = true
        HapticsService.shared.notification(.success)
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isComplete: .constant(false))
}
