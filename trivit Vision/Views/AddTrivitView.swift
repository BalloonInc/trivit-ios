//
//  AddTrivitView.swift
//  trivit Vision
//
//  Sheet for creating a new counter
//

import SwiftUI
import SwiftData

struct AddTrivitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Trivit.sortOrder) private var trivits: [Trivit]
    @State private var title = ""
    @State private var selectedColorIndex = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Counter name", text: $title)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(0..<TrivitColors.colorCount, id: \.self) { index in
                            Circle()
                                .fill(TrivitColors.color(at: index))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if index == selectedColorIndex {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 3)
                                    }
                                }
                                .hoverEffect(.highlight)
                                .onTapGesture {
                                    selectedColorIndex = index
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Counter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        createTrivit()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            // Auto-select next color in sequence
            let lastColorIndex = trivits.last?.colorIndex ?? -1
            selectedColorIndex = (lastColorIndex + 1) % TrivitColors.colorCount
        }
    }

    private func createTrivit() {
        let maxSortOrder = trivits.map { $0.sortOrder }.max() ?? -1
        let newTrivit = Trivit(
            title: title.trimmingCharacters(in: .whitespaces),
            count: 0,
            colorIndex: selectedColorIndex,
            sortOrder: maxSortOrder + 1
        )
        modelContext.insert(newTrivit)
    }
}

#Preview {
    AddTrivitView()
        .modelContainer(for: [Trivit.self], inMemory: true)
}
