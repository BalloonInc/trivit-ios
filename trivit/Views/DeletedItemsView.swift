//
//  DeletedItemsView.swift
//  Trivit
//
//  View for managing recently deleted trivits
//

import SwiftUI
import SwiftData

struct DeletedItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Trivit> { $0.deletedAt != nil }, sort: \Trivit.deletedAt, order: .reverse)
    private var deletedTrivits: [Trivit]

    var body: some View {
        List {
            if deletedTrivits.isEmpty {
                ContentUnavailableView(
                    "No Deleted Items",
                    systemImage: "trash",
                    description: Text("Items you delete will appear here for 30 days")
                )
            } else {
                Section {
                    ForEach(deletedTrivits) { trivit in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trivit.title)
                                    .font(.body)
                                if let deletedAt = trivit.deletedAt {
                                    Text(deletedAt, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Text("\(trivit.count)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                permanentlyDelete(trivit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                restore(trivit)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.blue)
                        }
                    }
                } footer: {
                    Text("Items are permanently deleted after 30 days. Swipe right to restore, swipe left to delete permanently.")
                }

                Section {
                    Button(role: .destructive) {
                        emptyTrash()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Empty Trash")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Recently Deleted")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cleanupOldItems()
        }
    }

    private func restore(_ trivit: Trivit) {
        withAnimation {
            trivit.restore()
            HapticsService.shared.impact(.medium)
        }
    }

    private func permanentlyDelete(_ trivit: Trivit) {
        withAnimation {
            modelContext.delete(trivit)
            HapticsService.shared.notification(.warning)
        }
    }

    private func emptyTrash() {
        withAnimation {
            for trivit in deletedTrivits {
                modelContext.delete(trivit)
            }
            HapticsService.shared.notification(.warning)
        }
    }

    private func cleanupOldItems() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        for trivit in deletedTrivits {
            if let deletedAt = trivit.deletedAt, deletedAt < thirtyDaysAgo {
                modelContext.delete(trivit)
            }
        }
    }
}

#Preview {
    DeletedItemsView()
        .modelContainer(for: Trivit.self, inMemory: true)
}
