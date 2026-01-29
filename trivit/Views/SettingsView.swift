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

    var id: String { rawValue }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var trivits: [Trivit]
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("colorScheme") private var selectedColorScheme = ColorScheme.vibrant.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle("Haptic Feedback", isOn: $enableHaptics)
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
                }

                Section("Sync Info") {
                    HStack {
                        Text("Trivits Synced")
                        Spacer()
                        Text("\(trivits.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text("--")
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

                Section("Data") {
                    Button(role: .destructive) {
                        // Reset all data
                    } label: {
                        Text("Reset All Trivits")
                    }
                }
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
        }
    }
}

#Preview {
    SettingsView()
}
