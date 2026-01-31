//
//  WatchSettingsView.swift
//  Trivit Watch App
//
//  Settings view for watch app
//

import SwiftUI
import SwiftData

struct WatchSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var trivits: [Trivit]
    @StateObject private var syncService = SyncService.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Sync Status") {
                    HStack {
                        Circle()
                            .fill(syncService.isReachable ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(syncService.isReachable ? "Connected" : "Not Connected")
                            .font(.system(size: 14))
                    }

                    Button {
                        syncService.requestSync()
                    } label: {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                Section("Data") {
                    HStack {
                        Text("Counters")
                        Spacer()
                        Text("\(trivits.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total Tallies")
                        Spacer()
                        Text("\(trivits.reduce(0) { $0 + $1.count })")
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
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
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
    WatchSettingsView()
        .modelContainer(for: [Trivit.self], inMemory: true)
}
