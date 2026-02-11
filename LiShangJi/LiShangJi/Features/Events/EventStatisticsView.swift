//
//  EventStatisticsView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/7.
//

import SwiftUI
import SwiftData
import Charts

/// 事件统计视图
struct EventStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    let events: [EventReminder]
    @State private var viewModel = EventStatisticsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 总览卡片
                overviewSection

                // 完成率环形图
                completionRateSection

                // 类别分布
                categoryDistributionSection

                // 月度趋势
                monthlyTrendSection

                // 即将到来的事件
                upcomingSection
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.top, AppConstants.Spacing.md)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .navigationTitle("事件统计")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") { dismiss() }
            }
        }
        .onAppear {
            viewModel.loadData(from: events)
        }
    }

    // MARK: - 总览卡片

    private var overviewSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.md) {
                statCard("总事件", value: "\(viewModel.totalCount)", color: Color.theme.info)
                statCard("已完成", value: "\(viewModel.completedCount)", color: Color.theme.received)
            }
            HStack(spacing: AppConstants.Spacing.md) {
                statCard("待处理", value: "\(viewModel.pendingCount)", color: Color.theme.warning)
                statCard("已过期", value: "\(viewModel.overdueCount)", color: Color.theme.sent)
            }
        }
    }

    private func statCard(_ label: String, value: String, color: Color) -> some View {
        LSJCard {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.sm) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.theme.textSecondary)
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 完成率

    private var completionRateSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("完成率")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            LSJCard {
                if viewModel.totalCount == 0 {
                    emptyPlaceholder(icon: "chart.pie.fill", text: "暂无事件数据")
                } else {
                    HStack(spacing: AppConstants.Spacing.xl) {
                        // 环形图
                        ZStack {
                            Circle()
                                .stroke(Color.theme.divider, lineWidth: 12)

                            Circle()
                                .trim(from: 0, to: CGFloat(viewModel.completionRate / 100.0))
                                .stroke(
                                    Color.theme.received,
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.6), value: viewModel.completionRate)

                            VStack(spacing: 2) {
                                Text(String(format: "%.0f%%", viewModel.completionRate))
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(Color.theme.textPrimary)
                                Text("完成率")
                                    .font(.caption2)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                        }
                        .frame(width: 100, height: 100)

                        // 详细数据
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                            statRow(color: Color.theme.received, label: "已完成", count: viewModel.completedCount)
                            statRow(color: Color.theme.warning, label: "待处理", count: viewModel.pendingCount - viewModel.overdueCount)
                            statRow(color: Color.theme.sent, label: "已过期", count: viewModel.overdueCount)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private func statRow(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: AppConstants.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
            Spacer()
            Text("\(count)")
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(Color.theme.textPrimary)
        }
    }

    // MARK: - 类别分布

    private var categoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("类别分布")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            LSJCard {
                if viewModel.categoryStats.isEmpty {
                    emptyPlaceholder(icon: "chart.bar.fill", text: "暂无数据")
                } else {
                    VStack(spacing: AppConstants.Spacing.md) {
                        // 柱状图
                        Chart(viewModel.categoryStats) { stat in
                            BarMark(
                                x: .value("类别", stat.categoryName),
                                y: .value("数量", stat.count)
                            )
                            .foregroundStyle(Color.theme.primary.gradient)
                            .cornerRadius(4)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let count = value.as(Int.self) {
                                        Text("\(count)")
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            }
                        }
                        .frame(height: 180)

                        Divider()
                            .foregroundStyle(Color.theme.divider)

                        // 详细列表
                        ForEach(viewModel.categoryStats) { stat in
                            HStack(spacing: AppConstants.Spacing.md) {
                                Image(systemName: stat.categoryIcon)
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.primary)
                                    .frame(width: 20)

                                Text(stat.categoryName)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.theme.textPrimary)

                                Spacer()

                                Text("\(stat.completedCount)/\(stat.count) 完成")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 月度趋势

    private var monthlyTrendSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("月度趋势")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            LSJCard {
                if viewModel.monthlyTrends.isEmpty || viewModel.monthlyTrends.allSatisfy({ $0.totalCount == 0 }) {
                    emptyPlaceholder(icon: "chart.line.uptrend.xyaxis", text: "暂无趋势数据")
                } else {
                    Chart(viewModel.monthlyTrends) { item in
                        BarMark(
                            x: .value("月份", item.month),
                            y: .value("数量", item.totalCount)
                        )
                        .foregroundStyle(Color.theme.info.gradient)
                        .cornerRadius(4)

                        BarMark(
                            x: .value("月份", item.month),
                            y: .value("完成", item.completedCount)
                        )
                        .foregroundStyle(Color.theme.received.gradient)
                        .cornerRadius(4)
                    }
                    .chartForegroundStyleScale([
                        "总数": Color.theme.info,
                        "已完成": Color.theme.received
                    ])
                    .frame(height: 180)
                }
            }
        }
    }

    // MARK: - 即将到来的事件

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("即将到来")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            LSJCard {
                if viewModel.upcomingEvents.isEmpty {
                    emptyPlaceholder(icon: "calendar", text: "暂无即将到来的事件")
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.upcomingEvents) { event in
                            HStack(spacing: AppConstants.Spacing.md) {
                                Image(systemName: CategoryItem.iconForName(event.eventCategory))
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.primary)
                                    .frame(width: 24, height: 24)
                                    .background(Color.theme.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(event.title)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.theme.textPrimary)
                                        .lineLimit(1)
                                    Text(formatEventDate(event.eventDate))
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.textSecondary)
                                }

                                Spacer()

                                let days = event.daysUntilEvent
                                Text(days == 0 ? "今天" : "\(days)天后")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(days <= 3 ? Color.theme.primary : Color.theme.textSecondary)
                            }
                            .padding(.vertical, AppConstants.Spacing.sm)

                            if event.id != viewModel.upcomingEvents.last?.id {
                                Divider()
                                    .foregroundStyle(Color.theme.divider)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 辅助

    private func emptyPlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: AppConstants.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Color.theme.textSecondary.opacity(0.3))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }

    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}
