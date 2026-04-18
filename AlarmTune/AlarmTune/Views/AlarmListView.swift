import SwiftUI

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @State private var showingAddAlarm = false
    @State private var editingAlarm: AlarmItem?
    @State private var showingSettings = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: toolbarIconSize))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddAlarm = true
                        HapticService.shared.light()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: toolbarIconSize))
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AlarmEditView(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditView(viewModel: viewModel, alarm: alarm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $viewModel.isRinging) {
                AlarmRingView(viewModel: viewModel)
            }
        }
    }

    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    private var toolbarIconSize: CGFloat {
        isPad ? 32 : 18
    }

    private var maxContentWidth: CGFloat {
        isPad ? 800 : AppConstants.Layout.maxContentWidth
    }

    private var emptyStateView: some View {
        EmptyStateView(onAdd: {
            showingAddAlarm = true
            HapticService.shared.light()
        })
    }

    private var alarmListContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                NextAlarmIndicator(text: viewModel.nextAlarmText)
                    .padding(.top, 8)

                ForEach(viewModel.groupedAlarms, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        if !group.category.isEmpty && group.category != "Other" {
                            HStack {
                                Image(systemName: categoryIcon(group.category))
                                    .font(.subheadline)
                                Text(group.category)
                                    .font(.headline.weight(.semibold))
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
            .frame(maxWidth: maxContentWidth)
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
