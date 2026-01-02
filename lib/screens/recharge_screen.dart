import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_layout.dart';
import 'mock_gateway_screen.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _customAmountCtrl = TextEditingController();
  double? _selectedAmount;
  String _method = 'vnpay';
  bool _processing = false;
  bool _success = false;
  double _lastAmount = 0;

  final _suggested = const [50000.0, 100000.0, 200000.0, 500000.0, 1000000.0];

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final balance = currentUser != null ? wallet.balanceForUser(currentUser.id) : 0.0;
    final total = _selectedAmount ?? double.tryParse(_customAmountCtrl.text) ?? 0;

    return MainLayoutWithCustomAppBar(
      title: 'Nạp tiền',
      showDrawer: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _balanceCard(balance),
            const SizedBox(height: 20),
            _sectionTitle('Chọn số tiền nạp'),
            _amountGrid(total),
            const SizedBox(height: 12),
            _customInput(),
            const SizedBox(height: 20),
            _sectionTitle('Phương thức thanh toán'),
            _methodList(),
            if (total > 0) ...[
              const SizedBox(height: 20),
              _summary(total),
            ],
            const SizedBox(height: 16),
            _submit(wallet, total),
            if (_success) ...[
              const SizedBox(height: 12),
              _successBox(balance, _lastAmount),
            ],
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.account_balance_wallet, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Số dư hiện tại', style: TextStyle(color: Colors.grey)),
              Text('${balance.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16));
  }

  Widget _amountGrid(double total) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggested.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final amount = _suggested[i];
        final selected = _selectedAmount == amount;
        return OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedAmount = amount;
              _customAmountCtrl.clear();
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? Colors.blue.shade50 : Colors.white,
            side: BorderSide(color: selected ? Colors.blue : Colors.grey.shade300, width: selected ? 2 : 1),
          ),
          child: Text('${amount.toStringAsFixed(0)}đ',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.blue : Colors.black,
              )),
        );
      },
    );
  }

  Widget _customInput() {
    return TextField(
      controller: _customAmountCtrl,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Hoặc nhập số tiền (tối thiểu 10,000đ)',
        border: OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() => _selectedAmount = null),
    );
  }

  Widget _methodList() {
    final methods = [
      _Method(id: 'vnpay', name: 'VNPay', description: 'Thanh toán qua thẻ ngân hàng', color: const Color(0xFF0052A5)),
      _Method(id: 'momo', name: 'MoMo', description: 'Ví điện tử MoMo', color: const Color(0xFFA50064)),
      _Method(id: 'qr', name: 'QR Code', description: 'Quét mã QR bằng app ngân hàng', color: Colors.green),
    ];
    return Column(
      children: [
        for (final m in methods)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: _processing ? null : () => setState(() => _method = m.id),
              leading: CircleAvatar(backgroundColor: m.color.withOpacity(0.12), child: Icon(Icons.payment, color: m.color)),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(m.description),
              trailing: Radio<String>(
                value: m.id,
                groupValue: _method,
                onChanged: _processing ? null : (v) => setState(() => _method = v ?? m.id),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _method == m.id ? m.color : Colors.grey.shade300, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _summary(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.credit_card, color: Colors.blue),
              SizedBox(width: 8),
              Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Text('${total.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _submit(WalletProvider wallet, double total) {
    final disabled = _processing || total <= 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : () => _handleRecharge(wallet, total),
        icon: _processing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.lock),
        label: Text(_processing ? 'Đang xử lý...' : 'Nạp ${total.toStringAsFixed(0)}đ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _successBox(double balance, double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nạp tiền thành công!',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 6),
          Text('Bạn đã nạp ${amount.toStringAsFixed(0)}đ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Số dư mới: ${balance.toStringAsFixed(0)}đ'),
        ],
      ),
    );
  }

  Future<void> _handleRecharge(WalletProvider wallet, double total) async {
    if (total < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền nạp tối thiểu 10,000đ')),
      );
      return;
    }
    setState(() => _processing = true);
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      setState(() => _processing = false);
      return;
    }

    final orderId = 'RC${DateTime.now().millisecondsSinceEpoch}';
    final description = 'Nạp ví qua ${_method.toUpperCase()}';

    final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => MockGatewayScreen(
              amount: total,
              method: _method,
              description: description,
              orderId: orderId,
            ),
          ),
        ) ??
        false;

    if (!mounted) return;
    setState(() => _processing = false);

    if (!paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán chưa hoàn tất.')),
      );
      return;
    }

    final ok = wallet.recharge(total, paymentMethod: _method.toUpperCase(), userId: currentUser.id);
    setState(() {
      _success = ok;
      _lastAmount = ok ? total : 0;
      if (ok) {
        _selectedAmount = null;
        _customAmountCtrl.clear();
      }
    });
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra, thử lại.')),
      );
    }
  }
}

class _Method {
  _Method({required this.id, required this.name, required this.description, required this.color});
  final String id;
  final String name;
  final String description;
  final Color color;
}
