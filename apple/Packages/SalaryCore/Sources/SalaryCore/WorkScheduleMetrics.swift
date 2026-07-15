import Foundation

public enum WorkScheduleMetrics {
    public static func effectiveWorkSeconds(
        workStart: String,
        workEnd: String,
        lunchStart: String,
        lunchEnd: String
    ) throws -> Int {
        guard let start = SalaryParsing.minutes(workStart),
              let end = SalaryParsing.minutes(workEnd),
              let lunchStartMinutes = SalaryParsing.minutes(lunchStart),
              let lunchEndMinutes = SalaryParsing.minutes(lunchEnd),
              start < lunchStartMinutes,
              lunchStartMinutes <= lunchEndMinutes,
              lunchEndMinutes <= end
        else { throw SalaryCoreError.invalidTimeRange }
        return ((lunchStartMinutes - start) + (end - lunchEndMinutes)) * 60
    }
}
