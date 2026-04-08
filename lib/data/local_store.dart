import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/habit_item.dart';
import '../models/category.dart';
import '../models/subtask_model.dart';

class LocalStore {
  LocalStore._internal();
  static final LocalStore I = LocalStore._internal();

  late File _file;
  bool _initialized = false;

  // Persistenter Zustand
  bool isDark = true;
  String viewMode = 'day';
  DateTime? _lastActiveDay;
  final List<HabitItem> _habits = [];
  final List<Category> _categories = [];

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/habits.json');

    if (await _file.exists()) {
      try {
        final content = await _file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final theme = (data['theme'] as String?) ?? 'dark';
        isDark = theme == 'dark';
        final mode = (data['viewMode'] as String?) ?? 'day';
        viewMode = mode == 'month' ? 'month' : 'day';
        _lastActiveDay = _parseDay(data['lastActiveDay']);

        final list = (data['habits'] as List<dynamic>? ?? []);
        _habits
          ..clear()
          ..addAll(
            list.map((e) => HabitItem.fromJson(e as Map<String, dynamic>)),
          );

        final catList = (data['categories'] as List<dynamic>? ?? []);
        _categories
          ..clear()
          ..addAll(
            catList.map((e) => Category.fromJson(e as Map<String, dynamic>)),
          );

        if (_categories.isEmpty) {
          _seedDefaultCategories();
          await _save();
        }
      } catch (_) {
        // Bei defekter Datei neu anfangen
        isDark = true;
        _habits.clear();
        _categories.clear();
        _seedDefaultCategories();
        await _save();
      }
    } else {
      _seedDefaultCategories();
      await _save();
    }

