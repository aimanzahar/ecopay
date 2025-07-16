class Transaction {
  int? id;
  String transactionId;
  String merchantName;
  double amount;
  double remainingBalance;
  DateTime transactionDate;
  String status; // 'completed', 'failed', 'pending'
  String? notes;

  Transaction({
    this.id,
    required this.transactionId,
    required this.merchantName,
    required this.amount,
    required this.remainingBalance,
    required this.transactionDate,
    this.status = 'completed',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'merchantName': merchantName,
      'amount': amount,
      'remainingBalance': remainingBalance,
      'transactionDate': transactionDate.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      transactionId: map['transactionId'],
      merchantName: map['merchantName'],
      amount: map['amount'],
      remainingBalance: map['remainingBalance'],
      transactionDate: DateTime.parse(map['transactionDate']),
      status: map['status'] ?? 'completed',
      notes: map['notes'],
    );
  }

  // Generate a unique transaction ID
  static String generateTransactionId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$random';
  }

  // Helper method to format transaction date for display
  String getFormattedDate() {
    return '${transactionDate.day.toString().padLeft(2, '0')}/${transactionDate.month.toString().padLeft(2, '0')}/${transactionDate.year}';
  }

  // Helper method to format transaction time for display
  String getFormattedTime() {
    return '${transactionDate.hour.toString().padLeft(2, '0')}:${transactionDate.minute.toString().padLeft(2, '0')}:${transactionDate.second.toString().padLeft(2, '0')}';
  }

  // Helper method to format transaction date and time for display
  String getFormattedDateTime() {
    return '${getFormattedDate()} ${getFormattedTime()}';
  }

  // Helper method to format amount for display
  String getFormattedAmount() {
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  // Helper method to format remaining balance for display
  String getFormattedRemainingBalance() {
    return 'RM ${remainingBalance.toStringAsFixed(2)}';
  }
}