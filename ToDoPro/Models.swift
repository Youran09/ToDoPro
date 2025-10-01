//
//  Models.swift
//  ToDoPro
//
//  Created by Youran Tao Jensen on 01/10/2025.
//

import Foundation
import SwiftUI

enum RepeatType: String, CaseIterable, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .none: return "不重复"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        case .custom: return "自定义"
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case paused = "paused"
    case overdue = "overdue"

    var displayName: String {
        switch self {
        case .pending: return "待开始"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .paused: return "已暂停"
        case .overdue: return "已逾期"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .paused: return .yellow
        case .overdue: return .red
        }
    }
}

struct TodoTask: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String
    var estimatedDuration: TimeInterval // in seconds
    var actualDuration: TimeInterval
    var dueDate: Date?
    var createdDate: Date
    var completedDate: Date?
    var startTime: Date?
    var pauseTime: Date?
    var status: TaskStatus
    var repeatType: RepeatType
    var repeatInterval: Int // for custom repeat
    var isArchived: Bool
    var tags: [String]
    var priority: Int // 0 = low, 1 = medium, 2 = high

    init(title: String, description: String, estimatedDuration: TimeInterval, dueDate: Date? = nil, repeatType: RepeatType = .none, repeatInterval: Int = 1, tags: [String] = [], priority: Int = 0) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.estimatedDuration = estimatedDuration
        self.actualDuration = 0
        self.dueDate = dueDate
        self.createdDate = Date()
        self.completedDate = nil
        self.startTime = nil
        self.pauseTime = nil
        self.status = .pending
        self.repeatType = repeatType
        self.repeatInterval = repeatInterval
        self.isArchived = false
        self.tags = tags
        self.priority = priority
    }

    // Computed properties
    var remainingTime: TimeInterval {
        guard status == .inProgress, let startTime = startTime else { return estimatedDuration }
        let elapsed = Date().timeIntervalSince(startTime) - pausedDuration
        let remaining = estimatedDuration - elapsed
        return max(0, remaining.isFinite ? remaining : 0)
    }

    var elapsedTime: TimeInterval {
        guard let startTime = startTime else { return 0 }
        let elapsed: TimeInterval
        if status == .inProgress {
            elapsed = Date().timeIntervalSince(startTime) - pausedDuration
        } else if status == .completed, let completedDate = completedDate {
            elapsed = completedDate.timeIntervalSince(startTime) - pausedDuration
        } else {
            elapsed = actualDuration
        }
        return elapsed.isFinite ? max(0, elapsed) : 0
    }

    var pausedDuration: TimeInterval {
        // Calculate total paused time (simplified - in real app would track pause sessions)
        return 0
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return Date() > dueDate && status != .completed
    }

    var progress: Double {
        guard estimatedDuration > 0 else { return 0 }
        let progressValue = elapsedTime / estimatedDuration
        return progressValue.isFinite ? min(1.0, max(0.0, progressValue)) : 0.0
    }

    // Helper methods
    mutating func start() {
        status = .inProgress
        startTime = Date()
        pauseTime = nil
    }

    mutating func pause() {
        guard status == .inProgress else { return }
        status = .paused
        pauseTime = Date()
    }

    mutating func resume() {
        guard status == .paused else { return }
        status = .inProgress
        pauseTime = nil
    }

    mutating func complete() {
        status = .completed
        completedDate = Date()
        actualDuration = elapsedTime
    }

    mutating func reset() {
        status = .pending
        startTime = nil
        pauseTime = nil
        completedDate = nil
        actualDuration = 0
    }

    func shouldRepeat() -> Bool {
        return repeatType != .none && status == .completed
    }

    func nextRepeatDate() -> Date? {
        guard shouldRepeat(), let dueDate = dueDate else { return nil }

        let calendar = Calendar.current
        switch repeatType {
        case .daily:
            return calendar.date(byAdding: .day, value: repeatInterval, to: dueDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: repeatInterval, to: dueDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: repeatInterval, to: dueDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: repeatInterval, to: dueDate)
        default:
            return nil
        }
    }
}

struct DailyStats: Codable {
    let date: Date
    var totalTasksCompleted: Int = 0
    var totalTimeSpent: TimeInterval = 0
    var totalEstimatedTime: TimeInterval = 0
    var productivityScore: Double = 0
    var tasksCreated: Int = 0
    var overdueTasks: Int = 0

    var efficiency: Double {
        guard totalEstimatedTime > 0 else { return 0 }
        let eff = totalTimeSpent / totalEstimatedTime
        return eff.isFinite ? min(1.0, max(0.0, eff)) : 0.0
    }

    var completionRate: Double {
        guard tasksCreated > 0 else { return 0 }
        let rate = Double(totalTasksCompleted) / Double(tasksCreated)
        return rate.isFinite ? min(1.0, max(0.0, rate)) : 0.0
    }
}

struct TimeBlock {
    let startTime: Date
    let endTime: Date
    let task: TodoTask?
    let type: BlockType

    enum BlockType {
        case work
        case `break`
        case free
        case slack
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// Extension for time formatting
extension TimeInterval {
    var formattedTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var shortFormattedTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var countdownFormattedTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}