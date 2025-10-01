//
//  TaskManager.swift
//  ToDoPro
//
//  Created by Youran Tao Jensen on 01/10/2025.
//

import Foundation
import SwiftUI
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published var dailyStats: DailyStats = DailyStats(date: Date())
    @Published var currentActiveTask: TodoTask?

    private let userDefaults = UserDefaults.standard
    private let tasksKey = "saved_tasks"
    private let statsKey = "daily_stats"

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadTasks()
        loadDailyStats()
        startPeriodicUpdates()
        updateTaskStatuses()

        // Add sample tasks if empty (for testing)
        if tasks.isEmpty {
            addSampleTasks()
        }
    }

    private func addSampleTasks() {
        let sampleTasks = [
            TodoTask(
                title: "完成项目报告",
                description: "编写月度工作总结",
                estimatedDuration: 2 * 3600, // 2 hours
                dueDate: Calendar.current.date(byAdding: .hour, value: 4, to: Date()),
                repeatType: .weekly,
                priority: 2
            ),
            TodoTask(
                title: "学习SwiftUI",
                description: "练习SwiftUI新功能",
                estimatedDuration: 1.5 * 3600, // 1.5 hours
                repeatType: .daily,
                priority: 1
            ),
            TodoTask(
                title: "运动健身",
                description: "每日跑步30分钟",
                estimatedDuration: 0.5 * 3600, // 30 minutes
                repeatType: .daily,
                priority: 0
            )
        ]

        for task in sampleTasks {
            tasks.append(task)
        }
        saveTasks()
    }

    // MARK: - Persistence
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: tasksKey)
        }
    }

    private func loadTasks() {
        guard let data = userDefaults.data(forKey: tasksKey),
              let decoded = try? JSONDecoder().decode([TodoTask].self, from: data) else {
            return
        }
        tasks = decoded
    }

    private func saveDailyStats() {
        if let encoded = try? JSONEncoder().encode(dailyStats) {
            userDefaults.set(encoded, forKey: statsKey + "_\(dailyStats.date.formatted(.dateTime.day().month().year()))")
        }
    }

    private func loadDailyStats() {
        let today = Date()
        let key = statsKey + "_\(today.formatted(.dateTime.day().month().year()))"

        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(DailyStats.self, from: data) else {
            dailyStats = DailyStats(date: today)
            return
        }

        dailyStats = decoded
    }

    // MARK: - Task Management
    func addTask(_ task: TodoTask) {
        var newTask = task
        newTask.createdDate = Date()
        tasks.append(newTask)
        dailyStats.tasksCreated += 1
        saveTasks()
        saveDailyStats()
    }

    func updateTask(_ task: TodoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }

    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        if currentActiveTask?.id == task.id {
            currentActiveTask = nil
        }
        saveTasks()
    }

    func startTask(_ taskId: UUID) {
        // Stop current active task if any
        if let activeTask = currentActiveTask {
            pauseTask(activeTask.id)
        }

        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].start()
            currentActiveTask = tasks[index]
            saveTasks()
        }
    }

    func pauseTask(_ taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].pause()
            if currentActiveTask?.id == taskId {
                currentActiveTask = nil
            }
            saveTasks()
        }
    }

    func resumeTask(_ taskId: UUID) {
        // Stop current active task if any
        if let activeTask = currentActiveTask {
            pauseTask(activeTask.id)
        }

        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].resume()
            currentActiveTask = tasks[index]
            saveTasks()
        }
    }

    func completeTask(_ taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            let task = tasks[index]
            tasks[index].complete()

            // Update daily stats
            dailyStats.totalTasksCompleted += 1
            dailyStats.totalTimeSpent += task.elapsedTime
            dailyStats.totalEstimatedTime += task.estimatedDuration

            if currentActiveTask?.id == taskId {
                currentActiveTask = nil
            }

            // Handle repeating tasks
            if task.shouldRepeat(), let nextDate = task.nextRepeatDate() {
                var repeatedTask = task
                repeatedTask.dueDate = nextDate
                repeatedTask.reset()
                addTask(repeatedTask)
            }

            saveTasks()
            saveDailyStats()
            updateProductivityScore()
        }
    }

    func resetTask(_ taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].reset()
            if currentActiveTask?.id == taskId {
                currentActiveTask = nil
            }
            saveTasks()
        }
    }

    // MARK: - Time Tracking & Analytics
    private func startPeriodicUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTaskStatuses()
            self.objectWillChange.send()
        }
    }

    private func updateTaskStatuses() {
        var hasChanges = false

        for index in tasks.indices {
            let oldStatus = tasks[index].status

            // Check for overdue tasks
            if tasks[index].isOverdue && tasks[index].status != .completed {
                tasks[index].status = .overdue
                if oldStatus != .overdue {
                    dailyStats.overdueTasks += 1
                    hasChanges = true
                }
            }
        }

        if hasChanges {
            saveTasks()
            saveDailyStats()
        }
    }

    private func updateProductivityScore() {
        let efficiency = dailyStats.efficiency
        let completionRate = dailyStats.completionRate
        let score = (efficiency + completionRate) / 2.0 * 100
        dailyStats.productivityScore = score.isFinite ? max(0, min(100, score)) : 0
        saveDailyStats()
    }

    // MARK: - Today's Schedule Analysis
    var todaysTasks: [TodoTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        return tasks.filter { task in
            if task.isArchived { return false }

            // Include tasks with no due date as "today's tasks"
            guard let dueDate = task.dueDate else { return true }

            // Include tasks due today
            return dueDate >= today && dueDate < tomorrow
        }
    }

    var todaysRemainingWorkload: TimeInterval {
        todaysTasks
            .filter { $0.status != .completed }
            .reduce(0) { $0 + $1.remainingTime }
    }

    var todaysCompletedWork: TimeInterval {
        todaysTasks
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.actualDuration }
    }

    var todaysTotalEstimatedWork: TimeInterval {
        todaysTasks.reduce(0) { $0 + $1.estimatedDuration }
    }

    // Assuming 8-hour work day
    var todaysFreeTime: TimeInterval {
        let workDayDuration: TimeInterval = 8 * 3600 // 8 hours
        let remaining = todaysRemainingWorkload
        return max(0, workDayDuration - remaining)
    }

    var todaysSlackTime: TimeInterval {
        let totalEstimated = todaysTotalEstimatedWork
        let completed = todaysCompletedWork
        return max(0, totalEstimated - completed)
    }

    var currentTaskRemainingTime: TimeInterval {
        currentActiveTask?.remainingTime ?? 0
    }

    // MARK: - Filtering & Sorting
    func getTasksForStatus(_ status: TaskStatus) -> [TodoTask] {
        tasks.filter { $0.status == status && !$0.isArchived }
    }

    func getTasksForToday() -> [TodoTask] {
        todaysTasks.sorted { task1, task2 in
            if task1.priority != task2.priority {
                return task1.priority > task2.priority
            }
            guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                return task1.dueDate != nil
            }
            return date1 < date2
        }
    }

    func getOverdueTasks() -> [TodoTask] {
        tasks.filter { $0.isOverdue && !$0.isArchived }
    }

    func getUpcomingTasks(days: Int = 7) -> [TodoTask] {
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: now)!

        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate > now && dueDate <= future && !task.isArchived
        }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }

    // MARK: - Search & Filter
    func searchTasks(query: String) -> [TodoTask] {
        guard !query.isEmpty else { return tasks }

        return tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query) ||
            task.description.localizedCaseInsensitiveContains(query) ||
            task.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    deinit {
        timer?.invalidate()
    }
}