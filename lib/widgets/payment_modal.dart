import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/mock_gateway_screen.dart';

class PaymentModal extends StatefulWidget {
  const PaymentModal({
    super.key,
    required this.packageType,
    required this.packagePrice,
    required this.onPaymentSuccess,
    this.postTitle,
  });

  final String packageType; // basic | premium
  final double packagePrice;
  final VoidCallback onPaymentSuccess;
  final String? postTitle;

  static Future<void> show(
    BuildContext context, {
    required String packageType,
    required double packagePrice,
    required VoidCallback onPaymentSuccess,
    String? postTitle,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentModal(
        packageType: packageType,
        packagePrice: packagePrice,
        onPaymentSuccess: onPaymentSuccess,
        postTitle: postTitle,
      ),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  late String _selectedMethod;
  bool _processing = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final user = auth.currentUser;
    final balance = user != null ? wallet.balanceForUser(user.id) : 0.0;
    _selectedMethod = balance >= widget.packagePrice ? 'balance' : 'vnpay';
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final balance = user != null ? wallet.balanceForUser(user.id) : 0.0;
    final hasEnoughBalance = balance >= widget.packagePrice;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildOrderInfo(balance, hasEnoughBalance),
              const SizedBox(height: 12),
              _buildMethods(hasEnoughBalance),
              const SizedBox(height: 12),
              _buildMethodNote(hasEnoughBalance),
              const SizedBox(height: 12),
              _buildPayButton(wallet, hasEnoughBalance),
              const SizedBox(height: 8),
              _buildSecurityNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.lock, color: Colors.black87, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(height: 2),
              Text('Giao dịch được bảo mật', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        if (!_processing && !_success)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildOrderInfo(double balance, bool hasEnoughBalance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade200, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gói ${widget.packageType == 'basic' ? 'Cơ bản' : 'Premium'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${widget.packagePrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.amber)),
                ],
              ),
              if (widget.postTitle != null) ...[
                const SizedBox(height: 6),
                Text('Bài đăng: ${widget.postTitle}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasEnoughBalance ? Colors.green.shade50 : Colors.red.shade50,
            border: Border.all(
              color: hasEnoughBalance ? Colors.green.shade400 : Colors.red.shade400,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số dư hiện tại', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${balance.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: hasEnoughBalance ? Colors.green.shade700 : Colors.red.shade700,
                      )),
                ],
              ),
              if (!hasEnoughBalance)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Cần thêm ${(widget.packagePrice - balance).clamp(0, double.infinity).toStringAsFixed(0)}đ',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${widget.packagePrice.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.amber)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethods(bool hasEnoughBalance) {
    final methods = [
      _Method(
        id: 'balance',
        name: 'Số dư ví',
        description: 'Thanh toán trực tiếp từ ví trong ứng dụng',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.blue,
        enabled: hasEnoughBalance,
      ),
      _Method(
        id: 'vnpay',
        name: 'VNPay',
        description: 'Thanh toán qua thẻ ngân hàng',
        icon: Icons.credit_card,
        color: const Color(0xFF0052A5),
      ),
      _Method(
        id: 'momo',
        name: 'MoMo',
        description: 'Ví điện tử MoMo',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFFA50064),
      ),
      _Method(
        id: 'qr',
        name: 'QR Code',
        description: 'Quét mã QR để thanh toán',
        icon: Icons.qr_code,
        color: Colors.green,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chọn phương thức thanh toán',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        ...methods.map((m) {
          final selected = _selectedMethod == m.id;
          return GestureDetector(
            onTap: _processing || !m.enabled
                ? null
                : () => setState(() => _selectedMethod = m.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? Colors.amber : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
                color: selected ? Colors.amber.shade50 : Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected ? m.color : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(m.icon, color: selected ? Colors.white : m.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(m.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: m.enabled ? Colors.black87 : Colors.grey,
                                )),
                            if (!m.enabled)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text('(Không đủ số dư)',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(m.description,
                            style: TextStyle(
                              color: m.enabled ? Colors.grey.shade700 : Colors.grey,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                  if (selected) const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMethodNote(bool hasEnoughBalance) {
    String text;
    switch (_selectedMethod) {
      case 'balance':
        text = 'Hệ thống sẽ trừ trực tiếp ${widget.packagePrice.toStringAsFixed(0)}đ từ số dư ví của bạn.';
        break;
      case 'vnpay':
        text = 'Bạn sẽ được chuyển tới cổng VNPay để xác nhận giao dịch. Sau khi thanh toán thành công, gói sẽ được kích hoạt.';
        break;
      case 'momo':
        text = 'Hệ thống hiển thị mã QR / deep-link MoMo để bạn xác nhận. Giao dịch hoàn tất trong vài giây.';
        break;
      default:
        text = 'Quét mã QR bằng ứng dụng ngân hàng/ ví điện tử để thanh toán chính xác số tiền.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 1),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }

  Widget _buildPayButton(WalletProvider wallet, bool hasEnoughBalance) {
    final disabled = _processing || (_selectedMethod == 'balance' && !hasEnoughBalance);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : () => _handlePay(wallet, hasEnoughBalance),
        icon: _processing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.lock_outline),
        label: Text(
          _processing
              ? 'Đang xử lý...'
              : 'Thanh toán ${widget.packagePrice.toStringAsFixed(0)}đ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Future<void> _handlePay(WalletProvider wallet, bool hasEnoughBalance) async {
    if (_selectedMethod == 'balance' && !hasEnoughBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư không đủ, vui lòng nạp thêm.')),
      );
      return;
    }
    setState(() => _processing = true);
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      setState(() => _processing = false);
      return;
    }

    if (_selectedMethod == 'balance') {
      wallet.pay(
        widget.packagePrice,
        description: 'Thanh toán gói ${widget.packageType}',
        userId: user.id,
      );
    } else {
      final orderId = 'PKG${DateTime.now().millisecondsSinceEpoch}';
      final desc = 'Thanh toán gói ${widget.packageType}${widget.postTitle != null ? ' - ${widget.postTitle}' : ''}';

      final paid = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => MockGatewayScreen(
                amount: widget.packagePrice,
                method: _selectedMethod,
                description: desc,
                orderId: orderId,
              ),
            ),
          ) ??
          false;

      if (!mounted) return;
      if (!paid) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán chưa hoàn tất.')),
        );
        return;
      }

      wallet.recordExternalPayment(
        widget.packagePrice,
        description: desc,
        userId: user.id,
        paymentMethod: _selectedMethod.toUpperCase(),
      );
    }

    setState(() {
      _processing = false;
      _success = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    widget.onPaymentSuccess();
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.lock_outline, size: 14, color: Colors.blue),
        SizedBox(width: 6),
        Text('Giao dịch được mã hóa và bảo mật', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
      ],
    );
  }
}

class _Method {
  _Method({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool enabled;
}
