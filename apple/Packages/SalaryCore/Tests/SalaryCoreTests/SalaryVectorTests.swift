import Foundation
import Testing
@testable import SalaryCore

private struct VectorSet: Decodable {
    let contractVersion: Int
    let vectorSetId: String
    let cases: [VectorCase]
}

private struct VectorCase: Decodable {
    let id: String
    let timeZone: String
    let now: String
    let config: SalaryConfiguration?
    let configRef: String?
    let expected: SalarySnapshot
}

@Suite("Cross-platform salary vectors")
struct SalaryVectorTests {
    @Test("Swift matches every shared reference vector")
    func sharedVectors() throws {
        let data = try Data(contentsOf: TestSupport.contractRoot.appending(path: "vectors/salary-vectors.json"))
        let vectors = try JSONDecoder().decode(VectorSet.self, from: data)
        #expect(vectors.contractVersion == 1)
        #expect(vectors.vectorSetId == "salary-core-v1-baseline")
        var resolved: [String: SalaryConfiguration] = [:]
        let holidays = try TestSupport.holidayCalendar()
        for item in vectors.cases {
            let config = item.config ?? item.configRef.flatMap { resolved[$0] }
            let unwrapped = try #require(config, "Unknown configRef in \(item.id)")
            resolved[item.id] = unwrapped
            let zone = try #require(TimeZone(identifier: item.timeZone))
            let actual = try SalaryCalculator.calculate(
                configuration: unwrapped,
                now: TestSupport.localDate(item.now, timeZone: zone),
                timeZone: zone,
                holidays: holidays
            )
            #expect(actual == item.expected, "Vector mismatch: \(item.id)")
        }
    }
}
