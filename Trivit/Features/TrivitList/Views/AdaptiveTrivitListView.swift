import SwiftUI
import SwiftData

/// Adaptive container that provides the best layout for each platform.
/// - iPhone: Single column NavigationStack
/// - iPad: Two-column NavigationSplitView with sidebar
/// - macOS: Three-column NavigationSplitView with inspector
struct AdaptiveTrivitListView: View {
    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorSchemeIndex) private var colorSchemeIndex

    // MARK: - State

    @State private var viewModel: TrivitListViewModel?
    @State private var selectedTrivit: Trivit?
    @State private var showingSettings = false
    @State private var showingResetConfirmation = false
    @State private var trivitToReset: Trivit?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchQuery = ""

    // MARK: - Query

    @Query(sort: \Trivit.createdAt, order: .forward)
    private var trivits: [Trivit]

    // MARK: - Body

    var body: some View {
        Group {
            #if os(macOS)
            macOSLayout
            #else
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
            #endif
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

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        NavigationStack {
            listContent
                .navigationTitle("Trivits")
                .toolbar { compactToolbar }
                .searchable(text: $searchQuery, prompt: "Search trivits")
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .navigationTitle("Trivits")
                .toolbar { sidebarToolbar }
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $searchQuery, prompt: "Search trivits")
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .navigationTitle("Trivits")
                .toolbar { macOSToolbar }
        } content: {
            if let trivit = selectedTrivit {
                TrivitDetailView(trivit: trivit)
            } else {
                ContentUnavailableView(
                    "Select a Trivit",
                    systemImage: "tally",
                    description: Text("Choose a trivit from the sidebar")
                )
            }
        } detail: {
            if let trivit = selectedTrivit {
                HistoryView(trivit: trivit)
            } else {
                ContentUnavailableView(
                    "No Statistics",
                    systemImage: "chart.bar",
                    description: Text("Select a trivit to view its history")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $searchQuery, prompt: "Search trivits")
    }
    #endif

    // MARK: - Sidebar Content

    private var sidebarContent: some View {
        List(selection: $selectedTrivit) {
            ForEach(filteredTrivits) { trivit in
                SidebarTrivitRow(trivit: trivit)
                    .tag(trivit)
                    .contextMenu {
                        trivitContextMenu(for: trivit)
                    }
            }
            .onDelete { indexSet in
                Task { await viewModel?.deleteTrivits(at: indexSet) }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if trivits.isEmpty {
                sidebarEmptyState
            }
        }
    }

    // MARK: - List Content (iPhone)

    private var listContent: some View {
        List {
            ForEach(filteredTrivits) { trivit in
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
        .overlay {
            if trivits.isEmpty {
                emptyState
            }
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        if let trivit = selectedTrivit {
            TrivitDetailView(trivit: trivit)
                .id(trivit.id)
        } else {
            ContentUnavailableView(
                "Select a Trivit",
                systemImage: "tally",
                description: Text("Choose a trivit from the sidebar to view details")
            )
        }
    }

    // MARK: - Empty States

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

    private var sidebarEmptyState: some View {
        ContentUnavailableView {
            Label("No Trivits", systemImage: "tally")
        } description: {
            Text("Create your first counter")
        } actions: {
            Button {
                Task { await viewModel?.createTrivit() }
            } label: {
                Label("Add Trivit", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var compactToolbar: some ToolbarContent {
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

    @ToolbarContentBuilder
    private var sidebarToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await viewModel?.createTrivit() }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add Trivit")
        }

        ToolbarItem(placement: .secondaryAction) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .accessibilityLabel("Settings")
        }
    }

    #if os(macOS)
    @ToolbarContentBuilder
    private var macOSToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await viewModel?.createTrivit() }
            } label: {
                Image(systemName: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            .accessibilityLabel("Add Trivit")
        }

        ToolbarItem(placement: .secondaryAction) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .keyboardShortcut(",", modifiers: .command)
            .accessibilityLabel("Settings")
        }
    }
    #endif

    // MARK: - Context Menu

    @ViewBuilder
    private func trivitContextMenu(for trivit: Trivit) -> some View {
        Button {
            Task { await viewModel?.incrementTrivit(trivit) }
        } label: {
            Label("Increment", systemImage: "plus")
        }

        Button {
            Task { await viewModel?.decrementTrivit(trivit) }
        } label: {
            Label("Decrement", systemImage: "minus")
        }

        Divider()

        Button {
            Task { await viewModel?.cycleColor(trivit) }
        } label: {
            Label("Change Color", systemImage: "paintpalette")
        }

        Button {
            trivitToReset = trivit
            showingResetConfirmation = true
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
        }

        Divider()

        Button(role: .destructive) {
            Task { await viewModel?.deleteTrivit(trivit) }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Helpers

    private var filteredTrivits: [Trivit] {
        if searchQuery.isEmpty {
            return trivits
        }
        return trivits.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
    }

    private func setupViewModel() async {
        let repository = SwiftDataTrivitRepository(modelContext: modelContext)
        viewModel = TrivitListViewModel(repository: repository)
        await viewModel?.loadTrivits()
    }
}

// MARK: - Preview

#Preview("iPhone") {
    AdaptiveTrivitListView()
        .modelContainer(for: Trivit.self, inMemory: true)
}

#Preview("iPad") {
    AdaptiveTrivitListView()
        .modelContainer(for: Trivit.self, inMemory: true)
        .previewDevice("iPad Pro (12.9-inch)")
}
