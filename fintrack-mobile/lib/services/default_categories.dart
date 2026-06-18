/// The starter set of categories created for every new user the first time
/// they sign in. Stored as plain maps so both the Firestore and in-memory
/// repositories can seed from the same source of truth.
const List<Map<String, dynamic>> defaultCategories = [
  {'name': 'Salary', 'icon': '💼', 'color_value': 0xFF4CAF50, 'type': 'income'},
  {'name': 'Freelance', 'icon': '💻', 'color_value': 0xFF2196F3, 'type': 'income'},
  {'name': 'Investment', 'icon': '📈', 'color_value': 0xFF9C27B0, 'type': 'income'},
  {'name': 'Gift', 'icon': '🎁', 'color_value': 0xFFFF9800, 'type': 'income'},
  {'name': 'Food', 'icon': '🍔', 'color_value': 0xFFF44336, 'type': 'expense'},
  {'name': 'Transport', 'icon': '🚗', 'color_value': 0xFF607D8B, 'type': 'expense'},
  {'name': 'Shopping', 'icon': '🛍️', 'color_value': 0xFFE91E63, 'type': 'expense'},
  {'name': 'Bills', 'icon': '📄', 'color_value': 0xFF795548, 'type': 'expense'},
  {'name': 'Health', 'icon': '💊', 'color_value': 0xFF00BCD4, 'type': 'expense'},
  {'name': 'Entertainment', 'icon': '🎬', 'color_value': 0xFFFF5722, 'type': 'expense'},
  {'name': 'Education', 'icon': '📚', 'color_value': 0xFF3F51B5, 'type': 'expense'},
  {'name': 'Other', 'icon': '📦', 'color_value': 0xFF9E9E9E, 'type': 'expense'},
];
