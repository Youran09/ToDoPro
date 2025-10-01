//
//  CleanContentView.swift
//  ToDoPro
//
//  Created by Youran Tao Jensen on 01/10/2025.
//

import SwiftUI

struct CleanContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CleanHomeView(taskManager: taskManager, showingAddTask: $showingAddTask)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)

            CleanTasksView(taskManager: taskManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("任务")
                }
                .tag(1)

            CleanStatsView(taskManager: taskManager)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("统计")
                }
                .tag(2)
        }
        .sheet(isPresented: $showingAddTask) {
            CleanAddTaskView(taskManager: taskManager)
        }
    }
}

struct CleanHomeView: View {
    @ObservedObject var taskManager: TaskManager
    @Binding var showingAddTask: Bool

    // 安全的数值计算，避免NaN
    private var safeProductivityScore: Int {
        let score = taskManager.dailyStats.productivityScore
        return Int(score.isFinite ? max(0, min(100, score)) : 0)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好"
        case 12..<17: return "下午好"
        case 17..<22: return "晚上好"
        default: return "深夜好"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 现代背景
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // 现代化标题区域
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(greeting)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.primary, .primary.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    Text("今天是 \(Date().formatted(.dateTime.month().day().weekday(.wide)))")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()

                                // 简洁的日期圆圈
                                VStack(spacing: 2) {
                                    Text("\(Calendar.current.component(.day, from: Date()))")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(Date().formatted(.dateTime.month(.abbreviated)))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                        }
                        .padding(.top, 8)

                        // 🎯 主要区域：今天需要完成的事情
                        CleanTodayTasks(taskManager: taskManager)

                        // 现代化添加按钮
                        Button(action: {
                            showingAddTask = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("添加新任务")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                            )
                        }
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingAddTask)

                        // 📊 现代化统计显示
                        CleanMiniStats(taskManager: taskManager, safeProductivityScore: safeProductivityScore)

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("")
        }
    }
}

struct CleanMiniStats: View {
    @ObservedObject var taskManager: TaskManager
    let safeProductivityScore: Int

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("今日概览")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
            }

            // 现代化卡片式统计
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                CleanStatCard(
                    title: "待完成",
                    value: "\(taskManager.getTasksForToday().count - taskManager.dailyStats.totalTasksCompleted)",
                    color: .blue,
                    icon: "clock.fill"
                )

                CleanStatCard(
                    title: "剩余时间",
                    value: taskManager.todaysRemainingWorkload.shortFormattedTime,
                    color: .orange,
                    icon: "timer"
                )

                if taskManager.todaysFreeTime > 0 {
                    CleanStatCard(
                        title: "空闲时间",
                        value: taskManager.todaysFreeTime.shortFormattedTime,
                        color: .green,
                        icon: "leaf.fill"
                    )
                }

                CleanStatCard(
                    title: "生产力",
                    value: "\(safeProductivityScore)%",
                    color: .purple,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }
}

struct MiniStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

struct CleanStatCard: View {
    let title: String
    let subtitle: String?
    let value: String
    let color: Color
    let icon: String?
    let trend: String?

    init(title: String, subtitle: String? = nil, value: String, color: Color, icon: String? = nil, trend: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.color = color
        self.icon = icon
        self.trend = trend
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with icon and trend
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 28, height: 28)
                        .background(color.opacity(0.2))
                        .clipShape(Circle())
                }

                Spacer()

                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

struct CleanTodayTasks: View {
    @ObservedObject var taskManager: TaskManager

    var todayTasks: [TodoTask] {
        taskManager.getTasksForToday().filter { $0.status != .completed }
    }

    var completedTasks: [TodoTask] {
        taskManager.getTasksForToday().filter { $0.status == .completed }
    }

