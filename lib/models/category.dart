import 'package:habit_tracker/ui/icon_registry.dart';

class Category {
  final int id;
  final String name;
  final int color; // ARGB
  final String iconKey; // Schlüssel in kIconRegistry

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.iconKey,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Migration: bevorzugt 'iconKey', fallback von altem 'icon' (codePoint)
    final String key = (json['iconKey'] as String?) ?? keyFromCodePoint((json['icon'] as int?) ?? 0);
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as int,
      iconKey: key,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'iconKey': iconKey,
      };
}
