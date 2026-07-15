import ActivityKit
import SalaryCore

struct SalaryActivityAttributes: ActivityAttributes {
    typealias ContentState = SalaryActivityContentState

    let context: SalaryActivityStaticContext
}
