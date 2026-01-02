class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balance,
    required this.status,
    required this.description,
    required this.timestamp,
    required this.userId,
    this.paymentMethod,
  });

  final String id;
  final String type; // recharge | payment | refund
  final double amount;
  final double balance;
  final String status; // success | failed
  final String description;
  final DateTime timestamp;
  final String userId; // User who made this transaction
  final String? paymentMethod;
}
