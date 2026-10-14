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

    func testLongAmountStaysOnOneLine() {
        let field = app.textFields["amountField"]
        let label = app.staticTexts["Rp"].firstMatch
        let window = app.windows.firstMatch
        field.tap()

        for digits in ["50000000", "999999999999"] {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 16))
            field.typeText(digits)
            // "Rp" tetap satu baris dan berada di kiri angka, angka tidak keluar layar.
            XCTAssertLessThan(label.frame.height, 40, "Rp terpecah jadi dua baris untuk \(digits)")
            XCTAssertLessThanOrEqual(label.frame.maxX, field.frame.minX + 1)
            XCTAssertLessThanOrEqual(field.frame.maxX, window.frame.maxX - 20, "Nominal \(digits) keluar dari kartu")
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "11-nominal-panjang"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
