// intl 时间库的使用
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  final df = DateFormat("yyyy/MM/dd");
  group('fetch day', () {
    test('format', () {
      final date = DateTime(2024, 9, 1);
      expect(df.format(date), "2024/09/01");
    });
// 获取指定日期所在月的第一天
    test('the first day of month', () {
      final date = DateTime(2024, 9, 10);
      final first = DateTime(date.year, date.month, 1);
      expect(df.format(first), "2024/09/01");
    });
    // 获取指定日期所在月的最后一天
    test('the last day of month', () {
      final date = DateTime(2024, 9, 10);
      final last = DateTime(date.year, date.month + 1, 0);
      expect(df.format(last), "2024/09/30");
    });
// 最后一天只有 28 天
    test('the last day is 28', () {
      final date = DateTime(2025, 2, 10);
      final last = DateTime(date.year, date.month + 1, 0);
      expect(df.format(last), "2025/02/28");
    });
    // 最后一天只有 29 天
    test('the last day is 29', () {
      final date = DateTime(2024, 2, 10);
      final last = DateTime(date.year, date.month + 1, 0);
      expect(df.format(last), "2024/02/29");
    });
    // 明天在同一月
    test('next date in same month', () {
      final date = DateTime(2024, 9, 12);
      final next = date.add(const Duration(days: 1));

      expect(df.format(next), "2024/09/13");
    });
    // 明天不在同一月
    test('next date in next month', () {
      final date = DateTime(2024, 9, 30);
      final next = date.add(const Duration(days: 1));

      expect(df.format(next), "2024/10/01");
    });
    // 昨天在同一月
    test('prev date in same month', () {
      final date = DateTime(2024, 9, 12);
      final prev = date.subtract(const Duration(days: 1));

      expect(df.format(prev), "2024/09/11");
    });
    // 昨天不在同一月
    test('prev date in prev month', () {
      final date = DateTime(2024, 9, 1);
      final prev = date.subtract(const Duration(days: 1));

      expect(df.format(prev), "2024/08/31");
    });
    // 上个月在同一年
    test('prev month in same year', () {
      final date = DateTime(2024, 9, 12);
      final prev = DateTime(date.year, date.month - 1, date.day);

      expect(df.format(prev), "2024/08/12");
    });
    // 上个月不在同一年
    test('prev month in prev year', () {
      final date = DateTime(2024, 1, 20);
      final prev = DateTime(date.year, date.month - 1, date.day);

      expect(df.format(prev), "2023/12/20");
    });
    // 下个月在同一年
    test('next month in same year', () {
      final date = DateTime(2024, 9, 12);
      final next = DateTime(date.year, date.month + 1, date.day);

      expect(df.format(next), "2024/10/12");
    });
    // 下个月不在同一年
    test('next month in next year', () {
      final date = DateTime(2024, 12, 20);
      final next = DateTime(date.year, date.month + 1, date.day);

      expect(df.format(next), "2025/01/20");
    });

    // 下个月在同一年但没有相同的日期
    test('next month in prev year', () {
      final date = DateTime(2024, 8, 31);
      final next = DateTime(date.year, date.month + 1, date.day);
      // 直接干到 10/01 了，合理。本质上就是按天推
      expect(df.format(next), "2024/10/01");
    });
    // 周一在同一月
    test('monday in same month', () {
      final date = DateTime(2024, 10, 8);
      final monday = date.subtract(Duration(days: date.weekday - DateTime.monday));
      expect(df.format(monday), "2024/10/07");
    });
    // 周一在上一月
    test('monday in prev month', () {
      final date = DateTime(2024, 10, 2);
      final monday = date.subtract(Duration(days: date.weekday - DateTime.monday));
      expect(df.format(monday), "2024/09/30");
    });
    // 获取指定天所在周的 周n
    test('get special weekday in same week', () {
      // 表示获取周五
      int n = 5;
      final date = DateTime(2024, 10, 2);
      final monday = date.subtract(Duration(days: date.weekday - n));
      expect(df.format(monday), "2024/10/04");
    });
  });

  group('fetch month', () {
    // 获取指定日期所在月的第一天
    test('the first day of month', () {
      final date = DateTime(2024, 9, 10);
      final first = DateTime(date.year, date.month - 1, date.day);
      expect(df.format(first), "2024/08/10");
    });
    // 获取指定日期所在月的最后一天
    test('the last day of month', () {
      final date = DateTime(2024, 9, 10);
      final last = DateTime(date.year, date.month + 1, date.day);
      expect(df.format(last), "2024/10/10");
    });

    /// 后一个月只有 28 天
    test('the next month only 28', () {
      final date = DateTime(2025, 1, 29);
      final last = DateTime(date.year, date.month + 1, date.day);
      expect(df.format(last), "2025/03/01");
    });
    // 前一个月只有 28 天
    test('the prev month only 28', () {
      final date = DateTime(2025, 3, 29);
      final last = DateTime(date.year, date.month - 1, date.day);
      expect(df.format(last), "2025/03/01");
    });
    // 上个月是去年
    test('the prev month at prev year', () {
      final date = DateTime(2024, 1, 12);
      final last = DateTime(date.year, date.month - 1, date.day);
      expect(df.format(last), "2023/12/12");
    });
// 下个月是明年
    test('the next month at next year', () {
      final date = DateTime(2024, 12, 12);
      final last = DateTime(date.year, date.month + 1, date.day);
      expect(df.format(last), "2025/01/12");
    });
  });
}
