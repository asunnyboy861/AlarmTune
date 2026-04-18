import SwiftUI

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @State private var showingAddAlarm = false
    @State private var editingAlarm: AlarmItem?
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if viewModel.alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmListContent
                }
            }
            .navigationTitle("AlarmTune")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAlarm = true
                        HapticService.shared.light()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AlarmEditView(viewModel: viewModel)
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditView(viewModel: viewModel, alarm: alarm)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $viewModel.isRinging) {
                AlarmRingView(viewModel: viewModel)
            }
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(onAdd: {
            showingAddAlarm = true
            HapticService.shared.light()
        })
    }

    private var alarmListContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                NextAlarmIndicator(text: viewModel.nextAlarmText)
                    .padding(.top, 8)

                ForEach(viewModel.groupedAlarms, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        if !group.category.isEmpty && group.category != "Other" {
                            HStack {
                                Image(systemName: categoryIcon(group.category))
                                    .font(.caption)
                                Text(group.category)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundColor(categoryColor(group.category))
                            .padding(.horizontal, 4)
                        }

                        ForEach(group.alarms) { alarm in
                            AlarmRowView(alarm: alarm) {
                                viewModel.toggleAlarm(alarm)
                            }
                            .onTapGesture {
                                editingAlarm = alarm
                                HapticService.shared.light()
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteAlarm(alarm)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingAlarm = alarm
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func categoryIcon(_ category: String) -> String {
        AlarmItem.AlarmCategory(rawValue: category)?.icon ?? "alarm.fill"
    }

    private func categoryColor(_ category: String) -> Color {
        switch AlarmItem.AlarmCategory(rawValue: category)?.color {
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "indigo": return .indigo
        case "green": return .green
        default: return .accentColor
        }
    }
}


