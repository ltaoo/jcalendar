import 'package:flutter/foundation.dart';

import 'package:animate_do/animate_do.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'package:jcalendar/biz/calendar.dart';
import 'package:jcalendar/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Util.isWindows()) {
    await windowManager.ensureInitialized();
    // await WindowManagerPlus.ensureInitialized(args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0);
    const size = Size(1228, 890);
    WindowOptions windowOptions = const WindowOptions(
      size: size,
      center: true,
      // backgroundColor: Colors.transparent,
      skipTaskbar: false,
      // titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      windowManager.setMaximizable(false);
      windowManager.setResizable(false);
    });
  }
  runApp(const Application());
}

class NoScrollbar extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // 返回子widget而不显示滚动条
  }
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      // title: '简日历',
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(scaffoldBackgroundColor: Colors.grey[10], brightness: Brightness.light),
      scrollBehavior: NoScrollbar(),
      // color: Colors.grey[100],
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;
  bool _mounted = false;
  double _initialY = 0.0;
  double _curY = 0.0;
  double itemHeight = 320.0;

  final ScrollController _scrollController = ScrollController();
  late CalendarStore calendar;

  @override
  void initState() {
    super.initState();
    if (Util.isWeb()) {
      BrowserContextMenu.disableContextMenu();
    }
    calendar = CalendarStore(date: DateTime.now());
    calendar.onRefresh((_) {
      setState(() {
        _counter++;
      });
    });
    calendar.onMonthCountChange((_) {
      double offset = _curY + 3 * itemHeight;
      _scrollController.jumpTo(offset);
      // _scrollController.animateTo(
      //   offset,
      //   duration: Duration(milliseconds: 300),
      //   curve: Curves.easeInOut,
      // );
    });
    calendar.onMonthChange((_) {
      if (kDebugMode) {
        print("calendar.onMonthChange");
      }
      int index = calendar.curMonthIndex;
      if (index != -1) {
        if (calendar.months.length - index < 2) {
          return;
        }
        _scrollToIndex(index);
      }
    });
    calendar.onScrollToToday((_) {
      _scrollToCurMonth();
    });
    Future.delayed(Duration(seconds: 1), () {
      _scrollToCurMonth();
      _mounted = true;
    });
  }

  void _scrollToCurMonth() {
    int index = calendar.fetchTodayMonthIndex();
    if (index != -1) {
      double offset = index * itemHeight;
      _initialY = offset;
      _scrollToIndex(index);
    }
  }

  void _scrollToIndex(int index) {
    double offset = index * itemHeight;
    // _scrollController.animateTo(offset, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
    // _scrollController.jumpTo(offset);
    _scrollToY(offset);
  }

  void _scrollToY(double offset) {
    _scrollController.animateTo(offset, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  Widget buildSubCalendarView(CalendarMonth month) {
    return SizedBox(
        height: 320,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(month.monthText, style: TextStyle(color: month.isSelected ? Colors.blue.darkest : Colors.grey[120], fontSize: 24)),
            ),
            const SizedBox(
              height: 16,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: month.weekdays.map((day) => Text(day.text, style: TextStyle(color: Colors.grey[80]))).toList(),
            ),
            const SizedBox(
              height: 12,
            ),
            Expanded(
                child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: month.dates.length,
              itemBuilder: (context, index) {
                final date = month.dates[index];
                if (date.isHidden) {
                  return const MouseRegion();
                }
                FlyoutController controller = FlyoutController();
                final contextAttachKey = GlobalKey();
                return MouseRegion(
                  // cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      calendar.clickDate(date, true);
                    },
                    onSecondaryTapUp: (d) {
                      final targetContext = contextAttachKey.currentContext;
                      if (targetContext == null) {
                        return;
                      }
                      final box = targetContext.findRenderObject() as RenderBox;
                      final pp = box.localToGlobal(Offset.zero);
                      final x = pp.dx + box.size.width;
                      final y = pp.dy;
                      // int totalDays = calendar.calculateTotalDays(calendar.curDate, date);
                      List<int> days1 = calendar.calculateWorkingDays(calendar.curDate, date);
                      List<int> days2 = calendar.today == calendar.curDate ? [] : calendar.calculateWorkingDays(calendar.today, date);
                      controller.showFlyout(
                        barrierColor: Colors.black.withOpacity(0.1),
                        position: Offset(x, y),
                        builder: (context) {
                          return FlyoutContent(
                            child: Container(
                              width: 360.0,
                              height: 240,
                              padding: EdgeInsets.all(12),
                              child: Column(
                                // mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${date.text}',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  Text(
                                    '${date.lunarText}  ${date.festival}',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 12),
                                  Divider(),
                                  SizedBox(height: 12),
                                  Text("${calendar.curDate.text} 到该天还有 ${days1[1]} 天，${days1[0]} 个工作日"),
                                  SizedBox(height: 4),
                                  days2.isEmpty ? Container() : Text("今天到该天还有 ${days2[1]} 天，${days2[0]} 个工作日")
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: FlyoutTarget(
                        key: contextAttachKey,
                        controller: controller,
                        child: Container(
                          decoration: BoxDecoration(
                            // border: Border.all(color: Colors.black, width: 0.5),
                            color: (() {
                              if (date.isHover) {
                                return Colors.grey[30];
                              }
                              return Colors.grey[10];
                            })(),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              date.isSelected
                                  ? Positioned(child: Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16))))
                                  : Positioned(child: Container()),
                              Align(
                                child: Text(
                                  (() {
                                    if (date.isSelected) {
                                      return date.day;
                                    }
                                    if (date.festival == "除夕") {
                                      return date.festival;
                                    }
                                    return date.day;
                                  })(),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: (() {
                                        if (date.isSelected) {
                                          return Colors.white;
                                        }
                                        if (date.festival == "除夕") {
                                          return Colors.red;
                                        }
                                        if (date.isHighlight) {
                                          return Colors.blue;
                                        }
                                        // if (areDateEqual(date.date, calendar.curDate.date)) {
                                        //   return Colors.blue.darkest;
                                        // }
                                        if (date.isHidden) {
                                          return Colors.grey[10];
                                        }
                                        return Colors.grey[120];
                                      })()),
                                ),
                              ),
                              (() {
                                if (date.isHidden) {
                                  return Positioned(child: Container());
                                }
                                if (date.restType == CalendarDateRestType.holidayRest) {
                                  return Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(color: Colors.green.light, borderRadius: BorderRadius.circular(12)),
                                      ));
                                }
                                if (date.restType == CalendarDateRestType.holidayWork) {
                                  return Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(color: Colors.red.light, borderRadius: BorderRadius.circular(12)),
                                      ));
                                }
                                return Positioned(child: Container());
                              })(),
                            ],
                          ),
                        )),
                  ),
                  onEnter: (_) {
                    calendar.setDateHover(date, true);
                  },
                  onExit: (_) {
                    calendar.setDateHover(date, false);
                  },
                  onHover: (_) {},
                );
              },
            )),
          ],
        ));
  }

  Widget buildMainCalendarView() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey[20])], borderRadius: const BorderRadius.all(Radius.circular(24))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: calendar.curMonth.weekdays
                  .map((day) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            Text("星期${day.text}", style: const TextStyle()),
                            calendar.curDate.weekday == day.num
                                ? Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(color: Colors.blue),
                                    ))
                                : Positioned(child: Container()),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            Expanded(
                // decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.5)),
                child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 16 / 14),
              itemCount: calendar.dates.length,
              itemBuilder: (context, index) {
                final date = calendar.dates[index];
                return MouseRegion(
                  // cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      calendar.clickDate(date, false);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              // border: Border.all(color: Colors.black, width: 0.5),
                              color: (() {
                            if (date.isSelected) {
                              if (date.isHover) {
                                return Colors.blue.darkest;
                              }
                              return Colors.blue;
                            }
                            if (date.isHighlight) {
                              return Colors.blue.lightest;
                            }
                            // if (date.day == calendar.curDate.day) {
                            //   return Colors.blue;
                            // }
                            if (date.isHover) {
                              return Colors.grey[30];
                            }
                            if (date.month != calendar.curMonth.month) {
                              // if (date.isHidden) {
                              return Colors.grey[20];
                            }
                            return Colors.white;
                          })()),
                          // borderRadius: BorderRadius.all(Radius.zero),
                          // color: (() {
                          //   if (date.highlight) {
                          //     return material.Colors.blue;
                          //   }
                          //   if (date.hover) {
                          //     return material.Colors.blue[100];
                          //   }
                          //   if (date.isRest) {
                          //     return material.Colors.red[100];
                          //   }
                          //   return null;
                          // })(),
                          child: Center(
                              child: Column(children: [
                            Text(
                              (() {
                                if (date.isSelected && date.month != calendar.curMonth.month) {
                                  return '${date.month}/${date.day}';
                                }
                                return date.day;
                              })(),
                              style: TextStyle(
                                  fontSize: 36,
                                  color: (() {
                                    if (date.isSelected) {
                                      return Colors.white;
                                    }
                                    if (date.isHighlight) {
                                      return Colors.white;
                                    }
                                    // if (date.day == calendar.curDate.day) {
                                    //   return Colors.white;
                                    // }
                                    if (date.month != calendar.curMonth.month) {
                                      // if (date.isHidden) {
                                      return Colors.grey[100];
                                    }
                                    return Colors.grey[160];
                                  })()),
                            ),
                            Text(
                              date.lunarDay,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: (() {
                                    if (date.isSelected) {
                                      return Colors.white;
                                    }
                                    if (date.isHighlight) {
                                      return Colors.white;
                                    }
                                    // if (date.day == calendar.curDate.day) {
                                    //   return Colors.white;
                                    // }
                                    if (date.month != calendar.curMonth.month) {
                                      // if (date.isHidden) {
                                      return Colors.grey[100];
                                    }
                                    return Colors.grey[160];
                                  })()),
                            ),
                            Text(
                              date.festival,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: (() {
                                    if (date.isSelected) {
                                      return Colors.white;
                                    }
                                    if (date.isHighlight) {
                                      return Colors.white;
                                    }
                                    // if (date.day == calendar.curDate.day) {
                                    //   return Colors.white;
                                    // }
                                    // if (date.isHidden) {
                                    if (date.month != calendar.curMonth.month) {
                                      return Colors.grey[100];
                                    }
                                    return Colors.grey[160];
                                  })()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            date.festival == "除夕"
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                          child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                      ))
                                    ],
                                  )
                                : Container()
                          ])),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Text(
                            date.restText,
                            style: TextStyle(color: (() {
                              if (date.isSelected) {
                                return Colors.white;
                              }
                              if (date.isHighlight) {
                                return Colors.white;
                              }
                              if (date.restType == CalendarDateRestType.holidayRest) {
                                return Colors.green.light;
                              }
                              if (date.restType == CalendarDateRestType.holidayWork) {
                                return Colors.red.light;
                              }
                              if (date.month != calendar.curMonth.month) {
                                return Colors.grey[100];
                              }
                              return Colors.grey[160];
                            })()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onEnter: (_) {
                    calendar.setDateHover(date, true);
                  },
                  onExit: (_) {
                    calendar.setDateHover(date, false);
                  },
                );
              },
            )),
          ],
        ));
  }

  Widget buildContent() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Stack(
            children: [
              NotificationListener(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_mounted) {
                      return true;
                    }
                    if (scrollInfo.metrics.atEdge && scrollInfo.metrics.pixels == 0) {
                      _curY = scrollInfo.metrics.pixels;
                      calendar.shiftMonths();
                    }
                    if (scrollInfo.metrics.atEdge && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      _curY = scrollInfo.metrics.pixels;
                      calendar.appendMonths();
                    }
                    return true;
                  },
                  child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      controller: _scrollController,
                      itemCount: calendar.months.length,
                      itemBuilder: (context, index) {
                        return buildSubCalendarView(calendar.months[index]);
                      })),
              Positioned(
                bottom: 8,
                right: 8,
                child: FadeInRight(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[10],
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Tooltip(
                      message: '回到当前月',
                      displayHorizontally: true,
                      useMousePosition: false,
                      style: const TooltipThemeData(preferBelow: true),
                      child: IconButton(
                        icon: Icon(
                          FluentIcons.calendar_reply,
                          color: Colors.grey[80],
                          size: 24.0,
                        ),
                        onPressed: () {
                          // calendar.showToday();
                          calendar.scrollToToday();
                          // _scrollToCurMonth();
                        },
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              // decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[20]))),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      children: [
                        Row(children: [
                          Text(calendar.curMonth.monthText, style: TextStyle(color: Colors.blue.darkest, fontSize: 48)),
                          const SizedBox(width: 12),
                          Tooltip(
                            message: '上个月',
                            displayHorizontally: true,
                            useMousePosition: false,
                            style: const TooltipThemeData(preferBelow: true),
                            child: IconButton(
                              icon: const Icon(
                                FluentIcons.up,
                                size: 36.0,
                              ),
                              onPressed: () {
                                calendar.gotoPrevMonth();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: '下个月',
                            displayHorizontally: true,
                            useMousePosition: false,
                            style: const TooltipThemeData(preferBelow: true),
                            child: IconButton(
                              icon: const Icon(
                                FluentIcons.down,
                                size: 36.0,
                              ),
                              onPressed: () {
                                calendar.gotoNextMonth();
                              },
                            ),
                          ),
                          const SizedBox(width: 48),
                          Tooltip(
                            message: '今天 ${calendar.today.text}',
                            displayHorizontally: true,
                            useMousePosition: false,
                            style: const TooltipThemeData(preferBelow: true),
                            child: IconButton(
                              icon: const Icon(
                                FluentIcons.goto_today,
                                size: 36.0,
                              ),
                              onPressed: () {
                                calendar.setToday(DateTime.now());
                                calendar.showToday();
                              },
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                Expanded(child: buildMainCalendarView()),
              ]),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        padding: const EdgeInsets.only(bottom: 24),
        content: (() {
          if (Util.isWeb()) {
            return Center(
                child: Container(
              width: 1080,
              height: 786,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[80]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: buildContent(),
            ));
          }
          return buildContent();
        })());
  }
}
