//
//  StatisticsView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI
import SwiftData
import Charts

/// 统计分析页
struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatisticsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 页面标题
                HStack(alignment: .bottom) {
                    Text("统计")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.theme.textPrimary)
                    Spacer()
                }
                .padding(.top, AppConstants.Spacing.sm)

                // 时间范围筛选
                timeFilterSection

                // 总览卡片
                overviewSection

                if PremiumManager.shared.isPremium {
                    // 收支趋势图表
                    trendChartSection

                    // 关系分布
                    relationDistributionSection

                    // 往来排行
                    topContactsSection
                } else {
                    // 免费版：图表加锁
                    premiumLockedChartsSection
                }
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadData(context: modelContext)
        }
        .alert("出错了", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 时间范围筛选

    private var timeFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Spacing.sm) {
                filterChip("全部", isSelected: viewModel.timeFilter == .allTime) {
                    viewModel.timeFilter = .allTime
                    viewModel.loadData(context: modelContext)
                }

                ForEach(viewModel.availableYears, id: \.self) { year in
                    filterChip("\(year)年", isSelected: viewModel.timeFilter == .year(year)) {
                        viewModel.timeFilter = .year(year)
                        viewModel.loadData(context: modelContext)
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.theme.primary : Color.theme.card)
                .foregroundStyle(isSelected ? .white : Color.theme.textSecondary)
                .clipShape(Capsule())
        }
    }

    // MARK: - 总览

    private var overviewSection: some View {
        VStack(spacing: AppConstants.Spacing.md) {
            HStack(spacing: AppConstants.Spacing.md) {
                statCard("总收到", value: viewModel.totalReceived.currencyString, color: Color.theme.received)
                statCard("总送出", value: viewModel.totalSent.currencyString, color: Color.theme.sent)
            }

            HStack(spacing: AppConstants.Spacing.md) {
                statCard("结余", value: viewModel.balance.balanceString, color: viewModel.balance >= 0 ? Color.theme.received : Color.theme.sent)
                statCard("记录数", value: "\(viewModel.recordCount) 笔", color: Color.theme.info)
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

    // MARK: - 收支趋势图

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("收支趋势")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            LSJCard {
                if viewModel.monthlyTrends.isEmpty {
                    emptyChartPlaceholder(icon: "chart.bar.fill", text: "暂无数据，记录后即可查看趋势")
                } else {
                    Chart(viewModel.monthlyTrends) { item in
                        BarMark(
                            x: .value("月份", item.month),
                            y: .value("金额", item.amount)
                        )
                        .foregroundStyle(by: .value("类型", item.direction))
                        .cornerRadius(4)
                    }
                    .chartForegroundStyleScale([
                        "收到": Color.theme.received,
                        "送出": Color.theme.sent
                    ])
                    .chartLegend(position: .top, alignment: .trailing)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(formatAxisAmount(amount))
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        }
                    }
                    .frame(height: 220)
                    .padding(.top, AppConstants.Spacing.sm)
                }
            }
        }
    }

    // MARK: - 关系分布

    private var relationDistributionSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("关系分布")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            LSJCard {
                if viewModel.relationStats.isEmpty {
                    emptyChartPlaceholder(icon: "chart.pie.fill", text: "暂无数据")
                } else {
                    VStack(spacing: AppConstants.Spacing.md) {
                        // 饼图
                        Chart(viewModel.relationStats) { stat in
                            SectorMark(
                                angle: .value("金额", stat.totalAmount),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("关系", stat.relation))
                            .cornerRadius(3)
                        }
                        .chartLegend(position: .bottom, alignment: .center, spacing: 12)
                        .frame(height: 200)

                        // 详细列表
                        Divider()
                            .foregroundStyle(Color.theme.divider)

                        ForEach(viewModel.relationStats) { stat in
                            HStack {
                                Circle()
                                    .fill(Color(hex: stat.color) ?? Color.gray)
                                    .frame(width: 8, height: 8)
                                Text(stat.relation)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.theme.textPrimary)
                                Spacer()
                                Text("\(stat.recordCount) 笔")
                                    .font(.caption)
                                    .foregroundStyle(Color.theme.textSecondary)
                                Text(stat.totalAmount.currencyString)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(Color.theme.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 往来排行

    private var topContactsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("往来排行")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            LSJCard {
                if viewModel.topContacts.isEmpty {
                    emptyChartPlaceholder(icon: "person.3.fill", text: "暂无往来数据")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.topContacts.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: AppConstants.Spacing.md) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(index < 3 ? Color.theme.primary : Color.theme.textSecondary)
                                    .frame(width: 20)

                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.theme.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("收 \(item.received.currencyString)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(Color.theme.received)
                                    Text("送 \(item.sent.currencyString)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(Color.theme.sent)
                                }
                            }
                            .padding(.vertical, AppConstants.Spacing.sm)

                            if index < viewModel.topContacts.count - 1 {
                                Divider()
                                    .foregroundStyle(Color.theme.divider)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 高级版锁定区域

    private var premiumLockedChartsSection: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // 收支趋势 - 模糊
            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                Text("收支趋势")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)

                LSJCard {
                    emptyChartPlaceholder(icon: "chart.bar.fill", text: "")
                }
                .overlay {
                    PremiumBlurOverlay()
                }
            }

            // 关系分布 - 模糊
            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                Text("关系分布")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)

                LSJCard {
                    emptyChartPlaceholder(icon: "chart.pie.fill", text: "")
                }
                .overlay {
                    PremiumBlurOverlay()
                }
            }

            // 往来排行 - 模糊
            VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
                Text("往来排行")
                    .font(.headline)
                    .foregroundStyle(Color.theme.textPrimary)

                LSJCard {
                    emptyChartPlaceholder(icon: "person.3.fill", text: "")
                }
                .overlay {
                    PremiumBlurOverlay()
                }
            }
        }
    }

    // MARK: - 空状态

    private func emptyChartPlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Color.theme.textSecondary.opacity(0.3))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
    }

    // MARK: - 辅助

    private func formatAxisAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return "\(Int(amount / 10000))万"
        } else if amount >= 1000 {
            return "\(Int(amount / 1000))千"
        }
        return "\(Int(amount))"
    }
}
