import SwiftUI
import MapKit

/// View for managing reminders for a specific trivit.
struct ReminderListView: View {
    // MARK: - Properties

    let trivit: Trivit
    @State private var reminderService: ReminderService
    @State private var showingAddReminder = false
    @State private var selectedReminder: TrivitReminder?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(trivit: Trivit, reminderService: ReminderService = ReminderService()) {
        self.trivit = trivit
        self._reminderService = State(initialValue: reminderService)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if !reminderService.hasNotificationPermission {
                    permissionSection
                }

                remindersSection

                if reminderService.reminders(for: trivit.id).isEmpty {
                    emptyStateSection
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!reminderService.hasNotificationPermission)
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                ReminderEditorView(
                    trivit: trivit,
                    reminderService: reminderService
                )
            }
            .sheet(item: $selectedReminder) { reminder in
                ReminderEditorView(
                    trivit: trivit,
                    reminderService: reminderService,
                    existingReminder: reminder
                )
            }
        }
    }

    // MARK: - Sections

    private var permissionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Notifications Required", systemImage: "bell.badge")
                    .font(.headline)

                Text("Enable notifications to receive reminders for your trivits.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Enable Notifications") {
                    Task {
                        await reminderService.requestNotificationPermission()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)
        }
    }

    private var remindersSection: some View {
        Section {
            ForEach(reminderService.reminders(for: trivit.id)) { reminder in
                ReminderRowView(reminder: reminder)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedReminder = reminder
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            reminderService.deleteReminder(reminder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        } header: {
            if !reminderService.reminders(for: trivit.id).isEmpty {
                Text("Active Reminders")
            }
        }
    }

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("No Reminders")
                    .font(.headline)

                Text("Tap + to add a reminder for \"\(trivit.title)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
}

// MARK: - Reminder Row View

struct ReminderRowView: View {
    let reminder: TrivitReminder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(reminder.isEnabled ? .blue : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)

                Text(triggerDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !reminder.isEnabled {
                Text("Disabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch reminder.trigger {
        case .daily:
            return "sun.max.fill"
        case .weekly:
            return "calendar"
        case .specificDate:
            return "clock.fill"
        case .interval:
            return "timer"
        case .location:
            return "location.fill"
        }
    }

    private var triggerDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        switch reminder.trigger {
        case .daily(let time):
            return "Daily at \(formatter.string(from: time))"

        case .weekly(let weekday, let time):
            let weekdayName = Calendar.current.weekdaySymbols[weekday - 1]
            return "\(weekdayName) at \(formatter.string(from: time))"

        case .specificDate(let date):
            formatter.dateStyle = .medium
            return formatter.string(from: date)

        case .interval(let seconds):
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            if hours > 0 {
                return "Every \(hours)h \(minutes)m"
            } else {
                return "Every \(minutes) minutes"
            }

        case .location(let config):
            let action = config.triggerOn == .arrive ? "Arriving at" : "Leaving"
            let name = config.locationName.isEmpty ? "location" : config.locationName
            return "\(action) \(name)"
        }
    }
}

// MARK: - Reminder Editor View

struct ReminderEditorView: View {
    // MARK: - Properties

    let trivit: Trivit
    let reminderService: ReminderService
    let existingReminder: TrivitReminder?

    @State private var title: String
    @State private var message: String
    @State private var triggerType: ReminderTriggerType = .daily
    @State private var selectedTime = Date()
    @State private var selectedWeekday = 2  // Monday
    @State private var selectedDate = Date()
    @State private var intervalMinutes: Double = 60
    @State private var locationCoordinate: CLLocationCoordinate2D?
    @State private var locationName = ""
    @State private var locationTriggerOn: LocationTriggerType = .arrive
    @State private var locationRadius: Double = 100
    @State private var isEnabled = true

    @State private var isSaving = false
    @State private var error: ReminderError?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(
        trivit: Trivit,
        reminderService: ReminderService,
        existingReminder: TrivitReminder? = nil
    ) {
        self.trivit = trivit
        self.reminderService = reminderService
        self.existingReminder = existingReminder

        if let existing = existingReminder {
            _title = State(initialValue: existing.title)
            _message = State(initialValue: existing.message)
            _isEnabled = State(initialValue: existing.isEnabled)

            switch existing.trigger {
            case .daily(let time):
                _triggerType = State(initialValue: .daily)
                _selectedTime = State(initialValue: time)
            case .weekly(let weekday, let time):
                _triggerType = State(initialValue: .weekly)
                _selectedWeekday = State(initialValue: weekday)
                _selectedTime = State(initialValue: time)
            case .specificDate(let date):
                _triggerType = State(initialValue: .specificDate)
                _selectedDate = State(initialValue: date)
            case .interval(let seconds):
                _triggerType = State(initialValue: .interval)
                _intervalMinutes = State(initialValue: seconds / 60)
            case .location(let config):
                _triggerType = State(initialValue: .location)
                _locationCoordinate = State(initialValue: config.coordinate)
                _locationName = State(initialValue: config.locationName)
                _locationTriggerOn = State(initialValue: config.triggerOn)
                _locationRadius = State(initialValue: config.radius)
            }
        } else {
            _title = State(initialValue: "Remember to count")
            _message = State(initialValue: "Don't forget to update \"\(trivit.title)\"")
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder Details") {
                    TextField("Title", text: $title)
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("When to Remind") {
                    Picker("Trigger", selection: $triggerType) {
                        ForEach(ReminderTriggerType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    triggerOptionsView
                }

                if existingReminder != nil {
                    Section {
                        Toggle("Enabled", isOn: $isEnabled)
                    }
                }
            }
            .navigationTitle(existingReminder == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(isSaving || title.isEmpty)
                }
            }
            .alert("Error", isPresented: .init(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error")
            }
        }
    }

    // MARK: - Trigger Options

    @ViewBuilder
    private var triggerOptionsView: some View {
        switch triggerType {
        case .daily:
            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)

        case .weekly:
            Picker("Day", selection: $selectedWeekday) {
                ForEach(1...7, id: \.self) { day in
                    Text(Calendar.current.weekdaySymbols[day - 1]).tag(day)
                }
            }
            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)

        case .specificDate:
            DatePicker("Date & Time", selection: $selectedDate, in: Date()...)

        case .interval:
            VStack(alignment: .leading) {
                Text("Every \(Int(intervalMinutes)) minutes")
                Slider(value: $intervalMinutes, in: 15...480, step: 15)
            }

        case .location:
            locationOptionsView
        }
    }

    @ViewBuilder
    private var locationOptionsView: some View {
        if !reminderService.hasLocationPermission {
            Button("Enable Location") {
                reminderService.requestLocationPermission()
            }
        } else {
            TextField("Location Name", text: $locationName)

            Picker("Trigger When", selection: $locationTriggerOn) {
                ForEach(LocationTriggerType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }

            VStack(alignment: .leading) {
                Text("Radius: \(Int(locationRadius))m")
                Slider(value: $locationRadius, in: 50...500, step: 50)
            }

            // Note: Full map picker would be a separate view
            Button("Select Location on Map") {
                // In a full implementation, this would open a map picker
                // For now, use current location or a preset
            }
        }
    }

    // MARK: - Save

    private func saveReminder() {
        isSaving = true

        let trigger: ReminderTrigger
        switch triggerType {
        case .daily:
            trigger = .daily(time: selectedTime)
        case .weekly:
            trigger = .weekly(weekday: selectedWeekday, time: selectedTime)
        case .specificDate:
            trigger = .specificDate(selectedDate)
        case .interval:
            trigger = .interval(intervalMinutes * 60)
        case .location:
            guard let coord = locationCoordinate else {
                error = .invalidTrigger
                isSaving = false
                return
            }
            trigger = .location(LocationTriggerConfig(
                coordinate: coord,
                radius: locationRadius,
                triggerOn: locationTriggerOn,
                locationName: locationName
            ))
        }

        let reminder = TrivitReminder(
            id: existingReminder?.id ?? UUID(),
            trivitId: trivit.id,
            title: title,
            message: message,
            trigger: trigger,
            isEnabled: isEnabled
        )

        Task {
            do {
                if existingReminder != nil {
                    try await reminderService.updateReminder(reminder)
                } else {
                    try await reminderService.createReminder(reminder)
                }
                dismiss()
            } catch let err as ReminderError {
                error = err
            } catch {
                self.error = .schedulingFailed
            }
            isSaving = false
        }
    }
}

// MARK: - Reminder Trigger Type (for UI)

enum ReminderTriggerType: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case specificDate
    case interval
    case location

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .specificDate: return "Specific Date"
        case .interval: return "Interval"
        case .location: return "Location"
        }
    }
}

// MARK: - Preview

#Preview("Reminder List") {
    ReminderListView(trivit: .preview)
}

#Preview("Reminder Editor") {
    ReminderEditorView(
        trivit: .preview,
        reminderService: ReminderService()
    )
}
