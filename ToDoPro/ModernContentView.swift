//
//  ModernContentView.swift
//  ToDoPro
//
//  Created by Youran Tao Jensen on 01/10/2025.
//

import SwiftUI

struct ModernContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ModernHomeView(taskManager: taskManager, showingAddTask: $showingAddTask)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("首页")
                }
                .tag(0)

            ModernTasksView(taskManager: taskManager)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "list.bullet.circle.fill" : "list.bullet.circle")
                    Text("任务")
                }
                .tag(1)

            ModernAnalyticsView(taskManager: taskManager)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    Text("分析")
                }
                .tag(2)
        }
        .tint(.indigo)
        .sheet(isPresented: $showingAddTask) {
            ModernAddTaskView(taskManager: taskManager)
        }
    }
}

struct ModernHomeView: View {
    @ObservedObject var taskManager: TaskManager
    @Binding var showingAddTask: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    // Hero Section
                    ModernHeroSection(taskManager: taskManager)

                    // Quick Stats
                    ModernQuickStats(taskManager: taskManager)

                    // Active Task
                    if let activeTask = taskManager.currentActiveTask {
                        ModernActiveTaskCard(task: activeTask, taskManager: taskManager)
                    }

                    // Today's Tasks Preview
                    ModernTodayTasksPreview(taskManager: taskManager)

                    // Add Task CTA
                    ModernAddTaskButton(action: { showingAddTask = true })

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
    }
}

struct ModernHeroSection: View {
    @ObservedObject var taskManager: TaskManager

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好"
        case 12..<17: return "下午好"
        case 17..<22: return "晚上好"
        default: return "夜深了"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("准备好开始高效的一天了吗？")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Today's Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.indigo.opacity(0.1), lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: min(1.0, taskManager.dailyStats.completionRate))
                        .stroke(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 60, height: 60)

                    Text("\(Int(taskManager.dailyStats.completionRate * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.indigo)
                }
            }

            // Today's Date
            HStack {
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("今日完成率")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct ModernQuickStats: View {
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ModernStatCard(
                title: "今日任务",
                value: "\(taskManager.getTasksForToday().count)",
                subtitle: "个待完成",
                color: .blue,
                icon: "calendar.badge.clock",
                trend: nil
            )

            ModernStatCard(
                title: "剩余时间",
                value: taskManager.todaysRemainingWorkload.shortFormattedTime,
                subtitle: "工作量",
                color: .orange,
                icon: "hourglass",
                trend: nil
            )

            ModernStatCard(
                title: "生产力",
                value: "\(Int(taskManager.dailyStats.productivityScore))",
                subtitle: "今日评分",
                color: .green,
                icon: "chart.line.uptrend.xyaxis",
                trend: "+5%"
            )

            ModernStatCard(
                title: "空闲时间",
                value: taskManager.todaysFreeTime.shortFormattedTime,
                subtitle: "可用时间",
                color: .purple,
                icon: "leaf",
                trend: nil
            )
        }
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let trend: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())

                Spacer()

                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct ModernActiveTaskCard: View {
    let task: TodoTask
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("正在专注")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text(task.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }

                Spacer()

                Button(action: {
                    taskManager.completeTask(task.id)
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }

            // Time Display
            VStack(spacing: 8) {
                Text(task.remainingTime.formattedTime)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Text("剩余时间")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Progress Bar
            VStack(spacing: 8) {
                ProgressView(value: task.progress)
                    .tint(.white)
                    .scaleEffect(y: 2)

                HStack {
                    Text("进度")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("\(Int(task.progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Control Buttons
            HStack(spacing: 12) {
                Button(action: {
                    if task.status == .inProgress {
                        taskManager.pauseTask(task.id)
                    } else {
                        taskManager.resumeTask(task.id)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: task.status == .inProgress ? "pause.fill" : "play.fill")
                        Text(task.status == .inProgress ? "暂停" : "继续")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.indigo)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
                }

                Button(action: {
                    taskManager.completeTask(task.id)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text("完成")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .indigo.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

struct ModernTodayTasksPreview: View {
    @ObservedObject var taskManager: TaskManager

    var todaysTasks: [TodoTask] {
        Array(taskManager.getTasksForToday().prefix(3))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日任务")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Button("查看全部") {
                    // Navigate to tasks tab
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.indigo)
            }

            if todaysTasks.isEmpty {
                ModernEmptyState(
                    icon: "checkmark.circle",
                    title: "今天没有任务",
                    subtitle: "享受你的空闲时光！",
                    color: .green
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todaysTasks) { task in
                        ModernTaskPreviewRow(task: task, taskManager: taskManager)
                    }
                }
            }
        }
    }
}

struct ModernTaskPreviewRow: View {
    let task: TodoTask
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        HStack(spacing: 16) {
            // Priority Indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(priorityColor)
                .frame(width: 4, height: 44)

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(task.estimatedDuration.shortFormattedTime, systemImage: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    if task.repeatType != .none {
                        Label(task.repeatType.displayName, systemImage: "repeat")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.indigo)
                    }

                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(.dateTime.hour().minute()), systemImage: "alarm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Status & Action
            VStack(spacing: 8) {
                Text(task.status.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(task.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.status.color.opacity(0.1))
                    .clipShape(Capsule())

                if task.status == .pending {
                    Button(action: {
                        taskManager.startTask(task.id)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.indigo)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
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

struct ModernEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.05))
        )
    }
}

struct ModernAddTaskButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))

                Text("添加新任务")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .indigo.opacity(0.3), radius: 10, x: 0, y: 4)
        }
    }
}

