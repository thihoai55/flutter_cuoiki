import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart';
import '../models/post.dart';
import '../widgets/main_layout.dart';
import 'order_tracking_screen.dart';
import '../widgets/post_image.dart';

class BankTransferScreen extends StatefulWidget {
  const BankTransferScreen({
    super.key,
    required this.transaction,
    required this.sellerInfo,
    this.post,
  });

  final PurchaseTransaction transaction;
  final Map<String, String> sellerInfo; // {bankName, accountNumber, accountHolder}
  final PostItem? post;

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _processing = false;
  String _paymentMethod = 'wallet'; // wallet, momo, vnpay

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _processing = true);

    try {
      // Simulate transfer processing
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      final amount = double.parse(_amountCtrl.text);
      final note = _noteCtrl.text.isNotEmpty ? _noteCtrl.text : 'Chuyển khoản ngân hàng';
      
      // Process payment based on selected method
      if (_paymentMethod == 'wallet') {
        final walletProvider = context.read<WalletProvider>();
        final auth = context.read<AuthProvider>();
        final currentUser = auth.currentUser;
        
        if (currentUser == null) return;
        
        // Deduct from buyer
        final success = walletProvider.pay(amount, description: note, userId: currentUser.id);
        
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Số dư không đủ!')),
          );
          setState(() => _processing = false);
          return;
        }
        
        // Add to seller
        walletProvider.addToBalance(
          widget.transaction.sellerId,
          amount,
          'Nhận thanh toán từ ${currentUser.name}',
        );
      } else {
        // Simulate external payment (Momo/VNPay)
        // In real app, this would redirect to payment gateway
        await Future.delayed(const Duration(seconds: 1));
        
          // For external payment, still log buyer transaction and add to seller's wallet
        final walletProvider = context.read<WalletProvider>();
        final auth = context.read<AuthProvider>();
        final currentUser = auth.currentUser;
        if (currentUser != null) {
            walletProvider.recordExternalPayment(
              amount,
              description: note,
              userId: currentUser.id,
              paymentMethod: _paymentMethod.toUpperCase(),
            );
          walletProvider.addToBalance(
            widget.transaction.sellerId,
            amount,
            'Nhận thanh toán từ ${currentUser.name} (${_paymentMethod.toUpperCase()})',
          );
        }
      }

      // Update transaction status to 'shipping' (auto start shipping)
      final postProvider = context.read<PostProvider>();
      postProvider.updateTransactionStatus(widget.transaction.id, 'shipping');
      
      // Mark post as sold
      postProvider.markPostAsSold(widget.transaction.postId);

      // Send notification to seller
      final notifProvider = context.read<NotificationProvider>();
      final auth = context.read<AuthProvider>();
      final buyer = auth.currentUser;
      
      if (buyer != null) {
        notifProvider.addNotification(
          userId: widget.transaction.sellerId,
          type: 'order_shipping',
          message: '${buyer.name} đã thanh toán ${amount.toStringAsFixed(0)}đ và đơn hàng đang được giao.',
          postId: widget.transaction.postId,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanh toán thành công! Đơn hàng đang được giao.'),
          duration: Duration(seconds: 3),
        ),
      );

      // Điều hướng tới màn hình theo dõi đơn hàng
      PurchaseTransaction trackingTx;
      try {
        trackingTx = postProvider.transactions.firstWhere((t) => t.id == widget.transaction.id);
      } catch (_) {
        trackingTx = widget.transaction;
        trackingTx.status = 'shipping';
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(transaction: trackingTx),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return MainLayoutWithCustomAppBar(
      title: 'Chuyển khoản ngân hàng',
      showDrawer: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seller info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin người bán',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Ngân hàng:', widget.sellerInfo['bankName'] ?? ''),
                    const SizedBox(height: 8),
                    _buildInfoRow('Số tài khoản:', widget.sellerInfo['accountNumber'] ?? ''),
                    const SizedBox(height: 8),
                    _buildInfoRow('Chủ tài khoản:', widget.sellerInfo['accountHolder'] ?? ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transaction details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiết giao dịch',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (widget.post != null) ...[
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PostImage(
                              url: widget.post!.image ?? (widget.post!.images.isNotEmpty ? widget.post!.images.first : ''),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 30, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post!.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.post!.price,
                                  style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                    ],
                    _buildInfoRow('Người mua:', widget.transaction.buyerName),
                    const SizedBox(height: 8),
                    _buildInfoRow('Người bán:', widget.transaction.sellerName),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Transfer form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
                      ),
                      prefixIcon: const Icon(Icons.payment),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'wallet', child: Text('Trừ từ số dư tài khoản')),
                      DropdownMenuItem(value: 'momo', child: Text('Momo')),
                      DropdownMenuItem(value: 'vnpay', child: Text('VNPay')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paymentMethod = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nhập số tiền chuyển',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền (đ)',
                      hintText: 'Nhập số tiền cần chuyển',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      try {
                        double.parse(value);
                        return null;
                      } catch (e) {
                        return 'Số tiền không hợp lệ';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ghi chú chuyển khoản',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú (tuỳ chọn)',
                      hintText: 'Nhập nội dung chuyển khoản',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _processing ? null : _confirmTransfer,
                    icon: const Icon(Icons.check_circle),
                    label: Text(_processing ? 'Đang xử lý...' : 'Xác nhận chuyển khoản'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