    var body: some View {
        VStack(spacing: 20) {
            // 现代化标题区域
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今天需要完成的事情")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    if !todayTasks.isEmpty || !completedTasks.isEmpty {
                        Text("还有 \(todayTasks.count) 个任务待完成")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()

                // 现代化进度指示器
                if !todayTasks.isEmpty || !completedTasks.isEmpty {
                    VStack(spacing: 4) {
                        Text("\(completedTasks.count)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("已完成")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
            }

            // Tasks List
            if todayTasks.isEmpty && completedTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.green)

                    VStack(spacing: 4) {
                        Text("今天没有安排任务")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)

                        Text("享受你的空闲时光！")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 8) {
                    // Pending tasks
                    ForEach(todayTasks) { task in
                        CleanTaskRow(task: task, taskManager: taskManager)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let task = todayTasks[index]
                            taskManager.deleteTask(task)
                        }
                    }

                    // Completed tasks (collapsed)
                    if !completedTasks.isEmpty {
                        DisclosureGroup("已完成 (\(completedTasks.count))") {
                            LazyVStack(spacing: 8) {
                                ForEach(completedTasks) { task in
                                    CleanTaskRow(task: task, taskManager: taskManager)
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        let task = completedTasks[index]
                                        taskManager.deleteTask(task)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ModernTaskBadge: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

struct CleanTaskRow: View {
    let task: TodoTask
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        VStack(spacing: 16) {
            // 现代化任务信息区域
            HStack(spacing: 16) {
                // 现代化优先级指示器
                Circle()
                    .fill(priorityColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: priorityColor.opacity(0.4), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .strikethrough(task.status == .completed)

                    HStack(spacing: 12) {
                        // 显示剩余时间或预计时间
                        if task.status == .inProgress {
                            ModernTaskBadge(
                                text: "剩余 \(task.remainingTime.countdownFormattedTime)",
                                icon: "timer",
                                color: task.remainingTime < 300 ? .red : .blue // 少于5分钟显示红色
                            )
                        } else {
                            ModernTaskBadge(
                                text: task.estimatedDuration.shortFormattedTime,
                                icon: "clock.fill",
                                color: .blue
                            )
                        }

                        if task.repeatType != .none {
                            ModernTaskBadge(
                                text: task.repeatType.displayName,
                                icon: "repeat",
                                color: .purple
                            )
                        }

                        if let dueDate = task.dueDate {
                            ModernTaskBadge(
                                text: dueDate.formatted(.dateTime.hour().minute()),
                                icon: "alarm.fill",
                                color: .orange
                            )
                        }
                    }
                }

                Spacer()

                // 现代化状态指示器 + 进度
                VStack(spacing: 6) {
                    if task.status == .inProgress {
                        // 圆形进度指示器
                        ZStack {
                            Circle()
                                .stroke(task.status.color.opacity(0.2), lineWidth: 3)
                                .frame(width: 32, height: 32)

                            Circle()
                                .trim(from: 0, to: task.progress)
                                .stroke(task.status.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.5), value: task.progress)

                            Text("\(Int(task.progress * 100))%")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(task.status.color)
                        }
                    } else {
                        Circle()
                            .fill(task.status.color)
                            .frame(width: 8, height: 8)
                    }

                    Text(task.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(task.status.color)
                }
            }

            // 进行中任务的倒计时显示区域
            if task.status == .inProgress {
                VStack(spacing: 8) {
                    HStack {
                        if task.remainingTime <= 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("任务超时")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        } else {
                            Text("任务进行中")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        if task.remainingTime <= 0 {
                            HStack(spacing: 4) {
                                Text("← 滑动操作")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                                Image(systemName: "hand.draw")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                            }
                        } else {
                            Text("剩余时间")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }

                    // 大号倒计时显示
                    HStack {
                        Image(systemName: task.remainingTime <= 0 ? "exclamationmark.triangle.fill" : "timer")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(
                                task.remainingTime <= 0 ? .red :
                                task.remainingTime < 300 ? .orange : .blue
                            )

                        if task.remainingTime <= 0 {
                            Text("时间用完！")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        } else {
                            Text(task.remainingTime.countdownFormattedTime)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(task.remainingTime < 300 ? .orange : .blue)
                                .monospacedDigit()
                        }

                        Spacer()

                        // 进度条或超时指示
                        if task.remainingTime <= 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .foregroundColor(.red)
                                Text("超时")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.red.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        } else {
                            ProgressView(value: task.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: task.status.color))
                                .frame(width: 100)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            task.remainingTime <= 0 ? .red.opacity(0.08) :
                            task.remainingTime < 300 ? .orange.opacity(0.08) :
                            task.status.color.opacity(0.05)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    task.remainingTime <= 0 ? .red.opacity(0.3) :
                                    task.remainingTime < 300 ? .orange.opacity(0.3) :
                                    task.status.color.opacity(0.2),
                                    lineWidth: task.remainingTime <= 0 ? 2 : 1
                                )
                        )
                )
            }

            // 操作按钮区域 (更大更明显)
            HStack(spacing: 12) {
                if task.status == .pending {
                    ActionButton(
                        title: "开始任务",
                        icon: "play.fill",
                        color: .blue,
                        isProminent: true
                    ) {
                        taskManager.startTask(task.id)
                    }
                } else if task.status == .inProgress {
                    // 检查是否超时
                    if task.remainingTime <= 0 {
                        // 超时任务的特殊操作 - 使用VStack排列让按钮更明显
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                ActionButton(
                                    title: "重新开始",
                                    icon: "arrow.clockwise",
                                    color: .blue,
                                    isProminent: true
                                ) {
                                    taskManager.resetTask(task.id)
                                    taskManager.startTask(task.id)
                                }

                                ActionButton(
                                    title: "直接完成",
                                    icon: "checkmark",
                                    color: .green,
                                    isProminent: false
                                ) {
                                    taskManager.completeTask(task.id)
                                }
                            }

                            ActionButton(
                                title: "删除任务",
                                icon: "trash",
                                color: .red,
                                isProminent: false
                            ) {
                                print("删除任务: \(task.title)")
                                taskManager.deleteTask(task)
                            }
                        }
                    } else {
                        // 正常进行中的任务
                        ActionButton(
                            title: "暂停",
                            icon: "pause.fill",
                            color: .orange,
                            isProminent: false
                        ) {
                            taskManager.pauseTask(task.id)
                        }

                        ActionButton(
                            title: "完成",
                            icon: "checkmark",
                            color: .green,
                            isProminent: true
                        ) {
                            taskManager.completeTask(task.id)
                        }
                    }
                } else if task.status == .paused {
                    ActionButton(
                        title: "继续",
                        icon: "play.fill",
                        color: .blue,
                        isProminent: true
                    ) {
                        taskManager.resumeTask(task.id)
                    }

                    ActionButton(
                        title: "完成",
                        icon: "checkmark",
                        color: .green,
                        isProminent: false
                    ) {
                        taskManager.completeTask(task.id)
                    }
                } else if task.status == .completed {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已完成")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            task.isOverdue ? .red.opacity(0.4) :
                            task.status == .completed ? .green.opacity(0.3) :
                            .primary.opacity(0.1),
                            lineWidth: task.isOverdue || task.status == .completed ? 1.5 : 0.5
                        )
                )
        )
    }

    private var priorityColor: Color {
        switch task.priority {
        case 0: return .green
        case 1: return .orange
        case 2: return .red
        default: return .gray
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isProminent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isProminent ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isProminent ? color : color.opacity(0.12))
                    .shadow(
                        color: isProminent ? color.opacity(0.4) : .clear,
                        radius: isProminent ? 6 : 0,
                        x: 0,
                        y: isProminent ? 3 : 0
                    )
            )
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isProminent)
    }
}

struct CleanTasksView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTask = false

