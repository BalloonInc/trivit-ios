import SwiftUI

/// Easter eggs and celebrations for special count values.
struct EasterEggs {
    // MARK: - Milestone Detection

    /// Standard milestones that trigger celebrations
    static let milestones: Set<Int> = [
        10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000
    ]

    /// Special numbers with unique meanings
    static let specialNumbers: [Int: SpecialNumber] = [
        42: SpecialNumber(
            name: "The Answer",
            description: "The Answer to Life, the Universe, and Everything!",
            emoji: "🌌",
            color: .purple
        ),
        69: SpecialNumber(
            name: "Nice",
            description: "Nice.",
            emoji: "😏",
            color: .pink
        ),
        100: SpecialNumber(
            name: "Century",
            description: "You've hit a century! Triple digits!",
            emoji: "💯",
            color: .orange
        ),
        123: SpecialNumber(
            name: "Count Up",
            description: "1, 2, 3... You're on a roll!",
            emoji: "🔢",
            color: .blue
        ),
        321: SpecialNumber(
            name: "Countdown",
            description: "3, 2, 1... Blast off!",
            emoji: "🚀",
            color: .red
        ),
        365: SpecialNumber(
            name: "Full Year",
            description: "That's a whole year's worth!",
            emoji: "📅",
            color: .green
        ),
        404: SpecialNumber(
            name: "Not Found",
            description: "Error 404: Patience not found",
            emoji: "🔍",
            color: .gray
        ),
        420: SpecialNumber(
            name: "Blaze It",
            description: "4:20 somewhere...",
            emoji: "🌿",
            color: .green
        ),
        666: SpecialNumber(
            name: "Devil's Number",
            description: "Devilishly good counting!",
            emoji: "😈",
            color: .red
        ),
        777: SpecialNumber(
            name: "Lucky Sevens",
            description: "Jackpot! Triple sevens!",
            emoji: "🎰",
            color: .yellow
        ),
        808: SpecialNumber(
            name: "808 Boom",
            description: "Drop the bass! 808 drum machine vibes.",
            emoji: "🥁",
            color: .indigo
        ),
        1000: SpecialNumber(
            name: "Grand",
            description: "A grand milestone! You've hit 1K!",
            emoji: "🎉",
            color: .orange
        ),
        1234: SpecialNumber(
            name: "Sequential",
            description: "1-2-3-4! Perfect sequence!",
            emoji: "✨",
            color: .cyan
        ),
        1337: SpecialNumber(
            name: "L33T",
            description: "You're now officially elite!",
            emoji: "🖥️",
            color: .green
        ),
        2048: SpecialNumber(
            name: "Power of Two",
            description: "2^11! You've merged to victory!",
            emoji: "🎮",
            color: .yellow
        ),
        3141: SpecialNumber(
            name: "Pi",
            description: "3.141... Mmm, pie!",
            emoji: "🥧",
            color: .brown
        ),
        8008: SpecialNumber(
            name: "Calculator Word",
            description: "Turn your calculator upside down...",
            emoji: "🔢",
            color: .pink
        ),
        9001: SpecialNumber(
            name: "Over 9000!",
            description: "IT'S OVER 9000!!!",
            emoji: "💪",
            color: .orange
        ),
        10000: SpecialNumber(
            name: "Ten Thousand",
            description: "10K! You're a counting legend!",
            emoji: "🏆",
            color: .yellow
        )
    ]

    // MARK: - Detection

    /// Checks if a count is a milestone or special number.
    static func check(_ count: Int) -> CelebrationEvent? {
        // Check special numbers first
        if let special = specialNumbers[count] {
            return .special(special)
        }

        // Check standard milestones
        if milestones.contains(count) {
            return .milestone(count)
        }

        // Check repeating digits
        if isRepeatingDigits(count) && count >= 111 {
            return .repeating(count)
        }

        // Check palindromes
        if isPalindrome(count) && count >= 101 {
            return .palindrome(count)
        }

        return nil
    }

    /// Checks if a number has all repeating digits (111, 222, etc.)
    private static func isRepeatingDigits(_ n: Int) -> Bool {
        let str = String(n)
        guard str.count >= 3 else { return false }
        return Set(str).count == 1
    }

    /// Checks if a number is a palindrome
    private static func isPalindrome(_ n: Int) -> Bool {
        let str = String(n)
        return str == String(str.reversed())
    }
}

// MARK: - Special Number

/// A special number with a unique celebration.
struct SpecialNumber: Equatable {
    let name: String
    let description: String
    let emoji: String
    let color: Color
}

// MARK: - Celebration Event

/// Types of celebration events.
enum CelebrationEvent: Equatable {
    case milestone(Int)
    case special(SpecialNumber)
    case repeating(Int)
    case palindrome(Int)

    var title: String {
        switch self {
        case .milestone(let count):
            return "Milestone: \(count)!"
        case .special(let special):
            return special.name
        case .repeating(let count):
            return "Repeating: \(count)!"
        case .palindrome(let count):
            return "Palindrome: \(count)!"
        }
    }

    var description: String {
        switch self {
        case .milestone(let count):
            return "You've reached \(count)! Keep going!"
        case .special(let special):
            return special.description
        case .repeating(let count):
            return "All the same digits! \(count) is satisfying!"
        case .palindrome(let count):
            return "\(count) reads the same forwards and backwards!"
        }
    }

    var emoji: String {
        switch self {
        case .milestone:
            return "🎯"
        case .special(let special):
            return special.emoji
        case .repeating:
            return "🔄"
        case .palindrome:
            return "🪞"
        }
    }

    var color: Color {
        switch self {
        case .milestone:
            return .blue
        case .special(let special):
            return special.color
        case .repeating:
            return .purple
        case .palindrome:
            return .teal
        }
    }
}

// MARK: - Celebration View

/// A view that displays a celebration overlay.
struct CelebrationView: View {
    let event: CelebrationEvent
    let onDismiss: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Text(event.emoji)
                .font(.system(size: 80))
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Text(event.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(event.color)

            Text(event.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Awesome!") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(event.color)
        }
        .padding(32)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 20)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Celebration Modifier

/// View modifier for showing celebrations.
struct CelebrationModifier: ViewModifier {
    @Binding var celebration: CelebrationEvent?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let celebration {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            self.celebration = nil
                        }

                    CelebrationView(event: celebration) {
                        self.celebration = nil
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: celebration != nil)
    }
}

extension View {
    /// Shows a celebration overlay when a celebration event is set.
    func celebration(_ event: Binding<CelebrationEvent?>) -> some View {
        modifier(CelebrationModifier(celebration: event))
    }
}

// MARK: - Preview

#Preview("Easter Eggs") {
    VStack(spacing: 20) {
        ForEach([42, 100, 420, 666, 777, 1337, 9001], id: \.self) { number in
            if let event = EasterEggs.check(number) {
                HStack {
                    Text(event.emoji)
                    Text("\(number): \(event.title)")
                }
            }
        }
    }
}

#Preview("Celebration View") {
    CelebrationView(
        event: .special(EasterEggs.specialNumbers[42]!)
    ) {}
}
