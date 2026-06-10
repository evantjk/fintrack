import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            return TabBarView(
              children: [
                _CategoryList(
                    categories: provider.expenseCategories,
                    type: 'expense'),
                _CategoryList(
                    categories: provider.incomeCategories,
                    type: 'income'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCategoryDialog(context, null),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, Category? category) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<Category> categories;
  final String type;

  const _CategoryList({required this.categories, required this.type});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category_outlined,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No $type categories.',
                style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final cat = categories[i];
        return _CategoryTile(
          category: cat,
          onEdit: () => showDialog(
            context: context,
            builder: (_) => _CategoryDialog(category: cat),
          ),
          onDelete: () => _confirmDelete(context, cat),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Delete "${cat.name}"? Transactions using it will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.expenseColor))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Provider.of<TransactionProvider>(context, listen: false)
          .deleteCategory(cat.id!);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(category.icon,
                style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(category.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        subtitle: Text(
          category.type == 'income' ? 'Income' : 'Expense',
          style: TextStyle(
              color: category.type == 'income'
                  ? AppTheme.incomeColor
                  : AppTheme.expenseColor,
              fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.textMuted),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameCtrl = TextEditingController();
  String _icon = '📦';
  String _type = 'expense';
  int _colorValue = 0xFF9E9E9E;

  final List<String> _icons = [
    '📦', '🍔', '🚗', '🛍️', '📄', '💊', '🎬', '📚',
    '💼', '💻', '📈', '🎁', '🏠', '✈️', '🎓', '💰',
    '🏋️', '🎮', '🐶', '☕',
  ];

  final List<int> _colors = [
    0xFFF44336, 0xFFE91E63, 0xFF9C27B0, 0xFF3F51B5,
    0xFF2196F3, 0xFF00BCD4, 0xFF4CAF50, 0xFF8BC34A,
    0xFFFF9800, 0xFFFF5722, 0xFF607D8B, 0xFF795548,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _icon = widget.category!.icon;
      _type = widget.category!.type;
      _colorValue = widget.category!.colorValue;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Category Name', hintText: 'e.g. Coffee'),
            ),
            const SizedBox(height: 16),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeBtn('Expense', 'expense'),
                const SizedBox(width: 8),
                _TypeBtn('Income', 'income'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons
                  .map((ic) => GestureDetector(
                        onTap: () => setState(() => _icon = ic),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _icon == ic
                                ? AppTheme.primary.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _icon == ic
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                              child: Text(ic,
                                  style: const TextStyle(fontSize: 20))),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _colorValue = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: _colorValue == c
                                ? Border.all(
                                    color: Colors.black, width: 2.5)
                                : null,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  // ignore: non_constant_identifier_names
  Widget _TypeBtn(String label, String value) {
    final isSelected = _type == value;
    final color = value == 'income' ? AppTheme.incomeColor : AppTheme.expenseColor;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? color : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final provider =
        Provider.of<TransactionProvider>(context, listen: false);
    final cat = Category(
      id: widget.category?.id,
      name: _nameCtrl.text.trim(),
      icon: _icon,
      colorValue: _colorValue,
      type: _type,
    );
    if (widget.category == null) {
      provider.addCategory(cat);
    } else {
      provider.updateCategory(cat);
    }
    Navigator.pop(context);
  }
}
