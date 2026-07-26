/// The starter set of categories created for every new user the first time
/// they sign in. Stored as plain maps so both the Firestore and in-memory
/// repositories can seed from the same source of truth.
const List<Map<String, dynamic>> defaultCategories = [
  {
    'name': 'Salary',
    'icon': '💼',
    'color_value': 0xFF2E7D32, // Dark green
    'type': 'income',
  },
  {
    'name': 'Freelance',
    'icon': '💻',
    'color_value': 0xFF1565C0, // Blue
    'type': 'income',
  },
  {
    'name': 'Investment',
    'icon': '📈',
    'color_value': 0xFF6A1B9A, // Purple
    'type': 'income',
  },
  {
    'name': 'Gift',
    'icon': '🎁',
    'color_value': 0xFFFF8F00, // Amber
    'type': 'income',
  },
  {
    'name': 'Food',
    'icon': '🍔',
    'color_value': 0xFF43A047, // Green
    'type': 'expense',
  },
  {
    'name': 'Transport',
    'icon': '🚗',
    'color_value': 0xFFFDD835, // Dark yellow
    'type': 'expense',
  },
  {
    'name': 'Shopping',
    'icon': '🛍️',
    'color_value': 0xFFEC407A, // Pink
    'type': 'expense',
  },
  {
    'name': 'Bills',
    'icon': '📄',
    'color_value': 0xFF5D4037, // Brown
    'type': 'expense',
  },
  {
    'name': 'Health',
    'icon': '💊',
    'color_value': 0xFF00ACC1, // Cyan
    'type': 'expense',
  },
  {
    'name': 'Entertainment',
    'icon': '🎬',
    'color_value': 0xFFFF5722, // Deep orange
    'type': 'expense',
  },
  {
    'name': 'Education',
    'icon': '📚',
    'color_value': 0xFF283593, // Indigo
    'type': 'expense',
  },
  {
    'name': 'Other',
    'icon': '📦',
    'color_value': 0xFF7E57C2, // Purple
    'type': 'expense',
  },
];
