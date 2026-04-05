import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_tracker/models/subtask_model.dart';

class SubtaskEditorSheet extends StatefulWidget {
  final List<SubTask> initial;

  const SubtaskEditorSheet({super.key, this.initial = const []});

  @override
  State<SubtaskEditorSheet> createState() => _SubtaskEditorSheetState();
}

class _SubtaskEditorSheetState extends State<SubtaskEditorSheet> {
  late List<SubTask> items;
  late int nextId;

  final TextEditingController _addCtrl = TextEditingController();
  final FocusNode _addFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    items = List<SubTask>.from(widget.initial);
    nextId = items.isEmpty ? 1 : (items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
  }

  void _addOne(String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    setState(() {
      items.add(SubTask(id: nextId++, title: t, isDone: false));
      _addCtrl.clear();
    });
    _addFocus.requestFocus();
  }

  void _bulkAdd() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Mehrere Unterpunkte hinzufügen", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: "Jede Zeile wird zu einem Unterpunkt",
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final lines = ctrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
                        setState(() {
                          for (final l in lines) {
                            items.add(SubTask(id: nextId++, title: l, isDone: false));
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text("Hinzufügen"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = items.where((e) => e.isDone).length;
    final total = items.length;
    final progress = total == 0 ? 0.0 : done / total;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.95,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Schließen",
              onPressed: () => Navigator.pop(context, widget.initial),
            ),
            title: const Text(
              "Unterpunkte",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, items),
                  icon: const Icon(Icons.check),
                  label: const Text("Fertig"),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(8),
              child: SizedBox(height: 8),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist, color: isDark ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          "$done von $total erledigt",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          total == 0 ? "0%" : "${(progress * 100).round()}%",
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                          color: const Color(0xFF7C7AE6),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.checklist, size: 44),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Noch keine Unterpunkte",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Tipp: Unten kannst du Unterpunkte hinzufügen. Die Tastatur schiebt das Feld automatisch nach oben.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = items.removeAt(oldIndex);
                            items.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (ctx, i) {
                          final s = items[i];
                          return Padding(
                            key: ValueKey(s.id),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF7F7FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: s.isDone,
                                    onChanged: (_) {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        final idx = items.indexWhere((e) => e.id == s.id);
                                        items[idx] = items[idx].copyWith(isDone: !items[idx].isDone);
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: s.title,
                                      maxLines: 2,
                                      decoration: const InputDecoration(
                                        hintText: "Unterpunkt",
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      style: TextStyle(
                                        decoration: s.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      onChanged: (v) {
                                        final t = v.trimLeft();
                                        setState(() {
                                          final idx = items.indexWhere((e) => e.id == s.id);
                                          items[idx] = items[idx].copyWith(title: t);
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "Löschen",
                                    onPressed: () {
                                      setState(() {
                                        items.removeWhere((e) => e.id == s.id);
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                  const SizedBox(width: 4),
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(Icons.drag_handle, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addCtrl,
                            focusNode: _addFocus,
                            autofocus: true,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Unterpunkt hinzufügen",
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: _addOne,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _addOne(_addCtrl.text),
                          icon: const Icon(Icons.add),
                          label: const Text("Hinzufügen"),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _bulkAdd,
                      icon: const Icon(Icons.playlist_add),
                      label: const Text("Mehrere auf einmal hinzufügen"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
