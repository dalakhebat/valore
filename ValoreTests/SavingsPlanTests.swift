import Foundation
import Testing
@testable import Valore

struct SavingsPlanTests {
    private func plan(target: Int = 1_000_000, saved: Int = 0, start: Date = date(2026, 10, 1), deadline: Date?, now: Date = date(2026, 10, 14)) -> SavingsPlan {
        SavingsPlan(target: target, saved: saved, start: start, deadline: deadline, now: now, calendar: wib)
    }

    @Test func remainingAndProgress() {
        let p = plan(target: 4_000_000, saved: 1_000_000, deadline: nil)
        #expect(p.remaining == 3_000_000)
        #expect(p.progress == 0.25)
        #expect(!p.isDone)
    }

    @Test func overSavingIsCappedAndDone() {
        let p = plan(target: 1_000_000, saved: 1_200_000, deadline: date(2026, 9, 1))
        #expect(p.remaining == 0)
        #expect(p.progress == 1)
        #expect(p.pace == .done)
        #expect(p.requiredPerPeriod(.monthly) == 0)
    }

    @Test(arguments: [
        (date(2026, 11, 11), 4, 250_000),   // tepat 28 hari = 4 minggu
        (date(2026, 11, 12), 5, 200_000),   // 29 hari → minggu kelima dihitung
    ])
    func weeklyRequirementRoundsUp(deadline: Date, weeks: Int, perWeek: Int) {
        let p = plan(deadline: deadline)
        #expect(p.periodsLeft(.weekly) == weeks)
        #expect(p.requiredPerPeriod(.weekly) == perWeek)
    }

    @Test func monthlyCountsPartialMonth() {
        #expect(plan(deadline: date(2026, 12, 14)).periodsLeft(.monthly) == 2)
        let partial = plan(deadline: date(2026, 12, 31))
        #expect(partial.periodsLeft(.monthly) == 3)
        #expect(partial.requiredPerPeriod(.monthly) == 333_334)
    }

    @Test func deadlineTodayStillLeavesOnePeriod() {
        let p = plan(deadline: date(2026, 10, 14, hour: 23))
        #expect(p.periodsLeft(.daily) == 1)
        #expect(p.requiredPerPeriod(.daily) == 1_000_000)
    }

    @Test func overdueHasNoPlan() {
        let p = plan(deadline: date(2026, 10, 13))
        #expect(p.isOverdue)
        #expect(p.pace == .overdue)
        #expect(p.requiredPerPeriod(.weekly) == nil)
    }

    @Test(arguments: [
        (4_000_000, GoalPace.behind),
        (5_500_000, GoalPace.onTrack),
        (7_000_000, GoalPace.ahead),
    ])
    func paceComparesAgainstEvenSchedule(saved: Int, expected: GoalPace) {
        // Setengah jalan dari setahun → idealnya ± 6 jt terkumpul; toleransi 5% = 600 rb.
        let p = plan(target: 12_000_000, saved: saved, start: date(2026, 1, 1), deadline: date(2027, 1, 1), now: date(2026, 7, 2))
        #expect(p.pace == expected)
    }

    @Test func goalWithoutDeadline() {
        let p = plan(target: 10_000_000, saved: 0, deadline: nil)
        #expect(p.pace == .noDeadline)
        #expect(p.periodsLeft(.monthly) == nil)
        #expect(p.monthsToReach(saving: 3_000_000) == 4)
        #expect(p.monthsToReach(saving: 0) == nil)
        #expect(p.projectedDate(saving: 3_000_000) == date(2027, 2, 14))
    }
}
