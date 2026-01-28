//
//  TrivitRowView.swift
//  Trivit
//
//  A single tally counter row
//

import SwiftUI
import SwiftData

struct TrivitRowView: View {
    @Bindable var trivit: Trivit
    @State private var isEditing = false
    @FocusState private var isTitleFocused: Bool

    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HStack(spacing: 16) {
                // Color indicator
                Circle()
                    .fill(TrivitColors.color(at: trivit.colorIndex))
                    .frame(width: 12, height: 12)

                // Title
                if isEditing {
                    TextField("Title", text: $trivit.title)
                        .font(.headline)
                        .focused($isTitleFocused)
                        .onSubmit {
                            isEditing = false
                        }
                } else {
                    Text(trivit.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .onTapGesture {
                            isEditing = true
                            isTitleFocused = true
                        }
                }

                Spacer()

                // Count display
                Text("\(trivit.count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(TrivitColors.color(at: trivit.colorIndex))
                    .frame(minWidth: 60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    trivit.increment()
                    HapticsService.shared.impact(.light)
                }
            }

            // Tally marks (when expanded)
            if !trivit.isCollapsed && trivit.count > 0 {
                TallyMarksView(count: trivit.count, color: TrivitColors.color(at: trivit.colorIndex))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Action buttons
            HStack(spacing: 20) {
                Button {
                    trivit.decrement()
                    HapticsService.shared.impact(.light)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                }
                .disabled(trivit.count == 0)

                Button {
                    withAnimation {
                        trivit.isCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: trivit.isCollapsed ? "chevron.down.circle" : "chevron.up.circle")
                        .font(.title2)
                }

                Button {
                    trivit.colorIndex = (trivit.colorIndex + 1) % TrivitColors.colorCount
                } label: {
                    Image(systemName: "paintpalette")
                        .font(.title2)
                }

                Button {
                    trivit.reset()
                    HapticsService.shared.notification(.warning)
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .font(.title2)
                }
                .disabled(trivit.count == 0)

                Spacer()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle")
                        .font(.title2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .foregroundColor(.secondary)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

// MARK: - Tally Marks Visual
struct TallyMarksView: View {
    let count: Int
    let color: Color

    var body: some View {
        let groups = count / 5
        let remainder = count % 5

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
            ForEach(0..<groups, id: \.self) { _ in
                TallyGroupView(count: 5, color: color)
            }
            if remainder > 0 {
                TallyGroupView(count: remainder, color: color)
            }
        }
    }
}

struct TallyGroupView: View {
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(count, 4), id: \.self) { _ in
                Rectangle()
                    .fill(color)
                    .frame(width: 3, height: 20)
            }
            if count == 5 {
                Rectangle()
                    .fill(color)
                    .frame(width: 20, height: 3)
                    .rotationEffect(.degrees(-60))
                    .offset(x: -10)
            }
        }
        .frame(width: 30, height: 24)
    }
}

#Preview {
    TrivitRowView(
        trivit: Trivit(title: "Test Counter", count: 7, colorIndex: 0),
        onDelete: {}
    )
    .padding()
}
