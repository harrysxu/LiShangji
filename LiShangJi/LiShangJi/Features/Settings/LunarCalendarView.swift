//
//  LunarCalendarView.swift
//  LiShangJi
//
//  Created by 徐晓龙 on 2026/2/6.
//

import SwiftUI

/// 农历日历与节日视图
struct LunarCalendarView: View {
    private let lunarService = LunarCalendarService.shared

    private var todayLunar: (monthName: String, dayName: String, yearGanZhi: String, shengXiao: String) {
        let result = lunarService.solarToLunar(date: Date())
        return (result.monthName, result.dayName, result.yearGanZhi, result.shengXiao)
    }

    private var todayFestival: String? {
        lunarService.festivalName(for: Date())
    }

    /// 即将到来的节日列表
    private var upcomingFestivals: [(name: String, date: Date, lunarDate: String)] {
        let calendar = Calendar.current
        var festivals: [(name: String, date: Date, lunarDate: String)] = []

        // 检查未来90天
        for dayOffset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            if let festivalName = lunarService.festivalName(for: date) {
                let lunar = lunarService.lunarDateString(from: date)
                festivals.append((name: festivalName, date: date, lunarDate: lunar))
            }
        }

        return festivals
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.xl) {
                // 今日农历
                todayCard

                // 即将到来的节日
                festivalSection
            }
            .padding(.horizontal, AppConstants.Spacing.lg)
            .padding(.bottom, AppConstants.Spacing.xxxl)
        }
        .lsjPageBackground()
        .navigationTitle("农历与节日")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 今日农历卡片

    private var todayCard: some View {
        VStack(spacing: AppConstants.Spacing.lg) {
            // 农历日期
            VStack(spacing: AppConstants.Spacing.sm) {
                Text("今日农历")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(todayLunar.monthName)月\(todayLunar.dayName)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: AppConstants.Spacing.md) {
                    Text(todayLunar.yearGanZhi + "年")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("生肖\(todayLunar.shengXiao)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            // 今日节日
            if let festival = todayFestival {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("今天是\(festival)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, AppConstants.Spacing.lg)
                .padding(.vertical, AppConstants.Spacing.sm)
                .background(.white.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppConstants.Spacing.xl)
        .background(
            LinearGradient(
                colors: [Color.theme.primary, Color.theme.primary.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.lg))
    }

    // MARK: - 节日列表

    private var festivalSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.md) {
            Text("近期节日")
                .font(.headline)
                .foregroundStyle(Color.theme.textPrimary)

            if upcomingFestivals.isEmpty {
                LSJCard {
                    VStack(spacing: AppConstants.Spacing.md) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.theme.textSecondary.opacity(0.3))
                        Text("近期无重要节日")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppConstants.Spacing.xxl)
                }
            } else {
                LSJCard {
                    VStack(spacing: 0) {
                        ForEach(Array(upcomingFestivals.enumerated()), id: \.offset) { index, festival in
                            HStack(spacing: AppConstants.Spacing.md) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(festival.name)
                                        .font(.headline)
                                        .foregroundStyle(Color.theme.textPrimary)
                                    Text("农历 \(festival.lunarDate)")
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(festival.date.chineseMonthDay)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.theme.textPrimary)
                                    Text(daysUntil(festival.date))
                                        .font(.caption)
                                        .foregroundStyle(Color.theme.primary)
                                }
                            }
                            .padding(.vertical, AppConstants.Spacing.sm)

                            if index < upcomingFestivals.count - 1 {
                                Divider().foregroundStyle(Color.theme.divider)
                            }
                        }
                    }
                }
            }
        }
    }

    private func daysUntil(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days == 0 { return "今天" }
        if days == 1 { return "明天" }
        if days == 2 { return "后天" }
        return "\(days)天后"
    }
}
