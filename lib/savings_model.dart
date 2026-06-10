class SavingsEntry {
  int? id;
  double amount;
  String date;
  String description;
  String type; // 'pemasukan' atau 'pengeluaran'

  SavingsEntry({
    this.id,
    required this.amount,
    required this.date,
    required this.description,
    this.type = 'pemasukan',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'description': description,
      'type': type,
    };
  }

  factory SavingsEntry.fromMap(Map<String, dynamic> map) {
    return SavingsEntry(
      id: map['id'],
      amount: map['amount'],
      date: map['date'],
      description: map['description'],
      type: map['type'] ?? 'pemasukan',
    );
  }
}
