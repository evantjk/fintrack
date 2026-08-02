// A spending/earning group (e.g. Food, Salary) used to label transactions.
class Category {
  /// Firestore document id. Null for a category that hasn't been saved yet.
  final String? id;
  final String name;        // display name
  final String icon;        // icon name shown next to it
  final int colorValue;     // colour stored as a number
  final String type; // 'income' or 'expense' or 'both'

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.type,
  });

  // Returns a copy with only the given fields changed.
  Category copyWith({
    String? id,
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

  /// Document fields only — the id is the Firestore document id, stored
  /// separately, so it is never part of the map.
  // Turns this category into a map to send to the backend.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color_value': colorValue,
      'type': type,
    };
  }

  // Builds a category from map data that came back from the backend.
  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: (map['color_value'] as num).toInt(),
      type: map['type'] as String,
    );
  }
}
