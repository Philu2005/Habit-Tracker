class SubTask {
  final int id;
  final String title;
  final bool isDone;

  const SubTask({required this.id, required this.title, required this.isDone});

  SubTask copyWith({int? id, String? title, bool? isDone}) =>
      SubTask(id: id ?? this.id, title: title ?? this.title, isDone: isDone ?? this.isDone);

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as int,
      title: json['title'] as String,
      isDone: (json['isDone'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };
}