struct ModernTasksView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var searchText = ""
    @State private var selectedFilter: TaskStatus? = nil

    var filteredTasks: [TodoTask] {
        var tasks = taskManager.tasks.filter { !$0.isArchived }

        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let filter = selectedFilter {
            tasks = tasks.filter { $0.status == filter }
        }

        return tasks.sorted { task1, task2 in
            if task1.priority != task2.priority {
                return task1.priority > task2.priority
            }
            return (task1.dueDate ?? Date.distantFuture) < (task2.dueDate ?? Date.distantFuture)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 16) {
                    ModernSearchBar(text: $searchText)
                    ModernFilterBar(selectedFilter: $selectedFilter)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)

                // Tasks List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            ModernTaskCard(task: task, taskManager: taskManager)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("任务列表")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                ModernAddTaskView(taskManager: taskManager)
            }
        }
    }
}

struct ModernSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            TextField("搜索任务...", text: $text)
                .font(.system(size: 16, weight: .medium))

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
        )
    }
}

struct ModernFilterBar: View {
    @Binding var selectedFilter: TaskStatus?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ModernFilterChip(
                    title: "全部",
                    isSelected: selectedFilter == nil,
                    color: .gray
                ) {
                    selectedFilter = nil
                }

                ForEach(TaskStatus.allCases, id: \.self) { status in
                    ModernFilterChip(
                        title: status.displayName,
                        isSelected: selectedFilter == status,
                        color: status.color
                    ) {
                        selectedFilter = selectedFilter == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                )
        }
    }
}

struct ModernTaskCard: View {
    let task: TodoTask
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        Label(task.estimatedDuration.shortFormattedTime, systemImage: "clock")

                        if task.repeatType != .none {
                            Label(task.repeatType.displayName, systemImage: "repeat")
                        }

