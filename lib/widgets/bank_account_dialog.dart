import 'package:flutter/material.dart';

class BankAccountDialog extends StatefulWidget {
  const BankAccountDialog({
    super.key,
    this.initialBankName,
    this.initialAccountNumber,
    this.initialAccountHolder,
  });

  final String? initialBankName;
  final String? initialAccountNumber;
  final String? initialAccountHolder;

  @override
  State<BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends State<BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with initial values if provided
    _bankNameController.text = widget.initialBankName ?? '';
    _accountNumberController.text = widget.initialAccountNumber ?? '';
    _accountHolderController.text = widget.initialAccountHolder ?? '';
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Nhập thông tin tài khoản',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vui lòng nhập thông tin tài khoản ngân hàng để người mua chuyển tiền:',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên ngân hàng',
                  hintText: 'Ví dụ: Vietcombank, Techcombank...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên ngân hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản',
                  hintText: 'Nhập số tài khoản',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tài khoản';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _accountHolderController,
                decoration: const InputDecoration(
                  labelText: 'Chủ tài khoản',
                  hintText: 'Tên chủ tài khoản',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên chủ tài khoản';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'bankName': _bankNameController.text.trim(),
                'accountNumber': _accountNumberController.text.trim(),
                'accountHolder': _accountHolderController.text.trim(),
              });
            }
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
