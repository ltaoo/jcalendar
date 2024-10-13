import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:jcalendar/biz/mitt.dart';
import 'package:lunar/calendar/Lunar.dart';
import 'package:lunar/calendar/Solar.dart';
import 'package:lunar/calendar/util/HolidayUtil.dart';

DateFormat dateFormat = DateFormat('yyyy/MM/dd');
DateFormat monthFormat = DateFormat('yyyy年MM月');

bool areDateEqual(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}

bool areMonthEqual(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month;
}

enum CalendarDateRestType {
  holidayRest,
  holidayWork,
  normalRest,
  normalWork,
}

class CalendarDate {
  /// 日期
  DateTime date;
  // 农历
  Lunar lunar;
  // 公历
  Solar solar;
  // 当天
  bool isHighlight;
  // 选中
  bool isSelected;
  // 悬浮
  bool isHover = false;
  // 非当月
  bool isHidden;

  int get year => date.year;
  int get month => date.month;
  String get day => date.day.toString();
  String get lunarText => '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  String get lunarDay {
    if (lunar.getDay() == 1) {
      return '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    }
    return lunar.getDayInChinese();
  }

  int get weekday => date.weekday;
  String get text => dateFormat.format(date);

  /// 休息日
  bool get isRest {
    if (restType == CalendarDateRestType.holidayRest) {
      return true;
    }
    if (restType == CalendarDateRestType.normalRest) {
      return true;
    }
    return false;
  }

  CalendarDateRestType get restType {
    final holiday = HolidayUtil.getHolidayByYmd(date.year, date.month, date.day);
    if (holiday != null) {
      final rest = !holiday.isWork();
      if (rest) {
        // 节假日休息
        return CalendarDateRestType.holidayRest;
      }
      // 节假日调休
      return CalendarDateRestType.holidayWork;
    }
    if (date.weekday == 6) {
      return CalendarDateRestType.normalRest;
    }
    if (date.weekday == 7) {
      return CalendarDateRestType.normalRest;
    }
    return CalendarDateRestType.normalWork;
  }

  String get restText {
    if (restType == CalendarDateRestType.holidayWork) {
      return '班';
    }
    if (restType == CalendarDateRestType.holidayRest) {
      return '休';
    }
    return '';
  }

  /// 节假日
  bool get isHoliday {
    final holiday = HolidayUtil.getHolidayByYmd(date.year, date.month, date.day);
    return holiday != null;
  }

  /// 节假日+节气
  String get festival {
    final v = lunar.getFestivals();
    if (v.isNotEmpty) {
      return v[0];
    }
    final v2 = solar.getFestivals();
    if (v2.isNotEmpty) {
      return v2[0];
    }
    final v4 = lunar.getJieQi();
    if (v4.isNotEmpty) {
      return v4;
    }
    // final v5 = solar.getOtherFestivals();
    // if (v5.isNotEmpty) {
    //   return v5[0];
    // }
    return "";
  }

  CalendarDate({required this.date, bool? highlight, bool? selected, bool? hidden, bool? hover})
      : isHighlight = highlight ?? false,
        isSelected = highlight ?? selected ?? false,
        isHover = hover ?? false,
        isHidden = hidden ?? false,
        lunar = Lunar.fromDate(date),
        solar = Solar.fromDate(date);

  setHover(bool v) {
    isHover = v;
  }

  setHighlight(bool v) {
    isHighlight = v;
  }

  setSelected(bool v) {
    isSelected = v;
  }

  click() {}
}

class FetchSpecialMonthDatesParam {
  FetchSpecialMonthDatesParam({required this.highlight});

  bool highlight;
}

class CalendarWeek {
  CalendarWeek({required this.text, required this.num});

  String text;
  int num;
}

class CalendarMonth {
  final bus = EventEmitter();

  List<CalendarWeek> weekdays = [
    CalendarWeek(text: '一', num: 1),
    CalendarWeek(text: '二', num: 2),
    CalendarWeek(text: '三', num: 3),
    CalendarWeek(text: '四', num: 4),
    CalendarWeek(text: '五', num: 5),
    CalendarWeek(text: '六', num: 6),
    CalendarWeek(text: '日', num: 7),
  ];

  /// 选中的日期
  // late DateTime curDay;
  // late CalendarDate cur;
  // late DateTime curMonth;

  int year;
  int month;
  String get unique => '$year/$month';

  /// 当前展示的所有日期
  List<CalendarDate> dates = [];
  List<CalendarDate> get validDates => dates.where((date) => !date.isHidden).toList();

