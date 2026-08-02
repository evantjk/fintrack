// One money record: either income or an expense the user added.
class Transaction {
  /// Firestore document id. Null for a transaction that hasn't been saved yet.
  final String? id;
  final String title;        // short name shown in the list
  final double amount;       // how much money
  final DateTime date;       // when it happened
  final String categoryId;   // which category it belongs to
  final String type;         // 'income' or 'expense'
  final String? note;        // optional extra text

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
    this.note,
  });

  // Returns a copy of this transaction with only the given fields changed.
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? type,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }

  /// Document fields only — the id is the Firestore document id, stored
  /// separately, so it is never part of the map.
  // Turns this transaction into a map to send to the backend.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'type': type,
      'note': note,
    };
  }

  // Builds a transaction from map data that came back from the backend.
  factory Transaction.fromMap(String id, Map<String, dynamic> map) {
    return Transaction(
      id: id,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as String,
      type: map['type'] as String,
      note: map['note'] as String?,
    );
  }
}
