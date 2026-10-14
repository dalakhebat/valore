import XCTest

/// Membuka tiap layar utama dengan data contoh dan menyimpan screenshot sebagai lampiran hasil tes.
/// Dipakai untuk gambar README; jalankan lewat scheme `Screenshots`.
final class ScreenshotTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["-sampleData"]
        app.launch()
    }

    func testCaptureMainScreens() {
        snap("01-beranda")

        app.buttons["Pengaturan"].tap()
        XCTAssertTrue(app.navigationBars["Pengaturan"].waitForExistence(timeout: 3))
        snap("08-pengaturan")
        app.buttons["Selesai"].tap()

        app.tabBars.buttons["Transaksi"].tap()
        snap("02-transaksi")

        app.tabBars.buttons["Tabungan"].tap()
        snap("03-tabungan")

        // Target yang sama juga tampil di tab Beranda (tersembunyi), jadi ketuk yang terlihat saja.
        tapVisible(app.staticTexts, "Liburan Jepang")
        XCTAssertTrue(app.staticTexts["Rencana"].waitForExistence(timeout: 3) || app.staticTexts["RENCANA"].exists)
        snap("04-detail-target")

        // Tombol setor harus bisa dijangkau (dulu tertutup tab bar).
        app.buttons["Setor / Tarik"].tap()
        XCTAssertTrue(app.buttons["Simpan"].waitForExistence(timeout: 3))
        snap("09-setor")
        app.buttons["Batal"].tap()

        app.tabBars.buttons["Ringkasan"].tap()
        snap("05-ringkasan")
        app.swipeUp()
        snap("06-ringkasan-tren")

        app.tabBars.buttons["Beranda"].tap()
        tapVisible(app.buttons, "Catat transaksi")
        XCTAssertTrue(app.navigationBars["Catat transaksi"].waitForExistence(timeout: 3))
        snap("07-catat-transaksi")
    }

    private func tapVisible(_ query: XCUIElementQuery, _ label: String) {
        let element = query.matching(identifier: label).allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(element, "\(label) tidak terlihat di layar")
        element?.tap()
    }

    private func snap(_ name: String) {
        // Beri waktu animasi transisi selesai.
        Thread.sleep(forTimeInterval: 0.8)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