  /// 是否隐藏非当月的日期
  bool hideDatesNotCurMonth = false;

  bool isHighlight;
  bool isSelected;
  bool isHover;

  String get monthText => monthFormat.format(DateTime(year, month, 1));

  CalendarMonth({required this.year, required this.month, required this.dates, bool? highlight, bool? selected, bool? hidden, bool? hover})
      : isHighlight = highlight ?? false,
        isSelected = selected ?? false,
        isHover = hover ?? false;

  setHover(bool v) {
    isHover = v;
    // date.setHover(v);
    // bus.emit("refresh", {});
  }

  // click(CalendarDate date) {
  //   cur.setHighlight(false);
  //   cur = date;
  //   cur.setHighlight(true);
  //   bus.emit("refresh", {});
  // }

  // setDate(DateTime date) {
  //   dates = CalendarStore.fetchSpecialMonthDates(date);
  //   var matched = dates.singleWhere((d) => d.highlight, orElse: () => CalendarDate(date: date));
  //   cur = matched;
  //   if (kDebugMode) {
  //     print(cur.day);
  //   }
  //   bus.emit("refresh", {});
  // }
}

class CalendarStore {
  static List<CalendarDate> fetchSpecialMonthDates(DateTime date, [FetchSpecialMonthDatesParam? opt]) {
    opt ??= FetchSpecialMonthDatesParam(highlight: false);

    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    final weekdayOfFirstDay = firstDayOfMonth.weekday;
    final List<CalendarDate> dates = [];
    for (int i = 1; i < weekdayOfFirstDay; i++) {
      DateTime d = firstDayOfMonth.subtract(Duration(days: weekdayOfFirstDay - i));
      CalendarDate v = CalendarDate(date: d, hidden: true);
      dates.add(v);
    }
    // 从当月的第一天开始，到当月的最后一天，就是当月的所有日期
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      DateTime d = DateTime(date.year, date.month, i);
      CalendarDate v = CalendarDate(date: d, highlight: opt.highlight ? i == date.day : false);
      dates.add(v);
    }
    // 假设 lastDayOfMonth.weekday 是 1 表示周一，那么就还要补 7-1=6 天
    for (int i = 0; i < 7 - lastDayOfMonth.weekday; i++) {
      DateTime d = lastDayOfMonth.add(Duration(days: i + 1));
      CalendarDate v = CalendarDate(date: d, hidden: true);
      dates.add(v);
    }
    // if (kDebugMode) {
    //   print("check need append more days ${dates.length}");
    // }
    if (dates.length == 7 * 5) {
      // 一页日历最多会有 6 周，如果只有 5 周，就再补一周
      final lastDay = dates[dates.length - 1];
      for (int i = 0; i < 7; i++) {
        DateTime d = lastDay.date.add(Duration(days: i + 1));
        CalendarDate v = CalendarDate(date: d, hidden: true);
        dates.add(v);
      }
    }
    return dates;
  }

  static List<CalendarMonth> fetchSpecialMonths(DateTime date) {
    final List<CalendarMonth> months = [];
    for (int i = 1; i < 13; i++) {
      bool isCurMonth = date.month == i;
      DateTime d = DateTime(date.year, i, isCurMonth ? date.day : 1);
      final List<CalendarDate> dates = fetchSpecialMonthDates(d, FetchSpecialMonthDatesParam(highlight: isCurMonth));
      final v = CalendarMonth(year: date.year, month: i, dates: dates, highlight: isCurMonth);
      months.add(v);
    }
    return months;
  }

  static List<CalendarMonth> fetchMonthsPrevAndNext(DateTime date, int count) {
    final List<CalendarMonth> months = [];
    for (int i = 3; i > 0; i--) {
      bool isCurMonth = false;
      DateTime d1 = DateTime(date.year, date.month - i, 1);
      final List<CalendarDate> dates1 = fetchSpecialMonthDates(d1, FetchSpecialMonthDatesParam(highlight: isCurMonth));
      final v1 = CalendarMonth(year: d1.year, month: d1.month, dates: dates1, highlight: isCurMonth);
      months.add(v1);
    }
    {
      bool isCurMonth = true;
      DateTime d = DateTime(date.year, date.month, date.day);
      final List<CalendarDate> dates = fetchSpecialMonthDates(d, FetchSpecialMonthDatesParam(highlight: isCurMonth));
      final v = CalendarMonth(year: d.year, month: d.month, dates: dates, highlight: isCurMonth);
      months.add(v);
    }
    for (int i = 1; i <= 3; i++) {
      bool isCurMonth = false;
      DateTime d2 = DateTime(date.year, date.month + i, 1);
      final List<CalendarDate> dates2 = fetchSpecialMonthDates(d2, FetchSpecialMonthDatesParam(highlight: isCurMonth));
      final v2 = CalendarMonth(year: d2.year, month: d2.month, dates: dates2, highlight: isCurMonth);
      months.add(v2);
    }
    return months;
  }

  List<CalendarDate> pickDatesOfMonth(int yearNum, int monthNum, List<CalendarMonth> months) {
    CalendarMonth matched = months.singleWhere((m) => m.year == yearNum && m.month == monthNum, orElse: () => CalendarMonth(year: 0, month: 0, dates: []));
    if (matched.year == 0) {
      return [];
    }
    int index = months.indexOf(matched);
    CalendarMonth prevMonth = months.elementAt(index - 1);
    CalendarMonth nextMonth = months.elementAt(index + 1);

    List<CalendarDate> validDates = matched.dates.where((d) => !d.isHidden).toList();
    final firstDayOfMonth = validDates.first;
    final lastDayOfMonth = validDates.last;
    final weekdayOfFirstDay = firstDayOfMonth.weekday;
    final List<CalendarDate> dates = [];
    if (kDebugMode) {
      print("before add days of prev month $weekdayOfFirstDay ${dateFormat.format(firstDayOfMonth.date)}");
    }
    for (int i = 1; i < weekdayOfFirstDay; i++) {
      DateTime d = firstDayOfMonth.date.subtract(Duration(days: weekdayOfFirstDay - i));
      if (kDebugMode) {
        print("$i - ${prevMonth.dates.length}");
      }
      if (prevMonth.dates.isNotEmpty) {
        CalendarDate v = prevMonth.dates.where((dd) => !dd.isHidden).singleWhere((dd) => dd.date.day == d.day, orElse: () => CalendarDate(date: d, hidden: true));
        dates.add(v);
      }
    }
    if (kDebugMode) {
      print("add cur month");
    }
    dates.addAll(validDates);
    if (kDebugMode) {
      print("before add days of next month ${lastDayOfMonth.weekday}  ${dateFormat.format(lastDayOfMonth.date)}");
    }
    for (int i = 0; i < 7 - lastDayOfMonth.weekday; i++) {
      DateTime d = lastDayOfMonth.date.add(Duration(days: i + 1));
      if (nextMonth.dates.isNotEmpty) {
        CalendarDate v = nextMonth.dates.where((dd) => !dd.isHidden).singleWhere((dd) => dd.date.day == d.day, orElse: () => CalendarDate(date: d, hidden: true));
        if (kDebugMode) {
          print("add days of next month");
        }
        dates.add(v);
      }
    }
    if (dates.length == 7 * 5) {
      final lastDay = dates[dates.length - 1];
      if (kDebugMode) {
        print("append extra dates");
      }
      for (int i = 0; i < 7; i++) {
        DateTime d = lastDay.date.add(Duration(days: i + 1));
        if (nextMonth.dates.isNotEmpty) {
          CalendarDate v = nextMonth.dates.where((dd) => !dd.isHidden).singleWhere((dd) => dd.date.day == d.day, orElse: () => CalendarDate(date: d, hidden: true));
          dates.add(v);
        }
      }
    }
    return dates;
  }

  final bus = EventEmitter();

  CalendarStore({required DateTime date}) {
    months = fetchMonthsPrevAndNext(date, 3);
    curMonth = months.singleWhere((d) => d.isHighlight, orElse: () => CalendarMonth(year: date.year, month: date.month, dates: []));
    dates = pickDatesOfMonth(curMonth.year, curMonth.month, months);
    curDate = dates.singleWhere((d) => d.isHighlight, orElse: () => CalendarDate(date: date));
    today = curDate;
    title = monthFormat.format(curDate.date);
  }

  String title = "";
  List<CalendarMonth> months = [];
  List<CalendarDate> dates = [];
  late CalendarDate today;
  late CalendarMonth curMonth;
  late CalendarDate curDate;
  int get curMonthIndex => months.indexWhere((m) => m.unique == curMonth.unique);
  bool pending = false;

  shiftMonths() {
    if (pending) {
      return;
    }
    pending = true;
    CalendarMonth firstMonth = months.elementAt(0);
    List<CalendarMonth> newMonths = [];
    for (int i = 5; i > 0; i--) {
      bool isCurMonth = false;
      DateTime d1 = DateTime(firstMonth.year, firstMonth.month - i, 1);
      final List<CalendarDate> dates1 = fetchSpecialMonthDates(d1, FetchSpecialMonthDatesParam(highlight: isCurMonth));
      final v1 = CalendarMonth(year: d1.year, month: d1.month, dates: dates1, highlight: isCurMonth);
      newMonths.add(v1);
    }
    months = [...newMonths, ...months];
    if (kDebugMode) {
      print("shift months ${months.length}");
    }
    bus.emit("refresh-months", {});
    Future.delayed(Duration(seconds: 1), () {
      pending = false;
    });
  }

  appendMonths() {
    if (pending) {
      return;
    }
    pending = true;
    CalendarMonth lastMonth = months.last;
    List<CalendarMonth> newMonths = [];
    for (int i = 1; i <= 5; i++) {
      bool isCurMonth = false;
      DateTime d2 = DateTime(lastMonth.year, lastMonth.month + i, 1);
      final List<CalendarDate> dates2 = fetchSpecialMonthDates(d2, FetchSpecialMonthDatesParam(highlight: isCurMonth));
      final v2 = CalendarMonth(year: d2.year, month: d2.month, dates: dates2, highlight: isCurMonth);
      newMonths.add(v2);
    }
    months = [...months, ...newMonths];
    if (kDebugMode) {
      print("append months ${months.length}");
    }
    bus.emit("refresh", {});

    Future.delayed(Duration(seconds: 1), () {
      pending = false;
    });
  }

  gotoPrevMonth() {
    int curMonthNum = curMonth.month;
    int prevMonthNum = curMonthNum - 1;
    int index = months.indexOf(curMonth);
    if (index <= 3) {
      shiftMonths();
    }
    DateTime prev = DateTime(curMonth.year, prevMonthNum, 1);
    if (kDebugMode) {
      print("gotoPrevMonth - $prevMonthNum");
    }
    if (months.isEmpty) {
      return;
    }
    curMonth = months.singleWhere((m) => m.year == prev.year && m.month == prev.month, orElse: () => CalendarMonth(year: prev.year, month: prev.month, dates: []));
    if (curMonth.dates.isEmpty) {
      return;
    }
    dates = pickDatesOfMonth(curMonth.year, curMonth.month, months);
    if (kDebugMode) {
      print("before curMonth.dates.singleWhere - ${curMonth.dates.length}");
    }
    // curDate = curMonth.dates.singleWhere((d) => d.day == curDate.day, orElse: () => CalendarDate(date: curDate.date));
    bus.emit("refresh", {});
    bus.emit("change-month", {});
  }

  gotoNextMonth() {
    int curMonthNum = curMonth.month;
    int nextMonthNum = curMonthNum + 1;
    int index = months.indexOf(curMonth);
    if (months.length - index <= 3) {
      appendMonths();
    }
    DateTime next = DateTime(curMonth.year, nextMonthNum, 1);
    if (kDebugMode) {
      print("gotoNextMonth - $nextMonthNum");
    }
    if (months.isEmpty) {
      return;
    }
    curMonth = months.singleWhere((m) => m.year == next.year && m.month == next.month, orElse: () => CalendarMonth(year: next.year, month: next.month, dates: []));
    if (curMonth.dates.isEmpty) {
      return;
    }
    dates = pickDatesOfMonth(curMonth.year, curMonth.month, months);
    if (kDebugMode) {
      print("before curMonth.dates.singleWhere - ${curMonth.dates.length}");
    }
    // curDate = curMonth.dates.singleWhere((d) => d.day == curDate.day, orElse: () => CalendarDate(date: curDate.date));
    bus.emit("refresh", {});
    bus.emit("change-month", {});
  }

  setDate(DateTime date) {
    if (areDateEqual(date, curDate.date)) {
      return;
    }
    if (areMonthEqual(date, curDate.date)) {
      curDate.setHighlight(false);
      curDate.setSelected(false);
      curDate = curMonth.dates.singleWhere((d) => d.date.day == date.day, orElse: () => CalendarDate(date: curDate.date));
      curDate.setHighlight(true);
      curDate.setSelected(true);
      bus.emit("refresh", {});
      return;
    }
    curMonth = months.singleWhere((m) => m.month == date.month, orElse: () => CalendarMonth(year: date.year, month: date.month, dates: []));
    curDate.setHighlight(false);
    curDate.setSelected(false);
    curDate = curMonth.dates.singleWhere((d) => d.date.day == date.day, orElse: () => CalendarDate(date: date));
    curDate.setHighlight(true);
    curDate.setSelected(true);
    bus.emit("refresh", {});
  }

  void setCurMonth() {}

  setDateHover(CalendarDate date, bool hover) {
    date.setHover(hover);
    bus.emit("refresh", {});
  }

  setToday(DateTime t) {
    if (areDateEqual(t, today.date)) {
      return;
    }
    CalendarMonth matched = months.singleWhere((m) => m.year == t.year && m.month == t.month, orElse: () => CalendarMonth(year: t.year, month: t.month, dates: []));
    CalendarDate matched2 = matched.dates.singleWhere((d) => d.date.day == t.day, orElse: () => CalendarDate(date: t));
    matched2.setHighlight(true);
    today = matched2;
  }

  clickDate(CalendarDate date, bool needChangeMonth) {
    curDate.setSelected(false);
    if (kDebugMode) {
      print("[BIZ]clickDate");
    }
    bool isSameMonth = curMonth.year == date.year && curMonth.month == date.month;
    if (kDebugMode) {
      print("[BIZ]clickDate - isSameMonth? $isSameMonth / needChangeMonth $needChangeMonth");
    }
    if (!isSameMonth && needChangeMonth == true) {
      curMonth = months.singleWhere((m) => m.year == date.year && m.month == date.month, orElse: () => CalendarMonth(year: date.year, month: date.month, dates: []));
      if (curMonth.dates.isEmpty) {
        if (kDebugMode) {
          print("[BIZ]clickDate error1");
        }
        return;
      }
      if (kDebugMode) {
        print("[BIZ]clickDate update dates");
      }
      dates = pickDatesOfMonth(curMonth.year, curMonth.month, months);
    }
    curDate = date;
    curDate.setSelected(true);
    bus.emit("refresh", {});
  }

  fetchTodayMonthIndex() {
    int index = months.indexWhere((m) => m.year == today.year && m.month == today.month);
    return index;
  }

  showToday() {
    clickDate(today, true);
    scrollToToday();
  }

  scrollToToday() {
    bus.emit("scroll-to-today", {});
  }

  fetchNextMonth(CalendarMonth m) {
    int index = months.indexOf(m);
    int nextIndex = index + 1;
    // if (nextIndex >= months.length) {

    // }
    return months[nextIndex];
  }

  fetchNextDay(CalendarDate day) {
    CalendarMonth matched = months.singleWhere((m) => m.year == day.year && m.month == day.month, orElse: () => CalendarMonth(year: day.year, month: day.month, dates: []));
    List<CalendarDate> validDates = matched.dates.where((dd) => !dd.isHidden).toList();
    int index = validDates.indexOf(day);
    int nextIndex = index + 1;
    if (nextIndex >= validDates.length) {
      matched = fetchNextMonth(matched);
      validDates = matched.dates.where((dd) => !dd.isHidden).toList();
      nextIndex = 0;
    }
    return validDates[nextIndex];
  }

  int calculateTotalDays(CalendarDate start, CalendarDate end) {
    return end.date.difference(start.date).inDays;
  }

  List<int> calculateWorkingDays(CalendarDate start, CalendarDate end) {
    // CalendarMonth startMonth =
    //     months.singleWhere((m) => m.year == start.year && m.month == start.month, orElse: () => CalendarMonth(year: start.year, month: start.month, dates: []));
    // CalendarMonth endMonth = months.singleWhere((m) => m.year == end.year && m.month == end.month, orElse: () => CalendarMonth(year: start.year, month: start.month, dates: []));
    int totalDays = calculateTotalDays(start, end);
    int count = 0;
    int workingDays = 0;

    CalendarDate cur = start;
    while (cur != end && count < totalDays) {
      if (kDebugMode) {
        print("${cur.text} - ${cur.restType}");
      }
      if (cur.restType == CalendarDateRestType.holidayWork || cur.restType == CalendarDateRestType.normalWork) {
        workingDays++;
      }
      count += 1;
      cur = fetchNextDay(cur);
    }
    // for (DateTime date = start.date; date.isBefore(end.date) || date.isAtSameMomentAs(end.date); date = date.add(Duration(days: 1))) {
    // }
    return [workingDays, totalDays];
  }

  refresh() {
    bus.emit("refresh", {});
  }

  onMonthChange(Handler handler) {
    return bus.on('change-month', handler);
  }

  onMonthCountChange(Handler handler) {
    return bus.on('refresh-months', handler);
  }

  onScrollToToday(Handler handler) {
    return bus.on('scroll-to-today', handler);
  }

  onRefresh(Handler handler) {
    return bus.on("refresh", handler);
  }
}
