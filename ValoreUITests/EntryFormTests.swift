import XCTest

/// Perilaku form catat transaksi: format nominal & larangan saldo minus.
final class EntryFormTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["-sampleData"]
        app.launch()
        app.buttons["Catat pengeluaran"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["CATAT TRANSAKSI"].waitForExistence(timeout: 3))
    }

    func testAmountIsGroupedWhileTyping() {
        let field = app.textFields["amountField"]
        field.tap()
        field.typeText("1500000")
        XCTAssertEqual(field.value as? String, "1.500.000")
    }

    func testExpenseCannotExceedWalletBalance() {
        // Saldo dompet terpilih dibaca dari layar, karena saldo data contoh ikut tanggal hari ini.
        let info = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Saldo Tunai Rp '")).firstMatch
        XCTAssertTrue(info.waitForExistence(timeout: 3))
        let balanceText = String(info.label.dropFirst("Saldo Tunai ".count))
        let balance = Int(balanceText.filter(\.isNumber)) ?? 0
        XCTAssertGreaterThan(balance, 0)

        let field = app.textFields["amountField"]
        field.tap()
        field.typeText(String(balance + 1_000))
        XCTAssertTrue(app.staticTexts["Saldo Tunai cuma \(balanceText)"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Simpan"].isEnabled)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "10-saldo-kurang"
        shot.lifetime = .keepAlways
        add(shot)

        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 15))
        field.typeText(String(balance))
        XCTAssertTrue(app.buttons["Simpan"].isEnabled)
    }
}
