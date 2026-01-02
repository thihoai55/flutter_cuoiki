import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../models/wallet_transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    
    // Filter transactions for current user only
    final userTransactions = currentUser != null 
        ? wallet.transactionsForUser(currentUser.id) 
        : <WalletTransaction>[];
    final transactions = _filtered(userTransactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
      ),
      body: Column(
        children: [
          _filterTabs(userTransactions),
          Expanded(
            child: transactions.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (_, i) => _TransactionTile(tx: transactions[i]),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: transactions.length,
                  ),
          ),
        ],
      ),
    );
  }

  List<WalletTransaction> _filtered(List<WalletTransaction> list) {
    if (_filter == 'all') return List.of(list);
    return list.where((t) => t.type == _filter).toList();
  }

  Widget _filterTabs(List<WalletTransaction> all) {
    int count(String type) => all.where((t) => t.type == type).length;
    Widget tab(String key, String label) {
      final active = _filter == key;
      return Expanded(
        child: TextButton(
          onPressed: () => setState(() => _filter = key),
          style: TextButton.styleFrom(
            backgroundColor: active ? Colors.blue : Colors.grey.shade200,
            foregroundColor: active ? Colors.white : Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          tab('all', 'Tất cả (${all.length})'),
          const SizedBox(width: 8),
          tab('recharge', 'Nạp tiền (${count('recharge')})'),
          const SizedBox(width: 8),
          tab('payment', 'Thanh toán (${count('payment')})'),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 56, color: Colors.grey),
          SizedBox(height: 8),
          Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isRecharge = tx.type == 'recharge';
    final isSuccess = tx.status == 'success';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRecharge ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isRecharge ? Colors.green.shade200 : Colors.blue.shade200),
            ),
            child: Icon(isRecharge ? Icons.arrow_downward : Icons.arrow_upward,
                color: isRecharge ? Colors.green : Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(tx.description,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    Icon(isSuccess ? Icons.check_circle : Icons.cancel,
                        color: isSuccess ? Colors.green : Colors.red, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (tx.paymentMethod != null) ...[
                      Icon(Icons.credit_card, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(tx.paymentMethod!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _fmt(tx.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.amount >= 0 ? '+' : ''}${tx.amount.toStringAsFixed(0)}đ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isRecharge ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text('Số dư: ${tx.balance.toStringAsFixed(0)}đ',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
