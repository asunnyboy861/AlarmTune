import SwiftUI
import UserNotifications

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmViewModel()
    @State private var showingAddAlarm = false
    @State private var editingAlarm: AlarmItem?
    @State private var showingSettings = false
    @State private var alarmToDelete: AlarmItem?
    @State private var showDeleteConfirmation = false
    @State private var hasRequestedNotificationPermission = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

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
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        requestNotificationPermissionIfNeeded {
                            showingAddAlarm = true
                            HapticService.shared.light()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: toolbarIconSize))
                    }
                    .accessibilityIdentifier("addAlarmToolbarButton")
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
            .alert("Delete Alarm?", isPresented: $showDeleteConfirmation, presenting: alarmToDelete) { alarm in
                Button("Delete", role: .destructive) {
                    viewModel.deleteAlarm(alarm)
                }
                Button("Cancel", role: .cancel) {}
            } message: { alarm in
                Text("\"\(alarm.wrappedLabel)\" will be permanently deleted.")
            }
            // P1 fix: 通知权限被拒时提示用户
            .alert("Notifications Disabled", isPresented: $showNotificationDenied) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("AlarmTune needs notification permission to play alarms. Please enable notifications in Settings.")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refresh()
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
            requestNotificationPermissionIfNeeded {
                showingAddAlarm = true
                HapticService.shared.light()
            }
        })
    }

    private var alarmListContent: some View {
        ScrollView {
            VStack(spacing: listSpacing) {
                NextAlarmIndicator(text: viewModel.nextAlarmText)
                    .padding(.top, 8)

                ForEach(viewModel.groupedAlarms, id: \.category) { group in
                    VStack(alignment: .leading, spacing: groupSpacing) {
                        if !group.category.isEmpty && group.category != "Other" {
                            HStack(spacing: 8) {
                                Image(systemName: categoryIcon(group.category))
                                    .font(.system(size: categoryIconSize))
                                Text(group.category)
                                    .font(.system(size: categoryFontSize, weight: .semibold))
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    alarmToDelete = alarm
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingAlarm = alarm
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.accentColor)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    alarmToDelete = alarm
                                    showDeleteConfirmation = true
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

    private var listSpacing: CGFloat {
        isPad ? 24 : 16
    }

    private var groupSpacing: CGFloat {
        isPad ? 16 : 12
    }

    private var categoryIconSize: CGFloat {
        isPad ? 18 : 14
    }

    private var categoryFontSize: CGFloat {
        isPad ? 20 : 16
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

    /// 首次点击添加闹钟时请求通知权限，已请求过则直接执行
    /// P1 fix: 检查权限状态，被拒时提示用户
    private func requestNotificationPermissionIfNeeded(then action: @escaping () -> Void) {
        if hasRequestedNotificationPermission {
            // 已请求过，检查当前权限状态
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .denied {
                        showNotificationDeniedAlert()
                    } else {
                        action()
                    }
                }
            }
            return
        }

        hasRequestedNotificationPermission = true
        AlarmScheduler.shared.requestAuthorization { granted in
            DispatchQueue.main.async {
                if granted {
                    action()
                } else {
                    showNotificationDeniedAlert()
                }
            }
        }
    }

    /// P1 fix: 通知权限被拒时提示用户
    @State private var showNotificationDenied: Bool = false

    private func showNotificationDeniedAlert() {
        showNotificationDenied = true
    }
}
