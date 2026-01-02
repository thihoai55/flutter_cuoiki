import 'package:flutter/material.dart';

import '../models/transaction.dart';
import 'post_image.dart';

class PurchaseConfirmDialog extends StatefulWidget {
  const PurchaseConfirmDialog({
    super.key,
    required this.postTitle,
    required this.postPrice,
    required this.postImage,
    required this.onConfirm,
    this.initialName,
    this.initialPhone,
    this.initialAddress,
  });

  final String postTitle;
  final String postPrice;
  final String? postImage;
  final ValueChanged<BuyerInfo> onConfirm;
  final String? initialName;
  final String? initialPhone;
  final String? initialAddress;

  static Future<void> show(
    BuildContext context, {
    required String postTitle,
    required String postPrice,
    required String? postImage,
    required ValueChanged<BuyerInfo> onConfirm,
    String? initialName,
    String? initialPhone,
    String? initialAddress,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PurchaseConfirmDialog(
        postTitle: postTitle,
        postPrice: postPrice,
        postImage: postImage,
        onConfirm: onConfirm,
        initialName: initialName,
        initialPhone: initialPhone,
        initialAddress: initialAddress,
      ),
    );
  }

  @override
  State<PurchaseConfirmDialog> createState() => _PurchaseConfirmDialogState();
}

class _PurchaseConfirmDialogState extends State<PurchaseConfirmDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _quantity = 1;
  String _paymentMethod = 'cash_on_delivery';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _nameCtrl.text = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : (widget.initialName ?? '');
    _phoneCtrl.text = _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : (widget.initialPhone ?? '');
    _addressCtrl.text = _addressCtrl.text.isNotEmpty ? _addressCtrl.text : (widget.initialAddress ?? '');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Xác nhận yêu cầu mua',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPostPreview(),
              const SizedBox(height: 16),
              _sectionTitle('Thông tin người mua'),
              _buildText('Tên *', _nameCtrl, 'Nhập tên'),
              _buildText('Số điện thoại *', _phoneCtrl, '0912345678', keyboardType: TextInputType.phone),
              _buildText('Địa chỉ giao hàng *', _addressCtrl, '123 Đường ABC, Quận 1'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Số lượng *'),
                      keyboardType: TextInputType.number,
                      initialValue: '1',
                      onChanged: (v) {
                        final parsed = int.tryParse(v) ?? 1;
                        setState(() => _quantity = parsed < 1 ? 1 : parsed);
                      },
                      validator: (v) {
                        final value = int.tryParse(v ?? '0') ?? 0;
                        if (value < 1) return 'Số lượng phải >= 1';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sectionTitle('Phương thức thanh toán'),
              _radio('Thanh toán sau khi nhận hàng', 'cash_on_delivery'),
              _radio('Thanh toán trước (chuyển khoản)', 'bank_transfer'),
              const SizedBox(height: 12),
              _sectionTitle('Ghi chú thêm'),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Muốn giao buổi sáng... ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
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
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Gửi yêu cầu mua'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
    );
  }

  Widget _buildText(String label, TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
        keyboardType: keyboardType,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập $label' : null,
      ),
    );
  }

  Widget _radio(String label, String value) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      onChanged: (v) => setState(() => _paymentMethod = v ?? value),
      title: Text(label),
      dense: true,
    );
  }

  Widget _buildPostPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
                child: PostImage(
                  url: widget.postImage ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.white70),
                  ),
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.postTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.postPrice, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final info = BuyerInfo(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      quantity: _quantity,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      paymentMethod: _paymentMethod,
    );
    widget.onConfirm(info);
    Navigator.of(context).pop();
  }
}
