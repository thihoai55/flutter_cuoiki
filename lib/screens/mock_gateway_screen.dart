import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Màn hình mô phỏng cổng thanh toán (VNPay/MoMo/QR) cho môi trường không có backend.
/// Yêu cầu người dùng thực hiện vài bước trước khi xác nhận thành công để tránh "bấm là được luôn".
class MockGatewayScreen extends StatefulWidget {
  const MockGatewayScreen({
    super.key,
    required this.amount,
    required this.method,
    required this.description,
    required this.orderId,
  });

  final double amount;
  final String method; // vnpay | momo | qr | wallet
  final String description;
  final String orderId;

  @override
  State<MockGatewayScreen> createState() => _MockGatewayScreenState();
}

class _MockGatewayScreenState extends State<MockGatewayScreen> {
  late final TextEditingController _otpCtrl;
  String? _serverOtp;
  bool _otpRequested = false;
  bool _confirmChecked = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _otpCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _requestOtp() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    setState(() {
      _serverOtp = code;
      _otpRequested = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã OTP mô phỏng: $code'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _complete(bool success) async {
    if (!success) {
      Navigator.of(context).pop(false);
      return;
    }

    if (_serverOtp != null && _otpCtrl.text.trim() != _serverOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập đúng mã OTP mô phỏng để tiếp tục.')),
      );
      return;
    }

    if (!_confirmChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận đã hoàn tất thanh toán.')),
      );
      return;
    }

    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isQR = widget.method.toLowerCase() == 'qr';
    final methodLabel = widget.method.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cổng thanh toán $methodLabel (mô phỏng)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _orderInfo(methodLabel),
            const SizedBox(height: 16),
            if (isQR || widget.method.toLowerCase() == 'vnpay') _qrBlock(methodLabel),
            const SizedBox(height: 16),
            _stepsCard(methodLabel),
            const SizedBox(height: 16),
            _otpCard(methodLabel),
            const SizedBox(height: 16),
            _confirmArea(),
          ],
        ),
      ),
    );
  }

  Widget _orderInfo(String methodLabel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Icon(Icons.shield, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mô phỏng thanh toán an toàn',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(methodLabel, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Mã đơn', widget.orderId),
            const SizedBox(height: 6),
            _infoRow('Số tiền', '${widget.amount.toStringAsFixed(0)} đ'),
            const SizedBox(height: 6),
            _infoRow('Nội dung', widget.description),
          ],
        ),
      ),
    );
  }

  Widget _qrBlock(String methodLabel) {
    final data = 'order=${widget.orderId}&amount=${widget.amount.toStringAsFixed(0)}&method=${widget.method}';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Quét mã $methodLabel', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Dùng app ngân hàng hoặc ví điện tử để quét mã này (mô phỏng).',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _stepsCard(String methodLabel) {
    final steps = [
      'Mở app $methodLabel hoặc ngân hàng.',
      'Quét QR / chọn thẻ và nhập thông tin.',
      'Nhận OTP (mô phỏng) và nhập vào ô bên dưới.',
      'Nhấn "Tôi đã hoàn tất" để xác nhận.',
    ];
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Các bước thực hiện', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (int i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.shade50,
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(steps[i])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _otpCard(String methodLabel) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xác thực OTP $methodLabel (mô phỏng)',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nhập mã OTP 6 số',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 6,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _processing ? null : _requestOtp,
                  child: const Text('Gửi OTP\n(mô phỏng)', textAlign: TextAlign.center),
                ),
              ],
            ),
            if (_otpRequested)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: const [
                    Icon(Icons.info, size: 16, color: Colors.grey),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text('OTP được hiển thị trong thông báo SnackBar để thử luồng xác thực.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _confirmArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: _confirmChecked,
          onChanged: _processing ? null : (v) => setState(() => _confirmChecked = v ?? false),
          title: const Text('Tôi đã hoàn tất thanh toán trên cổng bên ngoài'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _processing ? null : () => _complete(true),
          icon: _processing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle),
          label: Text(_processing ? 'Đang xác nhận...' : 'Tôi đã thanh toán xong'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _processing ? null : () => _complete(false),
          icon: const Icon(Icons.cancel),
          label: const Text('Hủy'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.red.shade200),
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}
