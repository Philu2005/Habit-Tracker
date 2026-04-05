import 'package:flutter/material.dart';
import 'package:habit_tracker/models/category.dart';
import 'package:habit_tracker/ui/icon_registry.dart';

class CategoryPickerSheet extends StatefulWidget {
  final List<Category> categories;
  final int? initial;

  const CategoryPickerSheet({super.key, required this.categories, this.initial});

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.categories.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (ctx, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Kategorie wählen", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        onPressed: () => Navigator.pop(context, widget.initial),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Suchen...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Keine"),
                  trailing: Radio<int?>(value: null, groupValue: widget.initial, onChanged: (_) => Navigator.pop(context, null)),
                  onTap: () => Navigator.pop(context, null),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: controller,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final c = filtered[i];
                        final color = Color(c.color);
                        return ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(iconFromKey(c.iconKey), color: color, size: 18),
                          ),
                          title: Text(c.name),
                          trailing: Radio<int?>(value: c.id, groupValue: widget.initial, onChanged: (_) => Navigator.pop(context, c.id)),
                          onTap: () => Navigator.pop(context, c.id),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
