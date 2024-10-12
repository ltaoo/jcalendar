import 'package:animate_do/animate_do.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'package:jcalendar/biz/calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  });
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
      // title: '极简日历',
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
    Future.delayed(Duration(seconds: 1), () {
      _scrollToCurMonth();
      _mounted = true;
    });
  }

  void _scrollToCurMonth() {
    int index = calendar.curMonthIndex;
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
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      calendar.clickDate(date);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        // border: Border.all(color: Colors.black, width: 0.5),
                        border: Border.all(color: (() {
                          if (date.isSelected) {
                            if (date.isHover) {
                              return Colors.blue.darkest;
                            }
                            return Colors.blue;
                          }
                          // if (date.day == calendar.curDate.day) {
                          //   return Colors.blue;
                          // }
                          // if (date.isHover) {
                          //   return Colors.blue;
                          // }
                          return Colors.transparent;
                        })()),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                              child: Column(children: [
                            Text(
                              date.day,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: (() {
                                    if (date.isSelected) {
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
                          ])),
                          (() {
                            if (date.isHidden) {
                              return Positioned(child: Container());
                            }
                            if (date.restType == CalendarDateRestType.holidayRest) {
                              return Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(color: Colors.green.light, borderRadius: BorderRadius.circular(12)),
                                  ));
                            }
                            if (date.restType == CalendarDateRestType.holidayWork) {
                              return Positioned(
                                  right: 2,
                                  top: 2,
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

  Widget buildMainCalendarView(CalendarMonth store) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey[20])], borderRadius: const BorderRadius.all(Radius.circular(24))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: store.weekdays
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
              itemCount: store.dates.length,
              itemBuilder: (context, index) {
                final date = store.dates[index];
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      calendar.clickDate(date);
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
                            if (date.isHidden) {
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
                                if (date.isSelected && date.isHidden) {
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
                                    if (date.isHidden) {
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
                                    if (date.isHidden) {
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
                                    if (date.isHidden) {
                                      return Colors.grey[100];
                                    }
                                    return Colors.grey[160];
                                  })()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
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
                              if (date.isHidden) {
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        padding: const EdgeInsets.only(bottom: 24),
        content: Row(
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
                              _scrollToCurMonth();
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
                                message: '今天',
                                displayHorizontally: true,
                                useMousePosition: false,
                                style: const TooltipThemeData(preferBelow: true),
                                child: IconButton(
                                  icon: const Icon(
                                    FluentIcons.goto_today,
                                    size: 36.0,
                                  ),
                                  onPressed: () {
                                    calendar.setDate(DateTime.now());
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
                    Expanded(child: buildMainCalendarView(calendar.curMonth)),
                  ]),
                )),
          ],
        ));
  }
}
