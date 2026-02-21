import SwiftUI

#if canImport(Charts)
import Charts

@available(iOS 16.0, *)
struct ForgettingCurveCard: View {
    let item: StudyItem
    var now: Date = .init()
    var calculator = ForgettingCurveCalculator()

    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private let axisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("Md")
        return formatter
    }()

    var body: some View {
        let samples = chartSamples
        let indicator = indicator(for: samples)
        let retentionText = indicator.map { "\(Int(round($0.retention)))%" }
            ?? defaultRetentionText

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.deck)
                    .font(.headline)
                Text(item.rangeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let lastReviewDate {
                    Text("最終復習: \(lastReviewText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("まだ復習の記録がありません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(samples) { sample in
                    AreaMark(
                        x: .value("時刻", sample.date),
                        y: .value("記憶率", sample.retention)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                }

                ForEach(samples) { sample in
                    LineMark(
                        x: .value("時刻", sample.date),
                        y: .value("記憶率", sample.retention)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.monotone)
                }

                if let indicator {
                    PointMark(
                        x: .value("現在", indicator.date),
                        y: .value("現在の記憶率", indicator.retention)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(60)

                    RuleMark(x: .value("現在", indicator.date))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    if let dateValue = value.as(Date.self) {
                        AxisValueLabel(axisFormatter.string(from: dateValue))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let percent = value.as(Double.self) {
                        AxisValueLabel("\(Int(percent))%")
                    }
                }
            }
            .frame(height: 180)

            HStack {
                Text("現在の記憶率")
                Spacer()
                Text(retentionText)
                    .font(.title3.weight(.semibold))
            }
            .accessibilityElement(children: .combine)

            if let nextDueText {
                Text("次の復習予定: \(nextDueText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var chartSamples: [ForgettingCurveCalculator.Sample] {
        calculator.samples(for: item, now: now)
    }

    private var lastReviewDate: Date? {
        item.history.last?.timestamp
    }

    private var lastReviewText: String {
        guard let lastReviewDate else { return "" }
        return relativeFormatter.localizedString(for: lastReviewDate, relativeTo: now)
    }

    private var defaultRetentionText: String {
        let value = calculator.retentionPercentage(for: item, at: now)
        return "\(Int(round(value)))%"
    }

    private func indicator(
        for samples: [ForgettingCurveCalculator.Sample]
    ) -> (date: Date, retention: Double)? {
        guard let first = samples.first?.date, let last = samples.last?.date else {
            return nil
        }
        let clampedDate = min(max(now, first), last)
        let retention = calculator.retentionPercentage(for: item, at: clampedDate)
        return (clampedDate, retention)
    }

    private var nextDueText: String? {
        let due = item.nextDueAt
        guard due > .distantPast else { return nil }
        if abs(due.timeIntervalSince(now)) < 60 * 60 * 24 * 2 {
            return relativeFormatter.localizedString(for: due, relativeTo: now)
        }
        return axisFormatter.string(from: due)
    }
}
#endif
