import Foundation

/// Kalender tetap (Gregorian, WIB) supaya tes tidak bergantung setelan perangkat.
let wib: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!
    return calendar
}()

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0) -> Date {
    wib.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}
