import 'package:flutter/material.dart';
import 'package:habit_tracker/data/local_store.dart';
import 'package:habit_tracker/models/habit_item.dart';
import 'package:habit_tracker/models/subtask_model.dart';

class SubtasksSheet extends StatefulWidget {
  final int habitId;
  final String habitName;

  const SubtasksSheet({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  State<SubtasksSheet> createState() => _SubtasksSheetState();
}

class _SubtasksSheetState extends State<SubtasksSheet> {
  final store = LocalStore.I;
  HabitItem? habit;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      habit = store.getHabit(widget.habitId);
    });
  }

  Future<void> _add() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    final updated = await store.addSubTask(widget.habitId, t);
    _ctrl.clear();
    setState(() => habit = updated);
  }

  Future<void> _toggle(int subId) async {
    final updated = await store.toggleSubTask(widget.habitId, subId);
    setState(() => habit = updated);
  }

  Future<void> _delete(int subId) async {
    final updated = await store.deleteSubTask(widget.habitId, subId);
    setState(() => habit = updated);
  }

  Future<void> _toggleWhole() async {
    if (habit == null) return;
    final updated = await store.toggleDone(habit!.id);
    setState(() => habit = updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subs = habit?.subtasks ?? const <SubTask>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, controller) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(widget.habitName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        Checkbox(
                          value: habit?.isDone ?? false,
                          onChanged: (_) => _toggleWhole(),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: subs.isEmpty
                        ? const Center(child: Text("Keine Unterpunkte"))
                        : ListView.separated(
                            controller: controller,
                            itemCount: subs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final s = subs[i];
                              return ListTile(
                                leading: Checkbox(
                                  value: s.isDone,
                                  onChanged: (_) => _toggle(s.id),
                                ),
                                title: Text(
                                  s.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    decoration: s.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(s.id),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            decoration: InputDecoration(
                              hintText: "Unterpunkt hinzufügen",
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _add(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _add,
                          child: const Text("Hinzufügen"),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
