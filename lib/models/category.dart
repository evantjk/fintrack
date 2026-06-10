class Category {
  final int? id;
  final String name;
  final String icon;
  final int colorValue;
  final String type; // 'income' or 'expense' or 'both'

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.type,
  });

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    int? colorValue,
    String? type,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color_value': colorValue,
      'type': type,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: map['color_value'] as int,
      type: map['type'] as String,
    );
  }
}
