import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final String? initialType;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialType,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'expense';
  DateTime _date = DateTime.now();
  Category? _selectedCategory;
  bool _isSaving = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.transaction!;
      _titleCtrl.text = tx.title;
      _amountCtrl.text = tx.amount.toStringAsFixed(2);
      _noteCtrl.text = tx.note ?? '';
      _type = tx.type;
      _date = tx.date;
    } else {
      _type = widget.initialType ?? 'expense';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        // Initialize selected category after categories load
        if (_selectedCategory == null && _isEditing) {
          _selectedCategory =
              provider.getCategoryById(widget.transaction!.categoryId);
        }
        final cats = _type == 'income'
            ? provider.incomeCategories
            : provider.expenseCategories;

        // Reset category if it doesn't match current type
        if (_selectedCategory != null &&
            _selectedCategory!.type != _type) {
          _selectedCategory = null;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _confirmDelete,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeToggle(
                    selected: _type,
                    onChanged: (t) => setState(() {
                      _type = t;
                      _selectedCategory = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _label('Title'),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Monthly Salary',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Amount (RM)'),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Amount is required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid positive amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Category'),
                  DropdownButtonFormField<Category>(
                    key: ValueKey(_type),
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      hintText: 'Select category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: cats
                        .map(
                          (c) => DropdownMenuItem<Category>(
                            value: c,
                            child: Row(
                              children: [
                                Text(c.icon,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (c) => setState(() => _selectedCategory = c),
                    validator: (v) =>
                        v == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Date'),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormat('dd MMMM yyyy').format(_date),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Note (optional)'),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _save(provider),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Update Transaction' : 'Save Transaction',
                              style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textDark)),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(TransactionProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final tx = Transaction(
      id: widget.transaction?.id,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      date: _date,
      categoryId: _selectedCategory!.id!,
      type: _type,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (_isEditing) {
      await provider.updateTransaction(tx);
    } else {
      await provider.addTransaction(tx);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.expenseColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider =
          Provider.of<TransactionProvider>(context, listen: false);
      await provider.deleteTransaction(widget.transaction!.id!);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _TypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _Tab('Expense', 'expense', selected, onChanged)),
          Expanded(child: _Tab('Income', 'income', selected, onChanged)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _Tab(this.label, this.value, this.selected, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final color = value == 'income' ? AppTheme.incomeColor : AppTheme.expenseColor;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
