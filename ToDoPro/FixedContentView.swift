//
//  FixedContentView.swift
//  ToDoPro
//
//  Created by Youran Tao Jensen on 01/10/2025.
//

import SwiftUI

struct FixedContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            FixedHomeView(taskManager: taskManager, showingAddTask: $showingAddTask)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)

            // Tasks Tab
            FixedTasksView(taskManager: taskManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("任务")
                }
                .tag(1)

            // Analytics Tab
            FixedAnalyticsView(taskManager: taskManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("分析")
                }
                .tag(2)
        }
        .sheet(isPresented: $showingAddTask) {
            FixedAddTaskView(taskManager: taskManager)
        }
    }
}

struct FixedHomeView: View {
    @ObservedObject var taskManager: TaskManager
    @Binding var showingAddTask: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("ToDoPro")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("高效任务管理")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Quick Stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        FixedStatCard(
                            title: "今日任务",
                            value: "\(taskManager.getTasksForToday().count)",
                            color: .blue,
                            icon: "calendar"
                        )

                        FixedStatCard(
                            title: "剩余工作",
                            value: taskManager.todaysRemainingWorkload.shortFormattedTime,
                            color: .orange,
                            icon: "clock"
                        )

                        FixedStatCard(
                            title: "已完成",
                            value: "\(taskManager.dailyStats.totalTasksCompleted)",
                            color: .green,
                            icon: "checkmark.circle"
                        )

                        FixedStatCard(
                            title: "生产力",
                            value: "\(Int(taskManager.dailyStats.productivityScore))",
                            color: .purple,
                            icon: "chart.line.uptrend.xyaxis"
                        )
                    }

                    // Active Task
                    if let activeTask = taskManager.currentActiveTask {
                        FixedActiveTaskCard(task: activeTask, taskManager: taskManager)
                    }

                    // Recent Tasks
                    FixedRecentTasksList(taskManager: taskManager)

                    // Add Task Button
                    Button(action: {
                        showingAddTask = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("添加新任务")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("")
        }
    }
}

