import Testing
@testable import Valore

struct BalanceRuleTests {
    @Test func newExpenseWithinBalance() {
        #expect(BalanceRule.isAllowed(current: 400_000, adding: -400_000))
        #expect(!BalanceRule.isAllowed(current: 400_000, adding: -400_001))
    }

    @Test func editingExpenseOnlyCountsTheDifference() {
        // Saldo 100 rb sudah termasuk pengeluaran lama 300 rb; jadi boleh dinaikkan sampai 400 rb.
        #expect(BalanceRule.spendable(current: 100_000, removing: -300_000) == 400_000)
        #expect(BalanceRule.isAllowed(current: 100_000, removing: -300_000, adding: -400_000))
        #expect(!BalanceRule.isAllowed(current: 100_000, removing: -300_000, adding: -400_001))
    }

    @Test func removingIncomeCanBeBlocked() {
        // Saldo 50 rb, di dalamnya ada pemasukan 200 rb: menghapusnya bikin saldo −150 rb.
        #expect(BalanceRule.resultingBalance(current: 50_000, removing: 200_000) == -150_000)
        #expect(!BalanceRule.isAllowed(current: 50_000, removing: 200_000))
    }

    @Test func switchingIncomeToExpense() {
        // Pemasukan 100 rb diubah jadi pengeluaran 100 rb di dompet bersaldo 150 rb.
        #expect(BalanceRule.resultingBalance(current: 150_000, removing: 100_000, adding: -100_000) == -50_000)
    }

    @Test func spendableNeverNegative() {
        #expect(BalanceRule.spendable(current: -20_000) == 0)
    }
}
