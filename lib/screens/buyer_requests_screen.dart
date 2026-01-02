import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../models/transaction.dart';
import '../models/post.dart';
import '../widgets/main_layout.dart';
import '../widgets/bank_account_dialog.dart';
import 'order_tracking_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/post_image.dart';
import '../widgets/avatar_image.dart';

class BuyerRequestsScreen extends StatefulWidget {
  const BuyerRequestsScreen({super.key});

  @override
  State<BuyerRequestsScreen> createState() => _BuyerRequestsScreenState();
}

class _BuyerRequestsScreenState extends State<BuyerRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const MainLayoutWithCustomAppBar(
        title: 'Thông tin người mua',
        showDrawer: true,
        child: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    final allRequests = postProvider.transactionsFor(user.id);
    
    // Tab 1: Yêu cầu mua (pending, approved, awaiting_payment, payment_confirmed)
    final pendingRequests = allRequests.where((tx) => 
      tx.status == 'pending' || 
      tx.status == 'approved' || 
      tx.status == 'awaiting_payment' ||
      tx.status == 'payment_confirmed'
    ).toList();
    
    // Tab 2: Lịch sử (shipping, completed, cancelled after payment)
    final historyRequests = allRequests.where((tx) => 
      tx.status == 'shipping' || 
      tx.status == 'completed' || 
      (tx.status == 'cancelled' && allRequests.any((t) => 
        t.id == tx.id && 
        (t.status == 'payment_confirmed' || t.status == 'shipping')
      ))
    ).toList();

    return MainLayoutWithCustomAppBar(
      title: 'Thông tin người mua',
      showDrawer: true,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2563EB),
              tabs: const [
                Tab(text: 'Yêu cầu mua'),
                Tab(text: 'Lịch sử mua hàng'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Yêu cầu mua
                pendingRequests.isEmpty
                    ? const _EmptyView(message: 'Chưa có yêu cầu mua nào')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: pendingRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _RequestTile(
                          tx: pendingRequests[i],
                          post: postProvider.postById(pendingRequests[i].postId),
                        ),
                      ),
                
                // Tab 2: Lịch sử
                historyRequests.isEmpty
                    ? const _EmptyView(message: 'Chưa có lịch sử mua hàng')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: historyRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _RequestTile(
                          tx: historyRequests[i],
                          post: postProvider.postById(historyRequests[i].postId),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({this.message = 'Chưa có yêu cầu nào'});
  
  final String message;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.tx, required this.post});
  final PurchaseTransaction tx;
  final PostItem? post;

  Future<void> _openBuyerProfile(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final buyer = await auth.getUserById(tx.buyerId);
    if (buyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin người mua')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(user: buyer)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methodLabel = tx.buyerInfo.paymentMethod == 'bank_transfer'
        ? 'Chuyển khoản'
        : 'Thanh toán khi nhận';

    return GestureDetector(
      onTap: () {
        // Navigate to order tracking screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(transaction: tx),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openBuyerProfile(context),
              child: Row(
                children: [
                  AvatarImage(
                    url: tx.buyerAvatar,
                    size: 44,
                    initials: tx.buyerName[0].toUpperCase(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.buyerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(_fmt(tx.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  _StatusBadge(status: tx.status),
                ],
              ),
            ),
            const SizedBox(height: 10),
          if (post != null)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: PostImage(
                    url: post!.image ?? (post!.images.isNotEmpty ? post!.images.first : ''),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(post!.price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(tx.buyerInfo.address)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.call, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(tx.buyerInfo.phone),
              const SizedBox(width: 12),
              const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(methodLabel),
            ],
          ),
          if (tx.cancelReason != null) ...[
            const SizedBox(height: 6),
            Text('Lý do hủy: ${tx.cancelReason}', style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 10),
          _ActionButtons(tx: tx),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.tx});
  final PurchaseTransaction tx;

  @override
  Widget build(BuildContext context) {
    final postProvider = context.read<PostProvider>();

    List<Widget> buttons = [];
    if (tx.status == 'pending' || tx.status == 'awaiting_payment') {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              // Check if payment method is bank_transfer
              if (tx.buyerInfo.paymentMethod == 'bank_transfer') {
                final auth = context.read<AuthProvider>();
                final seller = auth.currentUser;
                
                // Always show dialog, but pre-fill with seller's bank info if available
                String? bankName = seller?.bankName;
                String? bankAccount = seller?.bankAccount;
                String? accountHolder = seller?.accountHolder;
                
                // Show bank account dialog with pre-filled values
                final bankInfo = await showDialog<Map<String, String>>(
                  context: context,
                  builder: (_) => BankAccountDialog(
                    initialBankName: bankName,
                    initialAccountNumber: bankAccount,
                    initialAccountHolder: accountHolder,
                  ),
                );
                
                if (bankInfo == null) return; // User cancelled
                
                // Update transaction and send notification with bank info
                postProvider.updateTransactionStatus(tx.id, 'approved');
                
                final notifProvider = context.read<NotificationProvider>();
                if (seller != null) {
                  notifProvider.addNotification(
                    userId: tx.buyerId,
                    type: 'bank_transfer_info',
                    message: 'Người bán đã chấp nhận yêu cầu mua của bạn.\n\n'
                        'Thông tin chuyển khoản:\n'
                        'Ngân hàng: ${bankInfo['bankName']}\n'
                        'Số TK: ${bankInfo['accountNumber']}\n'
                        'Chủ TK: ${bankInfo['accountHolder']}\n\n'
                        'TransactionID: ${tx.id}',
                    postId: tx.postId,
                  );
                }
              } else {
                // COD (Cash On Delivery): skip payment, go directly to shipping
                final ok = await _confirm(context, 'Xác nhận yêu cầu', 'Xác nhận bán cho người mua này? Đơn hàng sẽ chuyển sang trạng thái giao hàng.');
                if (ok == true) {
                  // For COD: approve + immediately start shipping
                  postProvider.updateTransactionStatus(tx.id, 'shipping');
                  
                  // Mark post as sold
                  postProvider.markPostAsSold(tx.postId);
                  
                  final notifProvider = context.read<NotificationProvider>();
                  final auth = context.read<AuthProvider>();
                  final seller = auth.currentUser;
                  
                  if (seller != null) {
                    notifProvider.addNotification(
                      userId: tx.buyerId,
                      type: 'purchase_approved',
                      message: 'Yêu cầu mua của bạn đã được chấp nhận! Hàng sẽ được giao sớm.',
                      postId: tx.postId,
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            label: const Text('Xác nhận'),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await _confirm(context, 'Hủy yêu cầu', 'Bạn có chắc muốn hủy yêu cầu này?');
              if (ok == true) {
                postProvider.updateTransactionStatus(tx.id, 'cancelled');
              }
            },
            icon: const Icon(Icons.cancel, color: Color(0xFFDC2626)),
            label: const Text('Hủy'),
          ),
        ),
      );
    } else if (tx.status == 'approved') {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await _confirm(context, 'Hoàn tất giao dịch', 'Đánh dấu giao dịch đã hoàn tất?');
              if (ok == true) {
                postProvider.updateTransactionStatus(tx.id, 'completed');
                
                // Gửi thông báo thanh toán tới buyer
                final notifProvider = context.read<NotificationProvider>();
                final auth = context.read<AuthProvider>();
                final seller = auth.currentUser;
                
                if (seller != null) {
                  notifProvider.addNotification(
                    userId: tx.buyerId,
                    type: 'payment',
                    message: 'Giao dịch với ${seller.name} đã hoàn tất. Cảm ơn bạn đã mua hàng!',
                    postId: tx.postId,
                  );
                }
              }
            },
            icon: const Icon(Icons.check, color: Color(0xFF16A34A)),
            label: const Text('Hoàn tất'),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(children: buttons);
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'awaiting_payment':
        color = Colors.orange;
        label = 'Chờ thanh toán';
        break;
      case 'pending':
        color = Colors.blue;
        label = 'Đã gửi yêu cầu';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Đã xác nhận';
        break;
      case 'completed':
        color = Colors.green.shade700;
        label = 'Hoàn tất';
        break;
      case 'cancelled':
      default:
        color = Colors.red;
        label = 'Đã hủy';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
