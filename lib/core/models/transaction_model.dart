class TransactionModel {
  int? id;
  double amount;
  int categoryId;
  String description;
  DateTime date;
  String type; // 'income' or 'expense'

  TransactionModel({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      type: map['type'],
    );
  }
}