                        if let dueDate = task.dueDate {
                            Label(dueDate.formatted(.dateTime.month().day().hour().minute()), systemImage: "calendar")
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 8) {
                    Text(task.status.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(task.status.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(task.status.color.opacity(0.1))
                        .clipShape(Capsule())

                    priorityIndicator
                }
            }

            // Actions
            HStack(spacing: 12) {
                if task.status == .pending {
                    ModernTaskActionButton(
                        title: "开始",
                        icon: "play.fill",
                        color: .indigo,
                        action: { taskManager.startTask(task.id) }
                    )
                } else if task.status == .inProgress {
                    ModernTaskActionButton(
                        title: "暂停",
                        icon: "pause.fill",
                        color: .orange,
                        action: { taskManager.pauseTask(task.id) }
                    )
                } else if task.status == .paused {
                    ModernTaskActionButton(
                        title: "继续",
                        icon: "play.fill",
                        color: .indigo,
                        action: { taskManager.resumeTask(task.id) }
                    )
                }

                if task.status != .completed {
                    ModernTaskActionButton(
                        title: "完成",
                        icon: "checkmark",
                        color: .green,
                        action: { taskManager.completeTask(task.id) }
                    )
                }

                Spacer()

                Button(action: { taskManager.deleteTask(task) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }

    private var priorityIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < task.priority + 1 ? priorityColor : Color.gray.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
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

struct ModernTaskActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

struct ModernAnalyticsView: View {
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    // Productivity Score Hero
                    ModernProductivityHero(taskManager: taskManager)

                    // Analytics Grid
                    ModernAnalyticsGrid(taskManager: taskManager)

                    // Time Breakdown
                    ModernTimeBreakdown(taskManager: taskManager)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("生产力分析")
        }
    }
}

struct ModernProductivityHero: View {
    @ObservedObject var taskManager: TaskManager

    var safeScore: Double {
        let score = taskManager.dailyStats.productivityScore
        return score.isFinite ? max(0, min(100, score)) : 0
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("今日生产力评分")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.indigo.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)

                // Progress Circle
                Circle()
                    .trim(from: 0, to: safeScore / 100)
                    .stroke(
                        LinearGradient(
                            colors: [.indigo, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 1.5), value: safeScore)

                // Score Display
                VStack(spacing: 4) {
                    Text("\(Int(safeScore))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("分")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Score Description
            Text(scoreDescription)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }

    private var scoreDescription: String {
        switch safeScore {
        case 0..<40: return "还有提升空间，加油！"
        case 40..<70: return "表现不错，继续保持！"
        case 70..<90: return "非常优秀，你很棒！"
        default: return "完美表现，太厉害了！"
        }
    }
}

struct ModernAnalyticsGrid: View {
    @ObservedObject var taskManager: TaskManager

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ModernAnalyticsCard(
                title: "完成任务",
                value: "\(taskManager.dailyStats.totalTasksCompleted)",
                subtitle: "今日已完成",
                color: .green,
                icon: "checkmark.circle.fill"
            )

            ModernAnalyticsCard(
                title: "工作效率",
                value: "\(Int(taskManager.dailyStats.efficiency * 100))%",
                subtitle: "时间利用率",
                color: .blue,
                icon: "speedometer"
            )

            ModernAnalyticsCard(
                title: "完成率",
                value: "\(Int(taskManager.dailyStats.completionRate * 100))%",
                subtitle: "任务完成率",
                color: .orange,
                icon: "target"
            )

            ModernAnalyticsCard(
                title: "逾期任务",
                value: "\(taskManager.dailyStats.overdueTasks)",
                subtitle: "需要关注",
                color: .red,
                icon: "exclamationmark.triangle.fill"
            )
        }
    }
}

struct ModernAnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct ModernTimeBreakdown: View {
    @ObservedObject var taskManager: TaskManager

    var timeData: [(String, TimeInterval, Color)] {
        [
            ("已完成工作", taskManager.todaysCompletedWork, .green),
            ("剩余工作", taskManager.todaysRemainingWorkload, .blue),
            ("空闲时间", taskManager.todaysFreeTime, .orange),
            ("松弛时间", taskManager.todaysSlackTime, .purple)
        ]
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("时间分配")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("今日概况")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                ForEach(Array(timeData.enumerated()), id: \.offset) { index, data in
                    let (label, time, color) = data
                    ModernTimeRow(label: label, time: time, color: color)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

struct ModernTimeRow: View {
    let label: String
    let time: TimeInterval
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(time.shortFormattedTime)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct ModernAddTaskView: View {
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
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("创建新任务")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("让我们开始一项新的挑战")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Title Input
                    ModernInputSection(title: "任务标题") {
                        TextField("输入你要完成的任务...", text: $title)
                            .font(.system(size: 16, weight: .medium))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }

                    // Time Settings
                    ModernInputSection(title: "预计用时") {
                        VStack(spacing: 16) {
                            Toggle(isOn: $hasEstimatedTime) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.indigo)
                                    Text("设置预计用时")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .indigo))

                            if hasEstimatedTime {
                                VStack(spacing: 12) {
                                    DatePicker("预计用时", selection: $estimatedTime, displayedComponents: [.hourAndMinute])
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()

                                    Text("总计: \(formattedEstimatedTime)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.indigo)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.indigo.opacity(0.05))
                                )
                            }
                        }
                    }

                    // Due Date
                    ModernInputSection(title: "截止时间") {
                        VStack(spacing: 16) {
                            Toggle(isOn: $hasDueDate) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.orange)
                                    Text("设置截止时间")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .orange))

                            if hasDueDate {
                                DatePicker("截止时间", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.graphical)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.orange.opacity(0.05))
                                    )
                            }
                        }
                    }

                    // Repeat Settings
                    ModernInputSection(title: "重复设置") {
                        VStack(spacing: 16) {
                            Picker("重复类型", selection: $repeatType) {
                                ForEach(RepeatType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )

                            if repeatType == .custom {
                                HStack {
                                    Text("每")
                                    Stepper("\(Int(repeatInterval))", value: $repeatInterval, in: 1...365, step: 1)
                                        .labelsHidden()
                                    Text("天重复")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.purple.opacity(0.05))
                                )
                            }
                        }
                    }

                    // Priority
                    ModernInputSection(title: "优先级") {
                        HStack(spacing: 12) {
                            ForEach(0..<3) { index in
                                ModernPriorityButton(
                                    level: index,
                                    isSelected: priority == index
                                ) {
                                    priority = index
                                }
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("创建") {
                        saveTask()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(title.isEmpty ? .secondary : .indigo)
                    .disabled(title.isEmpty)
                }
            }
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
            estimatedDuration = 3600
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

struct ModernInputSection<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModernPriorityButton: View {
    let level: Int
    let isSelected: Bool
    let action: () -> Void

    private var priorityData: (String, Color) {
        switch level {
        case 0: return ("低", .green)
        case 1: return ("中", .orange)
        case 2: return ("高", .red)
        default: return ("", .gray)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= level ? priorityData.1 : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Text(priorityData.0)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : priorityData.1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? priorityData.1 : priorityData.1.opacity(0.1))
            )
        }
    }
}

#Preview {
    ModernContentView()
}