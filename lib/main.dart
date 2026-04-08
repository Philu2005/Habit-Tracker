import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:habit_tracker/models/habit_item.dart';
import 'package:habit_tracker/data/local_store.dart';
import 'package:habit_tracker/models/category.dart';
import 'package:habit_tracker/screens/categories_page.dart';
import 'package:habit_tracker/ui/icon_registry.dart';
import 'package:habit_tracker/screens/subtasks_sheet.dart';
import 'package:habit_tracker/screens/category_picker_sheet.dart';
import 'package:habit_tracker/models/subtask_model.dart';
import 'package:habit_tracker/screens/subtask_editor_sheet.dart';
import 'package:habit_tracker/screens/settings_page.dart';

enum AppViewMode { day, month }

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.I.init();
  await LocalStore.I.applyDayRollover();
  runApp(const HabitApp());
}

/// =====================================================
///           APP ROOT (THEME + STATE)
/// =====================================================
class HabitApp extends StatefulWidget {
  const HabitApp({super.key});

  @override
  State<HabitApp> createState() => _HabitAppState();
}

class _HabitAppState extends State<HabitApp> {
  bool isDark = LocalStore.I.isDark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker',

      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),

      home: HomePage(
        isDark: isDark,
        onToggleTheme: () {
          setState(() {
            isDark = !isDark;
          });
          LocalStore.I.setTheme(isDark);
        },
      ),
    );
  }
}

class _DateSelectorState extends State<_DateSelector> {
  late ScrollController _controller;

  final double itemWidth = 76;
  bool _isAnimating = false;
  late List<DateTime> dates;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    dates = List.generate(60, (i) {
      return today.subtract(Duration(days: 30 - i));
    });

    _controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(30, animate: false, notify: false);

