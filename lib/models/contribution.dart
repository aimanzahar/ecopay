class Contribution {
  final int? id;
  final int userId;
  final int projectId;
  final double amount;
  final String? transactionId;
  final DateTime timestamp;

  Contribution({
    this.id,
    required this.userId,
    required this.projectId,
    required this.amount,
    this.transactionId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'amount': amount,
      'transaction_id': transactionId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      id: map['id'],
      userId: map['user_id'],
      projectId: map['project_id'],
      amount: map['amount'],
      transactionId: map['transaction_id'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}