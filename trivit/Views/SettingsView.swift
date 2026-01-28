//
//  SettingsView.swift
//  Trivit
//
//  Settings view for app preferences
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("showTallyMarks") private var showTallyMarks = true

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle("Haptic Feedback", isOn: $enableHaptics)
                    Toggle("Show Tally Marks", isOn: $showTallyMarks)
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
}

#Preview {
    SettingsView()
}