      Future.delayed(const Duration(milliseconds: 10), () {
        _scrollToIndex(30, animate: false, notify: false);
      });
    });
  }

  void _ensureDateVisible(DateTime date) {
    int idx = _indexOfDate(date);
    if (idx == -1) {
      // Rebaue das Fenster rund um das Ziel-Datum
      final base = DateTime(date.year, date.month, date.day);
      dates = List.generate(60, (i) => base.subtract(Duration(days: 30 - i)));
      idx = 30; // center
    }
    // Zentriere ohne notify (kein erneutes Laden ausloesen)
    _scrollToIndex(idx, animate: false, notify: false);
  }

  @override
  void didUpdateWidget(covariant _DateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = oldWidget.selectedDate;
    final n = widget.selectedDate;
    if (o.year != n.year || o.month != n.month || o.day != n.day) {
      if (_indexOfDate(n) == -1) {
        _ensureDateVisible(n);
      }
    }
  }

  void _scrollToIndex(
    int index, {
    bool animate = true,
    bool notify = true,
    Duration? duration,
  }) {
    final offset = index * itemWidth;
    final animDuration = duration ?? const Duration(milliseconds: 250);

    if (animate) {
      _isAnimating = true;
      _controller
          .animateTo(offset, duration: animDuration, curve: Curves.easeOut)
          .whenComplete(() {
            _isAnimating = false;
            if (!mounted) return;
            if (notify) widget.onChanged(dates[index]);
          });
    } else {
      _controller.jumpTo(offset);
      if (notify) widget.onChanged(dates[index]);
    }
  }

  void _snapToCenter() {
    if (_isAnimating) return;

    int index = (_controller.offset / itemWidth).round();
    index = index.clamp(0, dates.length - 1);

    final targetOffset = index * itemWidth;
    if ((targetOffset - _controller.offset).abs() < 0.5) return;
    _scrollToIndex(index, notify: false);
  }

  void _onTap(int index) {
    _scrollToIndex(index, duration: const Duration(milliseconds: 160));
  }

  int _indexOfDate(DateTime date) {
    return dates.indexWhere(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (_isAnimating) return false;
              if (notification is ScrollEndNotification) {
                _snapToCenter();
              }
              return false;
            },
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),

              padding: EdgeInsets.symmetric(
                horizontal: screenWidth / 2 - itemWidth / 2,
              ),

              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];

                final isSelected =
                    date.year == widget.selectedDate.year &&
                    date.month == widget.selectedDate.month &&
                    date.day == widget.selectedDate.day;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                /// Padding ist bereits in der ListView berücksichtigt,
                /// daher genügt der reine Offset / itemWidth.
                final centerIndex = _controller.hasClients
                    ? (_controller.offset / itemWidth)
                    : 0;

                final distance = (index - centerIndex).abs();

                final scale = (1 - distance * 0.2).clamp(0.8, 1.0);
                final opacity = (1 - distance * 0.3).clamp(0.4, 1.0);

                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: SizedBox(
                        width: itemWidth,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // WEEKDAY
                            Text(
                              [
                                "Mo",
                                "Di",
                                "Mi",
                                "Do",
                                "Fr",
                                "Sa",
                                "So",
                              ][date.weekday - 1],
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Moderne Datumskarte mit Tag + Monat
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 56,
                              height: 60,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF7C7AE6),
                                          Color(0xFFB388FF),
                                        ],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark
                                          ? const Color(0xFF1C1C1E)
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : Colors.black.withOpacity(0.06)),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF7C7AE6,
                                          ).withOpacity(0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Builder(
                                    builder: (_) {
                                      final monthLabel = [
                                        "Jan",
                                        "Feb",
                                        "Mär",
                                        "Apr",
                                        "Mai",
                                        "Jun",
                                        "Jul",
                                        "Aug",
                                        "Sep",
                                        "Okt",
                                        "Nov",
                                        "Dez",
                                      ][date.month - 1];
                                      final d = date.day.toString().padLeft(
                                        2,
                                        '0',
                                      );
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            d,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.white
                                                        : Colors.black),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            monthLabel,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(
                                                      0.95,
                                                    )
                                                  : Colors.grey,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: isToday ? 1 : 0,
                              child: Container(
                                width: 50,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onChanged;

  const _DateSelector({required this.selectedDate, required this.onChanged});

  @override
  State<_DateSelector> createState() => _DateSelectorState();
}

class _MonthSelectorBar extends StatelessWidget {
  final DateTime monthDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _MonthSelectorBar({
    required this.monthDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const months = [
      "Januar",
      "Februar",
      "März",
      "April",
      "Mai",
      "Juni",
      "Juli",
      "August",
      "September",
      "Oktober",
      "November",
      "Dezember",
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: Icon(
                Icons.chevron_left,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Expanded(
              child: Text(
                "${months[monthDate.month - 1]} ${monthDate.year}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            FilledButton.tonal(
              onPressed: onToday,
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
              child: Text(
                "Heute",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  final DateTime monthDate;
  final DateTime selectedDate;
  final Map<int, List<HabitItem>> itemsByDay;
  final List<Category> categories;
  final ValueChanged<DateTime> onSelectDay;

  const _MonthView({
    required this.monthDate,
    required this.selectedDate,
    required this.itemsByDay,
    required this.categories,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
    final first = DateTime(monthDate.year, monthDate.month, 1);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final leading = first.weekday - 1;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final monthCount = itemsByDay.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "$monthCount Aufgaben im Monat",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.hardEdge,
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(monthDate.year, monthDate.month, dayNumber);
              final isSelected =
                  date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final dayItems = itemsByDay[dayNumber] ?? const <HabitItem>[];
              final hasData = dayItems.isNotEmpty;
              final categoryDots = <Color>[];
              for (final item in dayItems) {
                final catId = item.categoryId;
                if (catId == null) continue;
                Category? cat;
                for (final c in categories) {
                  if (c.id == catId) {
                    cat = c;
                    break;
                  }
                }
                if (cat == null) continue;
                final color = Color(cat.color);
                if (!categoryDots.any((d) => d.value == color.value)) {
                  categoryDots.add(color);
                  if (categoryDots.length >= 3) break;
                }
              }

              return GestureDetector(
                onTap: () => onSelectDay(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C7AE6)
                          : (isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.04)),
                    ),
                    color: isSelected
                        ? const Color(
                            0xFF7C7AE6,
                          ).withOpacity(isDark ? 0.22 : 0.16)
                        : (isDark
                              ? const Color(0xFF242428)
                              : const Color(0xFFF3F4F7)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$dayNumber",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!hasData)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            shape: BoxShape.circle,
                          ),
                        )
                      else if (categoryDots.isEmpty)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white70 : Colors.black54,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: categoryDots.map((c) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// =====================================================
///                     HOME PAGE
/// =====================================================
class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Modell siehe: lib/models/habit_item.dart

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late DateTime selectedDate;
  late DateTime today;
  late DateTime selectedMonth;
  late AppViewMode viewMode;

  final LocalStore store = LocalStore.I;
  bool _loading = false;
  Timer? _dayWatcher;
  DateTime? _lastSeenDay;

  List<HabitItem> habits = [];
  List<Category> categories = [];
  Map<int, List<HabitItem>> monthHabitsByDay = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final now = DateTime.now();

    /// WICHTIG: OHNE UHRZEIT
    selectedDate = DateTime(now.year, now.month, now.day);
    today = selectedDate;
    selectedMonth = DateTime(now.year, now.month, 1);
    viewMode = store.viewMode == 'month' ? AppViewMode.month : AppViewMode.day;
    _lastSeenDay = DateTime(now.year, now.month, now.day);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncDayState(force: true);
      await _reloadAll();
    });
    _dayWatcher = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncDayState();
    });
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _syncDayState({bool force = false}) async {
    final todayDate = _todayDate();
    final changed =
        _lastSeenDay == null ||
        _lastSeenDay!.year != todayDate.year ||
        _lastSeenDay!.month != todayDate.month ||
        _lastSeenDay!.day != todayDate.day;
    if (!force && !changed) return;
    _lastSeenDay = todayDate;

    final skipped = await store.applyDayRollover();
    if (!mounted) return;
    await _loadDate(todayDate);
    if (!mounted) return;
    if (skipped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$skipped Aufgaben wurden auf "skip" gesetzt')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncDayState();
    }
  }

  Future<void> _reloadAll() async {
    setState(() => _loading = true);
    try {
      final cats = await store.getCategories();
      final items = await store.getByDate(selectedDate);
      final monthItems = await store.getByMonth(selectedMonth);
      final grouped = <int, List<HabitItem>>{};
      for (final h in monthItems) {
        grouped.putIfAbsent(h.dueDate.day, () => []).add(h);
      }
      if (!mounted) return;
      setState(() {
        categories = cats;
        habits = items;
        monthHabitsByDay = grouped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    setState(() {
      selectedDate = normalized;
      selectedMonth = DateTime(normalized.year, normalized.month, 1);
      _loading = true;
    });
    try {
      final items = await store.getByDate(normalized);
      final monthItems = await store.getByMonth(selectedMonth);
      final grouped = <int, List<HabitItem>>{};
      for (final h in monthItems) {
        grouped.putIfAbsent(h.dueDate.day, () => []).add(h);
      }
      if (!mounted) return;
      setState(() {
        habits = items;
        monthHabitsByDay = grouped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _jumpMonth(int delta) async {
    final next = DateTime(selectedMonth.year, selectedMonth.month + delta, 1);
    setState(() {
      selectedMonth = next;
      if (selectedDate.year != next.year || selectedDate.month != next.month) {
        selectedDate = DateTime(next.year, next.month, 1);
      }
      _loading = true;
    });
    try {
      final items = await store.getByDate(selectedDate);
      final monthItems = await store.getByMonth(next);
      final grouped = <int, List<HabitItem>>{};
      for (final h in monthItems) {
        grouped.putIfAbsent(h.dueDate.day, () => []).add(h);
      }
      if (!mounted) return;
      setState(() {
        habits = items;
        monthHabitsByDay = grouped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    final mode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          selectedViewMode: viewMode == AppViewMode.month ? 'month' : 'day',
        ),
      ),
    );
    if (!mounted || mode == null) return;
    final next = mode == 'month' ? AppViewMode.month : AppViewMode.day;
    setState(() => viewMode = next);
    await store.setViewMode(mode);
    if (next == AppViewMode.month) {
      await _loadDate(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // Liste entspricht dem aktuell ausgewählten Datum
    final todaysHabits = habits;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text(
                  "Menü",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text("Kategorien"),
                onTap: () async {
                  Navigator.of(context).pop(); // Drawer schließen
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesPage()),
                  );
                  if (!mounted) return;
                  final cats = await store.getCategories();
                  setState(() {
                    categories = cats;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Einstellungen"),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _openSettings();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: const Text(
          "Habits",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),

      body: viewMode == AppViewMode.month
          ? _buildMonthModeContent(todaysHabits)
          : Column(
              children: [
                _DateSelector(selectedDate: selectedDate, onChanged: _loadDate),
                _HeaderSection(
                  count: todaysHabits.length,
                  selectedDate: selectedDate,
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildDayHabitsList(todaysHabits)),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayHabitsList(
    List<HabitItem> dayHabits, {
    String emptyText = "Keine Todos heute!",
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    if (dayHabits.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView(
      padding: padding,
      children: dayHabits.map((habit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SwipeToDelete(
            key: ValueKey(habit.id),
            onDelete: () {
              () async {
                try {
                  await store.delete(habit.id);
                  if (!mounted) return;
                  await _loadDate(selectedDate);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Deleted '${habit.name}'")),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Löschen fehlgeschlagen")),
                  );
                }
              }();
            },
            child: HabitTile(
              name: habit.name,
              isDone: habit.isDone,
              status: habit.status,
              categoryColor: (() {
                final c = categories.firstWhere(
                  (c) => c.id == habit.categoryId,
                  orElse: () =>
                      Category(id: -1, name: '', color: 0, iconKey: 'category'),
                );
                return c.id == -1 ? null : Color(c.color);
              })(),
              categoryIcon: (() {
                final c = categories.firstWhere(
                  (c) => c.id == habit.categoryId,
                  orElse: () =>
                      Category(id: -1, name: '', color: 0, iconKey: 'category'),
                );
                if (c.id == -1) return null;
                return iconFromKey(c.iconKey);
              })(),
              categoryName: (() {
                final c = categories.firstWhere(
                  (c) => c.id == habit.categoryId,
                  orElse: () =>
                      Category(id: -1, name: '', color: 0, iconKey: 'category'),
                );
                return c.id == -1 ? null : c.name;
              })(),
              subDone: habit.subtasks.where((s) => s.isDone).length,
              subTotal: habit.subtasks.length,
              onToggle: () async {
                final updated = await store.toggleDone(habit.id);
                if (!mounted || updated == null) return;
                await _loadDate(selectedDate);
              },
              onOpen: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      SubtasksSheet(habitId: habit.id, habitName: habit.name),
                );
                if (!mounted) return;
                await _loadDate(selectedDate);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthModeContent(List<HabitItem> dayHabits) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateText =
        "${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}";

    return ScrollConfiguration(
      behavior: const _NoStretchScrollBehavior(),
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _MonthSelectorBar(
              monthDate: selectedMonth,
              onToday: () => _loadDate(DateTime.now()),
              onPrevious: () => _jumpMonth(-1),
              onNext: () => _jumpMonth(1),
            ),
          ),
          SliverToBoxAdapter(
            child: _HeaderSection(
              count: dayHabits.length,
              selectedDate: selectedDate,
              monthMode: true,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: _MonthView(
              monthDate: selectedMonth,
              selectedDate: selectedDate,
              itemsByDay: monthHabitsByDay,
              categories: categories,
              onSelectDay: _loadDate,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Todos am $dateText",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      "${dayHabits.length}",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (dayHabits.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text("Keine Todos für den ausgewählten Tag"),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final habit = dayHabits[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SwipeToDelete(
                      key: ValueKey(habit.id),
                      onDelete: () {
                        () async {
                          try {
                            await store.delete(habit.id);
                            if (!mounted) return;
                            await _loadDate(selectedDate);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Deleted '${habit.name}'"),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Löschen fehlgeschlagen"),
                              ),
                            );
                          }
                        }();
                      },
                      child: HabitTile(
                        name: habit.name,
                        isDone: habit.isDone,
                        status: habit.status,
                        categoryColor: (() {
                          final c = categories.firstWhere(
                            (c) => c.id == habit.categoryId,
                            orElse: () => Category(
                              id: -1,
                              name: '',
                              color: 0,
                              iconKey: 'category',
                            ),
                          );
                          return c.id == -1 ? null : Color(c.color);
                        })(),
                        categoryIcon: (() {
                          final c = categories.firstWhere(
                            (c) => c.id == habit.categoryId,
                            orElse: () => Category(
                              id: -1,
                              name: '',
                              color: 0,
                              iconKey: 'category',
                            ),
                          );
                          if (c.id == -1) return null;
                          return iconFromKey(c.iconKey);
                        })(),
                        categoryName: (() {
                          final c = categories.firstWhere(
                            (c) => c.id == habit.categoryId,
                            orElse: () => Category(
                              id: -1,
                              name: '',
                              color: 0,
                              iconKey: 'category',
                            ),
                          );
                          return c.id == -1 ? null : c.name;
                        })(),
                        subDone: habit.subtasks.where((s) => s.isDone).length,
                        subTotal: habit.subtasks.length,
                        onToggle: () async {
                          final updated = await store.toggleDone(habit.id);
                          if (!mounted || updated == null) return;
                          await _loadDate(selectedDate);
                        },
                        onOpen: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => SubtasksSheet(
                              habitId: habit.id,
                              habitName: habit.name,
                            ),
                          );
                          if (!mounted) return;
                          await _loadDate(selectedDate);
                        },
                      ),
                    ),
                  );
                }, childCount: dayHabits.length),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dayWatcher?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// =====================================================
  ///                   ADD DIALOG
  /// =====================================================
  void _openAddDialog() {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    // Verwende immer den Messenger des Home-Scaffolds, nicht den Sheet-Context
    final rootMessenger = ScaffoldMessenger.of(context);

    DateTime? dueDate;
    int? selectedCategoryId;

    // Unterpunkte (optional) für neues Todo
    List<SubTask> newSubs = [];

    // Eingabegrenzen und Live-Status
    const int titleMax = 80;
    String titleText = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final insets = MediaQuery.of(ctx).viewInsets;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(ctx).unfocus(),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: insets.bottom),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.95,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 44,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Neues Todo",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  autofocus: true,
                                  maxLength: titleMax,
                                  maxLengthEnforcement:
                                      MaxLengthEnforcement.enforced,
                                  onChanged: (v) =>
                                      setModal(() => titleText = v),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      FocusScope.of(ctx).unfocus(),
                                  decoration: InputDecoration(
                                    hintText: "z. B. Wasser trinken",
                                    counterText:
                                        "${controller.text.characters.length}/$titleMax",
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFF2F2F7),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                /// DATE PICKER (optional)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        FocusScope.of(ctx).unfocus();
                                        final initial = dueDate ?? selectedDate;
                                        final picked = await showDatePicker(
                                          context: ctx,
                                          initialDate: initial,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                          helpText: "Datum wählen (optional)",
                                        );
                                        if (picked != null) {
                                          final normalized = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                          );
                                          setModal(() {
                                            dueDate = normalized;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.event),
                                      label: Text(
                                        (() {
                                          if (dueDate == null)
                                            return "Datum wählen";
                                          final w = [
                                            "Mo",
                                            "Di",
                                            "Mi",
                                            "Do",
                                            "Fr",
                                            "Sa",
                                            "So",
                                          ][dueDate!.weekday - 1];
                                          final m = [
                                            "Jan",
                                            "Feb",
                                            "Mär",
                                            "Apr",
                                            "Mai",
                                            "Jun",
                                            "Jul",
                                            "Aug",
                                            "Sep",
                                            "Okt",
                                            "Nov",
                                            "Dez",
                                          ][dueDate!.month - 1];
                                          return "$w, ${dueDate!.day.toString().padLeft(2, '0')} $m ${dueDate!.year}";
                                        })(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Optional - wähle ein Datum",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Kategorienauswahl
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Kategorie (optional)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        FocusScope.of(ctx).unfocus();
                                        await Navigator.of(ctx).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CategoriesPage(),
                                          ),
                                        );
                                        final updated = await store
                                            .getCategories();
                                        if (!mounted) return;
                                        setState(() {
                                          categories = updated;
                                        });
                                        setModal(() {});
                                      },
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text("Verwalten"),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.category_outlined),
                                    label: Text(() {
                                      final c = categories.firstWhere(
                                        (c) => c.id == selectedCategoryId,
                                        orElse: () => Category(
                                          id: -1,
                                          name: 'Keine',
                                          color: 0,
                                          iconKey: 'category',
                                        ),
                                      );
                                      return c.id == -1
                                          ? "Kategorie wählen"
                                          : "Kategorie: ${c.name}";
                                    }()),
                                    onPressed: () async {
                                      FocusScope.of(ctx).unfocus();
                                      final chosen =
                                          await showModalBottomSheet<int?>(
                                            context: ctx,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) {
                                              return FractionallySizedBox(
                                                heightFactor: 0.9,
                                                child: CategoryPickerSheet(
                                                  categories: categories,
                                                  initial: selectedCategoryId,
                                                ),
                                              );
                                            },
                                          );
                                      setModal(
                                        () => selectedCategoryId = chosen,
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Unterpunkte (optional)
                                const Text(
                                  "Unterpunkte (optional)",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    FocusScope.of(ctx).unfocus();
                                    final result =
                                        await showModalBottomSheet<
                                          List<SubTask>
                                        >(
                                          context: ctx,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) {
                                            final kb = MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom;
                                            final sheet = FractionallySizedBox(
                                              heightFactor: 0.95,
                                              child: SafeArea(
                                                top: false,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 160,
                                                  ),
                                                  curve: Curves.easeOut,
                                                  padding: EdgeInsets.only(
                                                    bottom: kb,
                                                  ),
                                                  child: SubtaskEditorSheet(
                                                    initial: newSubs,
                                                  ),
                                                ),
                                              ),
                                            );
                                            return MediaQuery.removeViewInsets(
                                              context: context,
                                              removeBottom: true,
                                              child: sheet,
                                            );
                                          },
                                        );
                                    if (result != null) {
                                      setModal(() => newSubs = result);
                                    }
                                  },
                                  icon: const Icon(Icons.checklist),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Unterpunkte verwalten"),
                                      if (newSubs.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            "${newSubs.length}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (newSubs.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        ...newSubs.take(3).map((s) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: Chip(
                                              label: Text(
                                                s.title.length > 24
                                                    ? "${s.title.substring(0, 24)}..."
                                                    : s.title,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          );
                                        }).toList(),
                                        if (newSubs.length > 3)
                                          Chip(
                                            label: Text(
                                              "+${newSubs.length - 3} weitere",
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(sheetContext),
                                      child: const Text("Abbrechen"),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          (controller.text.trim().isEmpty ||
                                              controller.text.trim().length >
                                                  titleMax)
                                          ? null
                                          : () async {
                                              final text = controller.text
                                                  .trim();

                                              final chosen =
                                                  dueDate ?? selectedDate;
                                              final normalized = DateTime(
                                                chosen.year,
                                                chosen.month,
                                                chosen.day,
                                              );

                                              Navigator.pop(sheetContext);

                                              try {
                                                final created = await store
                                                    .addHabit(
                                                      text,
                                                      normalized,
                                                      categoryId:
                                                          selectedCategoryId,
                                                      subtasks: newSubs,
                                                    );
                                                if (!mounted) return;
                                                await _loadDate(normalized);
                                                final cats2 = await store
                                                    .getCategories();
                                                if (!mounted) return;
                                                setState(() {
                                                  categories = cats2;
                                                });

                                                final y = created.dueDate.year
                                                    .toString()
                                                    .padLeft(4, '0');
                                                final m = created.dueDate.month
                                                    .toString()
                                                    .padLeft(2, '0');
                                                final d = created.dueDate.day
                                                    .toString()
                                                    .padLeft(2, '0');
                                                rootMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Todo erstellt für $y-$m-$d",
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!mounted) return;
                                                setState(
                                                  () => _loading = false,
                                                );
                                                rootMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text("Fehler: $e"),
                                                  ),
                                                );
                                              }
                                            },
                                      child: const Text("Hinzufügen"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// =====================================================
///                       HEADER
/// =====================================================
class _HeaderSection extends StatelessWidget {
  final int count;
  final DateTime selectedDate;
  final bool monthMode;

  const _HeaderSection({
    required this.count,
    required this.selectedDate,
    this.monthMode = false,
  });

  String _getTitle() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final diff = selected.difference(today).inDays;

    if (!monthMode) {
      if (diff == 0) return "Heute";
      if (diff == 1) return "Morgen";
      if (diff == -1) return "Gestern";
    }

    const weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
    const months = [
      "Jan",
      "Feb",
      "Mär",
      "Apr",
      "Mai",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Okt",
      "Nov",
      "Dez",
    ];

    final weekday = weekdays[selected.weekday - 1];
    final day = selected.day.toString().padLeft(2, '0');
    final month = months[selected.month - 1];

    return "$weekday, $day $month";
  }

  String _getCountText() {
    if (count == 0) return "Keine Aufgaben";
    if (count == 1) return "1 Aufgabe";
    return "$count Aufgaben";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getTitle(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(_getCountText()),
          ],
        ),
      ),
    );
  }
}

/// =====================================================
///            HABIT TILE (controlled)
/// =====================================================
class HabitTile extends StatelessWidget {
  final String name;
  final bool isDone;
  final String status; // 'open' | 'done' | 'skipped'
  final VoidCallback onToggle;
  final Color? categoryColor;
  final IconData? categoryIcon;
  final String? categoryName;
  final VoidCallback? onOpen;
  final int? subDone;
  final int? subTotal;

  const HabitTile({
    super.key,
    required this.name,
    required this.isDone,
    required this.status,
    required this.onToggle,
    this.categoryColor,
    this.categoryIcon,
    this.categoryName,
    this.onOpen,
    this.subDone,
    this.subTotal,
  });

  List<Color> get colors => const [
    Color(0xFFFF8A80),
    Color(0xFF82B1FF),
    Color(0xFF69F0AE),
    Color(0xFFFFD180),
  ];

  Color getFallbackColor() => colors[name.hashCode % colors.length];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = categoryColor ?? getFallbackColor();

    final bool isSkipped = status == 'skipped';
    final Color borderColor = status == 'done'
        ? Colors.green.withOpacity(0.6)
        : (isSkipped ? Colors.red.withOpacity(0.6) : Colors.transparent);
    final String displayName = name.length > 80
        ? '${name.substring(0, 80)}...'
        : name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: status == 'done' ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: status == 'done'
                      ? Colors.green
                      : (isSkipped ? Colors.red : Colors.grey),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: () {
                if (status == 'done') {
                  return const Icon(Icons.check, size: 18, color: Colors.white);
                } else if (isSkipped) {
                  return const Icon(Icons.close, size: 18, color: Colors.red);
                }
                return null;
              }(),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      decoration: status == 'done'
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (categoryName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: base.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (categoryIcon != null) ...[
                            Icon(categoryIcon, size: 12, color: base),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            categoryName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: base,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if ((subTotal ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.checklist,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${subDone ?? 0}/${subTotal ?? 0} Unterpunkte",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (ctx, c) {
                        final d = (subDone ?? 0).toDouble();
                        final t = (subTotal ?? 0).toDouble();
                        final p = t == 0 ? 0.0 : (d / t).clamp(0.0, 1.0);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 6,
                            child: LinearProgressIndicator(
                              value: p,
                              backgroundColor:
                                  (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.08),
                              color: const Color(0xFF7C7AE6),
                              minHeight: 6,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================================================
///                SWIPE TO DELETE
/// =====================================================
class _SwipeToDelete extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _SwipeToDelete({
    super.key,
    required this.child,
    required this.onDelete,
  });

  @override
  State<_SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<_SwipeToDelete>
    with SingleTickerProviderStateMixin {
  double offsetX = 0;

  late AnimationController controller;
  Animation<double>? animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  void animateTo(double target, {VoidCallback? onComplete}) {
    controller.stop();

    animation?.removeListener(_listener);

    animation = Tween<double>(
      begin: offsetX,
      end: target,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutExpo));

    animation!.addListener(_listener);

    controller.forward(from: 0).whenComplete(() {
      if (onComplete != null) onComplete();
    });
  }

  void _listener() {
    setState(() {
      offsetX = animation!.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (-offsetX / 140).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2 + 0.5 * progress),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Opacity(
              opacity: progress,
              child: const Icon(Icons.delete, color: Colors.red),
            ),
          ),
        ),

        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              offsetX += details.delta.dx;
              if (offsetX > 0) offsetX = 0;
            });
          },
          onHorizontalDragEnd: (details) {
            final shouldDelete = offsetX < -90;

            if (shouldDelete) {
              HapticFeedback.heavyImpact();
              Future.delayed(const Duration(milliseconds: 80), () {
                HapticFeedback.heavyImpact();
              });
              animateTo(-500, onComplete: widget.onDelete);
            } else {
              animateTo(0);
            }
          },
          child: Transform.translate(
            offset: Offset(offsetX, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
