import 'subtask_model.dart';

class HabitItem {
  final int id;
  final String name;
  final DateTime dueDate;
  final bool isDone;
  final String status; // 'open' | 'done' | 'skipped'
  final int? categoryId;
  final List<SubTask> subtasks;

  HabitItem({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.isDone,
    String? status,
    this.categoryId,
    List<SubTask>? subtasks,
  })  : status = status ?? (isDone ? 'done' : 'open'),
        subtasks = ((status ?? (isDone ? 'done' : 'open')) == 'done')
            ? ((subtasks ?? const []).map((e) => e.copyWith(isDone: true)).toList())
            : (subtasks ?? const []);

  HabitItem copyWith({
    int? id,
    String? name,
    DateTime? dueDate,
    bool? isDone,
    String? status,
    int? categoryId,
    List<SubTask>? subtasks,
  }) {
    final newIsDone = isDone ?? this.isDone;
    final newStatus = status ?? this.status;
    final effectiveDone = newStatus == 'done' || newIsDone;
    final baseSubs = subtasks ?? this.subtasks;
    final newSubs = effectiveDone
        ? baseSubs.map((e) => e.copyWith(isDone: true)).toList()
        : (newStatus == 'skipped'
            ? baseSubs.map((e) => e.copyWith(isDone: false)).toList()
            : baseSubs);

    return HabitItem(
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      isDone: newIsDone,
      status: newStatus,
      categoryId: categoryId ?? this.categoryId,
      subtasks: newSubs,
    );
  }

  static DateTime _parseDueDate(dynamic value) {
    final s = (value ?? '').toString();
    final reDateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (reDateOnly.hasMatch(s)) {
      final parts = s.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
    if (s.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final dt = DateTime.parse(s);
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    final subsRaw = (json['subtasks'] as List<dynamic>?) ?? const [];
    final String status = (json['status'] as String?) ?? ((json['isDone'] as bool?) ?? false ? 'done' : 'open');
    final bool done = status == 'done';
    return HabitItem(
      id: json['id'] as int,
      name: json['name'] as String,
      dueDate: _parseDueDate(json['dueDate']),
      isDone: done,
      status: status,
      categoryId: json['categoryId'] as int?,
      subtasks: subsRaw.map((e) => SubTask.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dueDate': '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      'isDone': isDone,
      'status': status,
      'categoryId': categoryId,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
    };
  }
}
