import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

// The form used to add a new transaction or edit an existing one.
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
  // Pre-fills the form with existing values when editing.
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
  // Builds the form: type toggle, amount, title, category, date, and note.
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        // Initialize selected category after categories load
        if (_selectedCategory == null && _isEditing) {
          _selectedCategory = provider.getCategoryById(
            widget.transaction!.categoryId,
          );
        }
        final cats = _type == 'income'
            ? provider.incomeCategories
            : provider.expenseCategories;

        // Reset category if it doesn't match current type
        if (_selectedCategory != null && _selectedCategory!.type != _type) {
          _selectedCategory = null;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'EDIT' : 'ADD'),
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
                  const SizedBox(height: 20),
                  _AmountField(
                    controller: _amountCtrl,
                    color: _type == 'income'
                        ? PixelColors.of(context).income
                        : PixelColors.of(context).expense,
                    pixel: PixelColors.of(context).hardShadow,
                  ),
                  const SizedBox(height: 24),
                  _label('Title'),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Monthly Salary',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Title is required'
                        : null,
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
                                Text(
                                  c.icon,
                                  style: const TextStyle(fontSize: 18),
                                ),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isEditing ? 'UPDATE' : 'SAVE'),
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

  // Small heading shown above a field.
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, color: PixelColors.of(context).textDark),
    ),
  );

  // Opens the date picker and stores the chosen date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // Validates the form, then saves the new or edited transaction and closes.
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

  // Asks the user to confirm, then deletes the transaction.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: PixelColors.of(context).expense),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      await provider.deleteTransaction(widget.transaction!.id!);
      if (mounted) Navigator.pop(context);
    }
  }
}

// The income / expense switch at the top of the form.
class _TypeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: p.radius == 0 ? null : BorderRadius.circular(14),
        border: p.box(p.outline, 2),
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

// One side (income or expense) of the type switch.
class _Tab extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;

  const _Tab(this.label, this.value, this.selected, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final isSelected = value == selected;
    final color = value == 'income' ? p.income : p.expense;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: p.radius == 0 ? null : BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : p.textMuted,
            fontSize: p.hardShadow ? 9 : 13,
          ),
        ),
      ),
    );
  }
}

/// Large focal amount input, tinted to the selected type's colour. Replaces the
/// small inline amount field so the most important value is the visual anchor.
// The money input field with the RM prefix.
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final bool pixel;

  const _AmountField({
    required this.controller,
    required this.color,
    required this.pixel,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Column(
      children: [
        Text(
          'AMOUNT',
          style: TextStyle(fontSize: 8, letterSpacing: 1.5, color: p.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'RM',
                style: TextStyle(
                  fontSize: pixel ? 14 : 20,
                  color: color,
                  fontWeight: pixel ? null : FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: pixel ? 22 : 34,
                  color: color,
                  fontWeight: pixel ? null : FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  errorMaxLines: 2,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: color.withValues(alpha: 0.4), thickness: pixel ? 2 : 1),
      ],
    );
  }
}
