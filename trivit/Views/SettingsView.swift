//
//  SettingsView.swift
//  Trivit
//
//  Settings view for app preferences
//

import SwiftUI
import SwiftData

enum ColorScheme: String, CaseIterable, Identifiable {
    case vibrant = "Vibrant"
    case pastel = "Pastel"
    case monochrome = "Monochrome"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case forest = "Forest"
    case candy = "Candy"
    case earth = "Earth"

    var id: String { rawValue }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var trivits: [Trivit]
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("hideCounterWhenExpanded") private var hideCounterWhenExpanded = true
    @AppStorage("colorScheme") private var selectedColorScheme = ColorScheme.vibrant.rawValue
    @ObservedObject private var watchSync = WatchSyncService.shared

    @Query(filter: #Predicate<Trivit> { $0.deletedAt != nil })
    private var deletedTrivits: [Trivit]

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle("Haptic Feedback", isOn: $enableHaptics)
                        .onChange(of: enableHaptics) { _, newValue in
                            AnalyticsService.shared.trackSettingChanged(setting: "haptic_feedback", value: String(newValue))
                        }
                    Toggle("Hide Counter When Expanded", isOn: $hideCounterWhenExpanded)
                        .onChange(of: hideCounterWhenExpanded) { _, newValue in
                            AnalyticsService.shared.trackSettingChanged(setting: "hide_counter_expanded", value: String(newValue))
                        }
                }

                Section("Color Scheme") {
                    Picker("Palette", selection: $selectedColorScheme) {
                        ForEach(ColorScheme.allCases) { scheme in
                            HStack {
                                colorPreview(for: scheme)
                                Text(scheme.rawValue)
                            }
                            .tag(scheme.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: selectedColorScheme) { _, newValue in
                        AnalyticsService.shared.trackColorSchemeChanged(scheme: newValue)
                    }
                }

                Section("Watch Sync") {
                    HStack {
                        Text("Watch Paired")
                        Spacer()
                        Image(systemName: watchSync.isWatchPaired ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(watchSync.isWatchPaired ? .green : .secondary)
                    }

                    HStack {
                        Text("Watch Reachable")
                        Spacer()
                        Image(systemName: watchSync.isWatchReachable ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(watchSync.isWatchReachable ? .green : .secondary)
                    }

                    Button {
                        watchSync.syncAllTrivitsToWatch()
                        HapticsService.shared.impact(.medium)
                    } label: {
                        HStack {
                            Text("Sync to Watch")
                            Spacer()
                            if watchSync.isWatchReachable {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.blue)
                            } else {
                                Text("Not reachable")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(!watchSync.isWatchReachable)
                }

                Section("Info") {
                    HStack {
                        Text("Trivits")
                        Spacer()
                        Text("\(trivits.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Device")
                        Spacer()
                        Text(deviceName)
                            .foregroundColor(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://apps.apple.com/app/trivit")!) {
                        HStack {
                            Text("Rate on App Store")
                            Spacer()
                            Image(systemName: "star")
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "mailto:support@trivit.app")!) {
                        HStack {
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Open Source") {
                    Link(destination: URL(string: "https://github.com/BalloonInc/trivit-ios")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/BalloonInc/trivit-ios/issues/new?labels=translation&title=Translation+issue")!) {
                        HStack {
                            Text("Report Translation Issue")
                            Spacer()
                            Image(systemName: "globe")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Deleted Items") {
                    NavigationLink {
                        DeletedItemsView()
                    } label: {
                        HStack {
                            Text("Recently Deleted")
                            Spacer()
                            Text("\(deletedTrivits.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        // Reset all data
                    } label: {
                        Text("Reset All Trivits")
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Button {
                        print("📱 DEBUG: Manual sync to watch triggered")
                        watchSync.syncAllTrivitsToWatch()
                        HapticsService.shared.notification(.success)
                    } label: {
                        HStack {
                            Text("Force Sync to Watch")
                            Spacer()
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.orange)
                        }
                    }

                    HStack {
                        Text("Session Activated")
                        Spacer()
                        Text(watchSync.isWatchPaired ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Watch Reachable")
                        Spacer()
                        Text(watchSync.isWatchReachable ? "Yes" : "No")
                            .foregroundColor(watchSync.isWatchReachable ? .green : .red)
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var deviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Unknown"
        #endif
    }

    @ViewBuilder
    private func colorPreview(for scheme: ColorScheme) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(previewColor(for: scheme, at: index))
                    .frame(width: 16, height: 16)
            }
        }
    }

    private func previewColor(for scheme: ColorScheme, at index: Int) -> Color {
        switch scheme {
        case .vibrant:
            return TrivitColors.color(at: index)
        case .pastel:
            return TrivitColors.color(at: index).opacity(0.6)
        case .monochrome:
            let gray = 0.3 + (Double(index) * 0.15)
            return Color(white: gray)
        case .ocean:
            return oceanPalette[index % oceanPalette.count]
        case .sunset:
            return sunsetPalette[index % sunsetPalette.count]
        case .forest:
            return forestPalette[index % forestPalette.count]
        case .candy:
            return candyPalette[index % candyPalette.count]
        case .earth:
            return earthPalette[index % earthPalette.count]
        }
    }

    // MARK: - Color Palettes

    private var oceanPalette: [Color] {
        [
            Color(hex: "0077B6"), // Deep Blue
            Color(hex: "00B4D8"), // Vivid Cyan
            Color(hex: "48CAE4"), // Light Cyan
            Color(hex: "023E8A"), // Navy Blue
            Color(hex: "0096C7"), // Ocean Blue
        ]
    }

    private var sunsetPalette: [Color] {
        [
            Color(hex: "FF6B35"), // Bright Orange
            Color(hex: "F7931E"), // Golden Orange
            Color(hex: "E84855"), // Coral Red
            Color(hex: "FF006E"), // Hot Pink
            Color(hex: "FFBA08"), // Amber
        ]
    }

    private var forestPalette: [Color] {
        [
            Color(hex: "2D6A4F"), // Forest Green
            Color(hex: "40916C"), // Medium Green
            Color(hex: "74C69D"), // Light Green
            Color(hex: "8B4513"), // Saddle Brown
            Color(hex: "556B2F"), // Dark Olive Green
        ]
    }

    private var candyPalette: [Color] {
        [
            Color(hex: "FF69B4"), // Hot Pink
            Color(hex: "DA70D6"), // Orchid
            Color(hex: "9B59B6"), // Amethyst
            Color(hex: "FF1493"), // Deep Pink
            Color(hex: "BA55D3"), // Medium Orchid
        ]
    }

    private var earthPalette: [Color] {
        [
            Color(hex: "BC6C25"), // Terracotta
            Color(hex: "606C38"), // Olive Green
            Color(hex: "8B7355"), // Burlywood Brown
            Color(hex: "A0522D"), // Sienna
            Color(hex: "DDA15E"), // Tan
        ]
    }
}

#Preview {
    SettingsView()
}