    var body: some View {
        NavigationView {
            List {
                ForEach(taskManager.tasks.filter { !$0.isArchived }) { task in
                    CleanTaskDetailRow(task: task, taskManager: taskManager)
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
                CleanAddTaskView(taskManager: taskManager)
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            let task = taskManager.tasks[index]
            taskManager.deleteTask(task)
        }
    }
}

struct CleanTaskDetailRow: View {
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
                Text("⏰ \(task.estimatedDuration.shortFormattedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if task.repeatType != .none {
                    Text("• 🔄 \(task.repeatType.displayName)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                if task.status == .pending {
                    Button("开始") {
                        taskManager.startTask(task.id)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CleanStatsView: View {
    @ObservedObject var taskManager: TaskManager

    // 安全的数值计算，避免NaN
    private var safeEfficiency: Int {
        let eff = taskManager.dailyStats.efficiency
        return Int((eff.isFinite ? max(0, min(1, eff)) : 0) * 100)
    }

    private var safeCompletionRate: Int {
        let rate = taskManager.dailyStats.completionRate
        return Int((rate.isFinite ? max(0, min(1, rate)) : 0) * 100)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("详细统计")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("深入了解你的工作表现")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Detailed Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        CleanStatCard(
                            title: "工作效率",
                            subtitle: "时间利用率",
                            value: "\(safeEfficiency)%",
                            color: .blue,
                            icon: "speedometer"
                        )

                        CleanStatCard(
                            title: "完成率",
                            subtitle: "任务完成率",
                            value: "\(safeCompletionRate)%",
                            color: .green,
                            icon: "target"
                        )

                        CleanStatCard(
                            title: "逾期任务",
                            subtitle: "需要关注",
                            value: "\(taskManager.dailyStats.overdueTasks)",
                            color: .red,
                            icon: "exclamationmark.triangle.fill"
                        )

                        CleanStatCard(
                            title: "创建任务",
                            subtitle: "今日新增",
                            value: "\(taskManager.dailyStats.tasksCreated)",
                            color: .purple,
                            icon: "plus.circle.fill"
                        )
                    }

                    // Detailed Time Breakdown
                    VStack(spacing: 16) {
                        HStack {
                            Text("详细时间分析")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        VStack(spacing: 12) {
                            CleanTimeRow(
                                label: "已完成工作",
                                time: taskManager.todaysCompletedWork,
                                color: .green
                            )

                            CleanTimeRow(
                                label: "剩余工作",
                                time: taskManager.todaysRemainingWorkload,
                                color: .blue
                            )

                            CleanTimeRow(
                                label: "空闲时间",
                                time: taskManager.todaysFreeTime,
                                color: .orange
                            )

                            CleanTimeRow(
                                label: "松弛时间",
                                time: taskManager.todaysSlackTime,
                                color: .purple
                            )

                            CleanTimeRow(
                                label: "总预计时间",
                                time: taskManager.todaysTotalEstimatedWork,
                                color: .gray
                            )

                            CleanTimeRow(
                                label: "实际花费时间",
                                time: taskManager.dailyStats.totalTimeSpent,
                                color: .indigo
                            )
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("详细分析")
        }
    }
}

struct CleanTimeRow: View {
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

struct CleanAddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager

    @State private var title = ""
    @State private var estimatedHours = 1
    @State private var estimatedMinutes = 0
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var priority = 0
    @State private var repeatType: RepeatType = .none

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title Input - 最简单的TextField
                VStack(alignment: .leading, spacing: 8) {
                    Text("任务标题")
                        .font(.headline)

                    TextField("请输入任务标题", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                // Time Settings - 简单的Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("预计用时")
                        .font(.headline)

                    HStack {
                        Picker("小时", selection: $estimatedHours) {
                            ForEach(0..<9) { hour in
                                Text("\(hour)小时").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("分钟", selection: $estimatedMinutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text("\(minute)分钟").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                }

                // Due Date
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("设置截止时间", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("截止时间", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                    }
                }

                // Repeat
                VStack(alignment: .leading, spacing: 8) {
                    Text("重复设置")
                        .font(.headline)

                    Picker("重复类型", selection: $repeatType) {
                        ForEach(RepeatType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Priority
                VStack(alignment: .leading, spacing: 8) {
                    Text("优先级")
                        .font(.headline)

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

    private func saveTask() {
        let estimatedDuration = TimeInterval(estimatedHours * 3600 + estimatedMinutes * 60)

        let task = TodoTask(
            title: title,
            description: "",
            estimatedDuration: estimatedDuration,
            dueDate: hasDueDate ? dueDate : nil,
            repeatType: repeatType,
            priority: priority
        )

        taskManager.addTask(task)
        dismiss()
    }
}

#Preview {
    CleanContentView()
}