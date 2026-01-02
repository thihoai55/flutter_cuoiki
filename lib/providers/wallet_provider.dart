import 'package:flutter/material.dart';
import '../models/wallet_transaction.dart';

class WalletProvider extends ChangeNotifier {
  // Map userId -> balance
  final Map<String, double> _balances = {};
  final List<WalletTransaction> _transactions = [];

  // Get balance for specific user
  double balanceForUser(String userId) => _balances[userId] ?? 0.0;
  
  // Backward compatibility - get balance for current context
  double get balance => 0.0; // Deprecated, use balanceForUser(userId)
  
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  
  // Get transactions for specific user
  List<WalletTransaction> transactionsForUser(String userId) {
    return _transactions.where((tx) => tx.userId == userId).toList();
  }

  bool recharge(double amount, {String paymentMethod = 'VNPay', required String userId}) {
    if (amount <= 0) return false;
    
    // Update balance for this user
    final currentBalance = _balances[userId] ?? 0.0;
    final newBalance = currentBalance + amount;
    _balances[userId] = newBalance;
    
    final tx = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'recharge',
      amount: amount,
      balance: newBalance,
      status: 'success',
      description: 'Nạp ${amount.toStringAsFixed(0)} đ qua $paymentMethod',
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      userId: userId,
    );
    _transactions.insert(0, tx);
    notifyListeners();
    return true;
  }

  bool pay(double amount, {String description = 'Thanh toán', required String userId}) {
    final currentBalance = _balances[userId] ?? 0.0;
    if (amount <= 0 || currentBalance < amount) return false;
    
    // Deduct from payer
    final newBalance = currentBalance - amount;
    _balances[userId] = newBalance;
    
    final tx = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'payment',
      amount: -amount,
      balance: newBalance,
      status: 'success',
      description: description,
      timestamp: DateTime.now(),
      userId: userId,
    );
    _transactions.insert(0, tx);
    notifyListeners();
    return true;
  }

  /// Ghi nhận thanh toán bằng phương thức ngoài ví (không trừ số dư)
  void recordExternalPayment(
    double amount, {
    String description = 'Thanh toán',
    required String userId,
    String paymentMethod = 'external',
  }) {
    if (amount <= 0) return;

    final currentBalance = _balances[userId] ?? 0.0;
    final tx = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'payment',
      amount: -amount,
      balance: currentBalance,
      status: 'success',
      description: description,
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
      userId: userId,
    );
    _transactions.insert(0, tx);
    notifyListeners();
  }
  
  // Add money to receiver (seller receiving payment)
  void addToBalance(String userId, double amount, String description) {
    if (amount <= 0) return;
    
    final currentBalance = _balances[userId] ?? 0.0;
    final newBalance = currentBalance + amount;
    _balances[userId] = newBalance;
    
    final tx = WalletTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'receive',
      amount: amount,
      balance: newBalance,
      status: 'success',
      description: description,
      timestamp: DateTime.now(),
      userId: userId,
    );
    _transactions.insert(0, tx);
    notifyListeners();
  }
}
