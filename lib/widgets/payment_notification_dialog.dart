import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction.dart';
import '../models/post.dart';

class PaymentNotificationDialog extends StatefulWidget {
  const PaymentNotificationDialog({
    super.key,
    required this.bankTransferInfo,
    required this.post,
    required this.onConfirm,
  });

  final BankTransferInfo bankTransferInfo;
  final PostItem post;
  final VoidCallback onConfirm;

  static Future<void> show(
    BuildContext context, {
    required BankTransferInfo info,
    required PostItem post,
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentNotificationDialog(
        bankTransferInfo: info,
        post: post,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<PaymentNotificationDialog> createState() => _PaymentNotificationDialogState();
}

class _PaymentNotificationDialogState extends State<PaymentNotificationDialog> {
  bool _showQr = false;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.bankTransferInfo;
    final shipping = info.shippingFee;
    final price = double.tryParse(widget.post.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final total = price + shipping;

    if (_completed) {
      return _buildCompleted(total);
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, 'Thông tin chuyển khoản'),
                  const SizedBox(height: 8),
                  _infoBox('Người bán đã gửi thông tin tài khoản để bạn thanh toán'),
                  const SizedBox(height: 12),
                  _buildProductSection(price, shipping, total),
                  const SizedBox(height: 12),
                  _buildBankInfo(info),
                  if (info.qrImageData != null) ...[
                    const SizedBox(height: 12),
                    _buildQr(info),
                  ],
                  const SizedBox(height: 12),
                  _buildSteps(total),
                  const SizedBox(height: 16),
                  _buildActions(total),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleted(double total) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, '✓ Thanh toán thành công'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Text('Cảm ơn bạn đã thanh toán!',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text('Tổng: ${total.toStringAsFixed(0)} đ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(color: Colors.brown, fontSize: 13)),
    );
  }

  Widget _buildProductSection(double price, double shipping, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sản phẩm',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _priceRow('Tên', widget.post.title),
              _priceRow('Giá', '${price.toStringAsFixed(0)} đ'),
              if (shipping > 0) _priceRow('Vận chuyển', '${shipping.toStringAsFixed(0)} đ'),
              const Divider(),
              _priceRow('Tổng cộng', '${total.toStringAsFixed(0)} đ', isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.brown.shade700, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.brown.shade700, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBankInfo(BankTransferInfo info) {
    Widget row(String label, String value, {bool copyable = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (copyable)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => Clipboard.setData(ClipboardData(text: value)),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thông tin tài khoản',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              row('Ngân hàng', info.bankName),
              row('Số tài khoản', info.accountNumber, copyable: true),
              row('Chủ tài khoản', info.accountHolder),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQr(BankTransferInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mã QR',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              if (_showQr)
                Column(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Image.network(
                          info.qrImageData!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('Không tải được mã QR'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              OutlinedButton(
                onPressed: () => setState(() => _showQr = !_showQr),
                child: Text(_showQr ? 'Ẩn mã QR' : 'Hiển thị mã QR'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSteps(double total) {
    final steps = [
      'Mở ứng dụng ngân hàng / ví điện tử',
      'Chuyển tiền qua QR hoặc nhập số tài khoản',
      'Nhập số tiền: ${total.toStringAsFixed(0)} đ',
      'Xác nhận thanh toán thành công bên dưới',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hướng dẫn thanh toán',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in steps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(s, style: const TextStyle(color: Colors.green)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(double total) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() => _completed = true);
              Future.delayed(const Duration(milliseconds: 600), widget.onConfirm);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('✓ Đã thanh toán'),
          ),
        ),
      ],
    );
  }
}