    _initialized = true;
  }

  void _seedDefaultCategories() {
    final List<Category> defaults = [
      Category(id: 1, name: 'Arbeit', color: 0xFF82B1FF, iconKey: 'work'),
      Category(
        id: 2,
        name: 'Fitness',
        color: 0xFF69F0AE,
        iconKey: 'fitness_center',
      ),
      Category(id: 3, name: 'Lernen', color: 0xFFFFD180, iconKey: 'school'),
      Category(id: 4, name: 'Haushalt', color: 0xFFFF8A80, iconKey: 'home'),
    ];
    _categories.addAll(defaults);
  }

  Future<void> _save() async {
    final map = <String, dynamic>{
      'theme': isDark ? 'dark' : 'light',
      'viewMode': viewMode,
      'lastActiveDay': _lastActiveDay == null
          ? null
          : _formatDay(_lastActiveDay!),
      'categories': _categories.map((c) => c.toJson()).toList(),
      'habits': _habits.map((h) => h.toJson()).toList(),
    };
    await _file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(map),
      flush: true,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? _parseDay(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return null;
    try {
      final dt = DateTime.parse(s);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  static String _formatDay(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<int> applyDayRollover() async {
    final today = _today();
    final last = _lastActiveDay;
    int skipped = 0;

    if (last != null && last.isBefore(today)) {
      for (var i = 0; i < _habits.length; i++) {
        final h = _habits[i];
        final due = DateTime(h.dueDate.year, h.dueDate.month, h.dueDate.day);
        if (due.isBefore(today) && h.status == 'open') {
          _habits[i] = h.copyWith(status: 'skipped', isDone: false);
          skipped++;
        }
      }
    }

    if (last == null || !_sameDay(last, today) || skipped > 0) {
      _lastActiveDay = today;
      await _save();
    }
    return skipped;
  }

  Future<List<HabitItem>> getByDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final items = _habits.where((h) => _sameDay(h.dueDate, d)).toList();
    items.sort((a, b) => b.id.compareTo(a.id));
    return items;
  }

  Future<List<HabitItem>> getByMonth(DateTime date) async {
    final y = date.year;
    final m = date.month;
    final items = _habits
        .where((h) => h.dueDate.year == y && h.dueDate.month == m)
        .toList();
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  Future<HabitItem> addHabit(
    String name,
    DateTime date, {
    int? categoryId,
    List<SubTask>? subtasks,
  }) async {
    final d = DateTime(date.year, date.month, date.day);
    final nextId = _habits.fold<int>(0, (m, h) => h.id > m ? h.id : m) + 1;
    final item = HabitItem(
      id: nextId,
      name: name,
      dueDate: d,
      isDone: false,
      categoryId: categoryId,
      subtasks: subtasks ?? const [],
    );
    _habits.add(item);
    await _save();
    return item;
  }

  Future<void> delete(int id) async {
    _habits.removeWhere((h) => h.id == id);
    await _save();
  }

  Future<HabitItem?> toggleDone(int id) async {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx == -1) return null;
    final current = _habits[idx];
    final nextStatus = () {
      if (current.status == 'open') return 'done';
      if (current.status == 'done') return 'skipped';
      return 'open';
    }();

    List<SubTask> subs = current.subtasks;
    if (nextStatus == 'done') {
      subs = subs.map((s) => s.copyWith(isDone: true)).toList();
    } else if (nextStatus == 'skipped') {
      subs = subs.map((s) => s.copyWith(isDone: false)).toList();
    }

    final updated = current.copyWith(
      status: nextStatus,
      isDone: nextStatus == 'done',
      subtasks: subs,
    );
    _habits[idx] = updated;
    await _save();
    return updated;
  }

  // Kategorien
  Future<List<Category>> getCategories() async {
    return List<Category>.unmodifiable(_categories);
  }

  Future<Category> addCategory(String name, int color, String iconKey) async {
    final nextId = _categories.fold<int>(0, (m, c) => c.id > m ? c.id : m) + 1;
    final cat = Category(
      id: nextId,
      name: name,
      color: color,
      iconKey: iconKey,
    );
    _categories.add(cat);
    await _save();
    return cat;
  }

  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((c) => c.id == id);
    // Entknüpfe Habits von gelöschter Kategorie
    for (var i = 0; i < _habits.length; i++) {
      if (_habits[i].categoryId == id) {
        _habits[i] = _habits[i].copyWith(categoryId: null);
      }
    }
    await _save();
  }

  Category? findCategory(int? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  HabitItem? getHabit(int id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<HabitItem?> addSubTask(int habitId, String title) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return null;
    final habit = _habits[idx];
    final nextId =
        habit.subtasks.fold<int>(0, (m, s) => s.id > m ? s.id : m) + 1;
    final effectiveDone = habit.status == 'done' || habit.isDone;
    final sub = SubTask(id: nextId, title: title, isDone: effectiveDone);
    final updated = habit.copyWith(subtasks: [...habit.subtasks, sub]);
    _habits[idx] = updated;
    await _save();
    return updated;
  }

  Future<HabitItem?> toggleSubTask(int habitId, int subTaskId) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return null;
    final habit = _habits[idx];
    final sIdx = habit.subtasks.indexWhere((s) => s.id == subTaskId);
    if (sIdx == -1) return habit;
    final current = habit.subtasks[sIdx];

    final toggledSubs = [...habit.subtasks];
    toggledSubs[sIdx] = current.copyWith(isDone: !current.isDone);

    // Wenn vorher „skipped“, Status verlassen, sobald ein Subtask editiert wird.
    String newStatus = habit.status == 'skipped' ? 'open' : habit.status;
    bool newIsDone = habit.status == 'skipped' ? false : habit.isDone;

    final allDone =
        toggledSubs.isNotEmpty && toggledSubs.every((s) => s.isDone);
    if (allDone) {
      newStatus = 'done';
      newIsDone = true;
    } else {
      if (newStatus == 'done') {
        newStatus = 'open';
        newIsDone = false;
      }
    }

    final updated = habit.copyWith(
      subtasks: toggledSubs,
      status: newStatus,
      isDone: newIsDone,
    );
    _habits[idx] = updated;
    await _save();
    return updated;
  }

  Future<HabitItem?> deleteSubTask(int habitId, int subTaskId) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return null;
    final habit = _habits[idx];
    final newSubs = habit.subtasks.where((s) => s.id != subTaskId).toList();

    String newStatus = habit.status;
    bool newIsDone = habit.isDone;
    if (habit.status != 'skipped') {
      if (newSubs.isNotEmpty && newSubs.every((s) => s.isDone)) {
        newStatus = 'done';
        newIsDone = true;
      } else if (newStatus == 'done' && newSubs.any((s) => !s.isDone)) {
        newStatus = 'open';
        newIsDone = false;
      }
    }

    final updated = habit.copyWith(
      subtasks: newSubs,
      status: newStatus,
      isDone: newIsDone,
    );
    _habits[idx] = updated;
    await _save();
    return updated;
  }

  Future<void> setTheme(bool dark) async {
    isDark = dark;
    await _save();
  }

  Future<void> setViewMode(String mode) async {
    viewMode = mode == 'month' ? 'month' : 'day';
    await _save();
  }
}
