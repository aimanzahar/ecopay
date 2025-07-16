class Balance {
  int? id;
  double amount;
  DateTime lastUpdated;

  Balance({this.id, required this.amount, required this.lastUpdated});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Balance.fromMap(Map<String, dynamic> map) {
    return Balance(
      id: map['id'],
      amount: map['amount'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
