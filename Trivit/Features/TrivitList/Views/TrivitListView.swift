import SwiftUI
import SwiftData

/// The main list view displaying all trivits.
struct TrivitListView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorSchemeIndex) private var colorSchemeIndex

    // MARK: - State

    @State private var viewModel: TrivitListViewModel?
    @State private var showingSettings = false
    @State private var showingResetConfirmation = false
    @State private var trivitToReset: Trivit?
    @State private var isSearching = false

    // MARK: - Query

    @Query(sort: \Trivit.createdAt, order: .forward)
    private var trivits: [Trivit]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trivits")
                .toolbar { toolbarContent }
                .searchable(
                    text: Binding(
                        get: { viewModel?.searchQuery ?? "" },
                        set: { viewModel?.searchQuery = $0 }
                    ),
                    isPresented: $isSearching,
                    prompt: "Search trivits"
                )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert(
            "Reset Trivit",
            isPresented: $showingResetConfirmation,
            presenting: trivitToReset
        ) { trivit in
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task {
                    await viewModel?.resetTrivit(trivit)
                }
            }
        } message: { trivit in
            Text("Are you sure you want to reset '\(trivit.title)'?")
        }
        .task {
            await setupViewModel()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if trivits.isEmpty && !(viewModel?.isLoading ?? false) {
            emptyState
        } else {
            trivitList
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Trivits", systemImage: "tally")
        } description: {
            Text("Tap the + button to create your first counter")
        } actions: {
            Button {
                Task { await viewModel?.createTrivit() }
            } label: {
                Text("Add Trivit")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var trivitList: some View {
        List {
            ForEach(viewModel?.filteredTrivits ?? trivits) { trivit in
                TrivitRowView(
                    trivit: trivit,
                    onIncrement: {
                        Task { await viewModel?.incrementTrivit(trivit) }
                    },
                    onDecrement: {
                        Task { await viewModel?.decrementTrivit(trivit) }
                    },
                    onResetRequest: {
                        trivitToReset = trivit
                        showingResetConfirmation = true
                    },
                    onToggleCollapse: {
                        Task { await viewModel?.toggleCollapsed(trivit) }
                    },
                    onRename: { newTitle in
                        Task { await viewModel?.renameTrivit(trivit, to: newTitle) }
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel?.deleteTrivit(trivit) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        Task { await viewModel?.cycleColor(trivit) }
                    } label: {
                        Label("Color", systemImage: "paintpalette")
                    }
                    .tint(.green)
                }
            }
            .onDelete { indexSet in
                Task { await viewModel?.deleteTrivits(at: indexSet) }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel?.refresh()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .accessibilityLabel("Settings")
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await viewModel?.createTrivit() }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add Trivit")
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
        }
    }

    // MARK: - Setup

    private func setupViewModel() async {
        let repository = SwiftDataTrivitRepository(modelContext: modelContext)
        viewModel = TrivitListViewModel(repository: repository)
        await viewModel?.loadTrivits()
    }
}

// MARK: - Preview

#Preview {
    TrivitListView()
        .modelContainer(for: Trivit.self, inMemory: true)
}