struct FixedStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FixedActiveTaskCard: View {
    let task: TodoTask
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("正在进行")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "timer")
                    .foregroundColor(.orange)
            }

            VStack(spacing: 8) {
                Text(task.title)
                    .font(.title3)
                    .fontWeight(.medium)

                Text(task.remainingTime.formattedTime)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                ProgressView(value: task.progress)
                    .tint(.orange)

                HStack(spacing: 16) {
                    Button(action: {
                        if task.status == .inProgress {
                            taskManager.pauseTask(task.id)
                        } else {
                            taskManager.resumeTask(task.id)
                        }
                    }) {
                        HStack {
                            Image(systemName: task.status == .inProgress ? "pause.fill" : "play.fill")
                            Text(task.status == .inProgress ? "暂停" : "继续")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(20)
                    }

                    Button(action: {
                        taskManager.completeTask(task.id)
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("完成")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .background(.orange.opacity(0.05))
        .cornerRadius(16)
    }
}

struct FixedRecentTasksList: View {
    @ObservedObject var taskManager: TaskManager

    var recentTasks: [TodoTask] {
        Array(taskManager.tasks
            .filter { !$0.isArchived }
            .sorted { $0.createdDate > $1.createdDate }
            .prefix(3))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("最近任务")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            if recentTasks.isEmpty {
                Text("还没有任务")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(recentTasks) { task in
                        FixedTaskRow(task: task, taskManager: taskManager)
                    }
                }
            }
        }
    }
}

struct FixedTaskRow: View {
    let task: TodoTask
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(task.status.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(task.estimatedDuration.shortFormattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if task.repeatType != .none {
                        Text("• \(task.repeatType.displayName)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    if let dueDate = task.dueDate {
                        Text("• \(dueDate.formatted(.dateTime.month().day()))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Text(task.status.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(task.status.color.opacity(0.2))
                .foregroundColor(task.status.color)
                .cornerRadius(8)

            if task.status == .pending {
                Button(action: {
                    taskManager.startTask(task.id)
                }) {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct FixedTasksView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTask = false

    var body: some View {
        NavigationView {
            List {
                ForEach(taskManager.tasks.filter { !$0.isArchived }) { task in
                    FixedTaskDetailRow(task: task, taskManager: taskManager)
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle("所有任务")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                FixedAddTaskView(taskManager: taskManager)
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        let tasksToDelete = offsets.map { taskManager.tasks[$0] }
        for task in tasksToDelete {
            taskManager.deleteTask(task)
        }
    }
}

struct FixedTaskDetailRow: View {
    let task: TodoTask
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Text(task.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.status.color.opacity(0.2))
                    .foregroundColor(task.status.color)
                    .cornerRadius(8)
            }


            HStack {
                Label(task.estimatedDuration.shortFormattedTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let dueDate = task.dueDate {
                    Label(dueDate.formatted(.dateTime.month().day().hour().minute()), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if task.repeatType != .none {
                    Label(task.repeatType.displayName, systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                if task.status == .pending {
                    Button("开始") {
                        taskManager.startTask(task.id)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                } else if task.status == .inProgress {
                    Button("暂停") {
                        taskManager.pauseTask(task.id)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                } else if task.status == .paused {
                    Button("继续") {
                        taskManager.resumeTask(task.id)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FixedAnalyticsView: View {
    @ObservedObject var taskManager: TaskManager

    var safeProductivityScore: Double {
        let score = taskManager.dailyStats.productivityScore
        return score.isFinite ? max(0, min(100, score)) : 0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Productivity Score
                    VStack(spacing: 16) {
                        Text("今日生产力评分")
                            .font(.headline)
                            .fontWeight(.semibold)

                        ZStack {
                            Circle()
                                .stroke(lineWidth: 15)
                                .opacity(0.1)
                                .foregroundColor(.blue)

                            Circle()
                                .trim(from: 0.0, to: CGFloat(safeProductivityScore / 100))
                                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .foregroundColor(.blue)
                                .rotationEffect(Angle(degrees: 270.0))
                                .animation(.easeInOut(duration: 1.0), value: safeProductivityScore)

                            VStack {
                                Text("\(Int(safeProductivityScore))")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.blue)

                                Text("分")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 150, height: 150)
                    }

                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        FixedAnalyticsCard(
                            title: "完成任务",
                            value: "\(taskManager.dailyStats.totalTasksCompleted)",
                            color: .green
                        )

                        FixedAnalyticsCard(
                            title: "工作效率",
                            value: "\(Int(taskManager.dailyStats.efficiency * 100))%",
                            color: .blue
                        )

                        FixedAnalyticsCard(
                            title: "完成率",
                            value: "\(Int(taskManager.dailyStats.completionRate * 100))%",
                            color: .orange
                        )

                        FixedAnalyticsCard(
                            title: "逾期任务",
                            value: "\(taskManager.dailyStats.overdueTasks)",
                            color: .red
                        )
                    }

                    // Time Breakdown
                    VStack(spacing: 16) {
                        Text("时间分析")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(spacing: 12) {
                            FixedTimeBreakdownRow(
                                label: "已完成工作",
                                time: taskManager.todaysCompletedWork,
                                color: .green
                            )

                            FixedTimeBreakdownRow(
                                label: "剩余工作",
                                time: taskManager.todaysRemainingWorkload,
                                color: .blue
                            )

                            FixedTimeBreakdownRow(
                                label: "空闲时间",
                                time: taskManager.todaysFreeTime,
                                color: .orange
                            )
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("分析")
        }
    }
}

struct FixedAnalyticsCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FixedTimeBreakdownRow: View {
    let label: String
    let time: TimeInterval
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Text(time.shortFormattedTime)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FixedAddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager

    @State private var title = ""
    @State private var hasEstimatedTime = true
    @State private var estimatedTime = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority = 0
    @State private var repeatType: RepeatType = .none
    @State private var repeatInterval = 1.0

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("任务标题")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("请输入任务标题", text: $title)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }


                // Time Settings
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("设置预计用时", isOn: $hasEstimatedTime)

                    if hasEstimatedTime {
                        VStack(spacing: 12) {
                            DatePicker("预计用时", selection: $estimatedTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel)

                            Text("总计: \(formattedEstimatedTime)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Due Date
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("设置截止时间", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("截止时间", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                // Repeat
                VStack(alignment: .leading, spacing: 8) {
                    Text("重复设置")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Picker("重复类型", selection: $repeatType) {
                        ForEach(RepeatType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    if repeatType == .custom {
                        HStack {
                            Text("每")
                            Stepper("\(Int(repeatInterval))", value: $repeatInterval, in: 1...365, step: 1)
                                .labelsHidden()
                            Text("天重复")
                        }
                    }
                }

                // Priority
                VStack(alignment: .leading, spacing: 8) {
                    Text("优先级")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Picker("优先级", selection: $priority) {
                        Text("低").tag(0)
                        Text("中").tag(1)
                        Text("高").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()

                // Buttons
                HStack(spacing: 16) {
                    Button("取消") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.3))
                    .foregroundColor(.black)
                    .cornerRadius(8)

                    Button("创建") {
                        saveTask()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(title.isEmpty ? .gray : .blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(title.isEmpty)
                }
            }
            .padding()
            .navigationTitle("新建任务")
        }
    }

    private var formattedEstimatedTime: String {
        if hasEstimatedTime {
            let hours = Calendar.current.component(.hour, from: estimatedTime)
            let minutes = Calendar.current.component(.minute, from: estimatedTime)
            let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
            return totalSeconds.shortFormattedTime
        }
        return "未设置"
    }

    private func saveTask() {
        let estimatedDuration: TimeInterval
        if hasEstimatedTime {
            let hours = Calendar.current.component(.hour, from: estimatedTime)
            let minutes = Calendar.current.component(.minute, from: estimatedTime)
            estimatedDuration = TimeInterval(hours * 3600 + minutes * 60)
        } else {
            estimatedDuration = 3600 // 默认1小时
        }

        let task = TodoTask(
            title: title,
            description: "",
            estimatedDuration: estimatedDuration,
            dueDate: hasDueDate ? dueDate : nil,
            repeatType: repeatType,
            repeatInterval: Int(repeatInterval),
            priority: priority
        )
        taskManager.addTask(task)
        dismiss()
    }
}

#Preview {
    FixedContentView()
}