import 'package:flutter/material.dart';
import 'package:habit_tracker/data/local_store.dart';
import 'package:habit_tracker/models/category.dart';
import 'package:habit_tracker/ui/icon_registry.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final store = LocalStore.I;
  List<Category> categories = [];

  final List<Color> palette = const [
    Color(0xFF82B1FF),
    Color(0xFF69F0AE),
    Color(0xFFFFD180),
    Color(0xFFFF8A80),
    Color(0xFFB388FF),
    Color(0xFFFFF176),
    Color(0xFF80CBC4),
    Color(0xFFA5D6A7),
    Color(0xFF90CAF9),
    Color(0xFFCE93D8),
  ];

  final List<String> iconKeyChoices = kSelectableIconKeys;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await store.getCategories();
    if (!mounted) return;
    setState(() => categories = list);
  }

  Future<void> _addCategoryDialog() async {
    final nameCtrl = TextEditingController();
    Color selectedColor = palette.first;
    String selectedIconKey = iconKeyChoices.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(builder: (ctx, setModal) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Kategorie hinzufügen", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: "Name",
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Farbe", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: palette.map((c) {
                        final sel = c.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () => setModal(() => selectedColor = c),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: sel ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Icon", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: iconKeyChoices.map((key) {
                        final sel = key == selectedIconKey;
                        final ic = iconFromKey(key);
                        return GestureDetector(
                          onTap: () => setModal(() => selectedIconKey = key),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: sel ? selectedColor.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selectedColor.withOpacity(0.4)),
                            ),
                            child: Icon(ic, color: selectedColor),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            await store.addCategory(name, selectedColor.value, selectedIconKey);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            await _load();
                          },
                          child: const Text("Hinzufügen"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Kategorien"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategoryDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (ctx, i) {
          final c = categories[i];
          return ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(c.color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconFromKey(c.iconKey), color: Color(c.color)),
            ),
            title: Text(c.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final deleted = c;
                await store.deleteCategory(c.id);
                if (!mounted) return;
                await _load();

                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(12),
                    duration: const Duration(seconds: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    content: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(deleted.color).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconFromKey(deleted.iconKey),
                            color: Color(deleted.color),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Kategorie gelöscht",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                deleted.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    action: SnackBarAction(
                      label: "Rückgängig",
                      onPressed: () async {
                        await store.addCategory(deleted.name, deleted.color, deleted.iconKey);
                        if (!mounted) return;
                        await _load();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: categories.length,
      ),
    );
  }
}
