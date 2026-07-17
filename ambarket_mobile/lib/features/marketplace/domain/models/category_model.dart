class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _stringValue(json['id'], fallback: 'unknown-category'),
      name: _stringValue(json['name'], fallback: 'Kategori'),
      icon: _nullableString(json['icon']),
      createdAt: _dateValue(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

DateTime _dateValue(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
