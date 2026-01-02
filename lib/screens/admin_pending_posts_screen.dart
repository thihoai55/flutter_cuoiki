import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/main_layout.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/post.dart';

class AdminPendingPostsScreen extends StatelessWidget {
  const AdminPendingPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    // Only allow admins
    if (user?.role != 'admin') {
      return const MainLayoutWithCustomAppBar(
        showDrawer: true,
        title: 'Duyệt bài đăng',
        child: Center(
          child: Text('Chức năng này chỉ dành cho quản trị viên.'),
        ),
      );
    }

    return Consumer<PostProvider>(
      builder: (context, postProvider, _) {
        final pending = postProvider.posts
            .where((p) => (p.status ?? 'pending') == 'pending')
            .toList();

        return MainLayoutWithCustomAppBar(
          showDrawer: true,
          title: 'Duyệt bài đăng (${pending.length})',
          child: pending.isEmpty
              ? const Center(child: Text('Không có bài chờ duyệt'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final post = pending[index];
                    return _PostApprovalCard(post: post);
                  },
                ),
        );
      },
    );
  }
}

class _PostApprovalCard extends StatelessWidget {
  const _PostApprovalCard({required this.post});
  final PostItem post;

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.read<NotificationProvider>();
    final postProvider = context.read<PostProvider>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.image!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${post.category} • ${post.type == 'sell' ? 'Đăng bán' : 'Cần mua'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (post.packageType != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: post.packageType == 'premium'
                                    ? const Color(0xFFFFF3E0)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Gói: ${post.packageType}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: post.packageType == 'premium'
                                      ? const Color(0xFFF57C00)
                                      : const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            post.price,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await _confirmDialog(
                        context,
                        title: 'Duyệt bài đăng',
                        message: 'Bạn có chắc muốn duyệt bài này?',
                      );
                      if (confirmed != true) return;
                      await postProvider.approvePost(post.id, notifProvider);
                    },
                    icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                    label: const Text('Duyệt'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final reason = await _showRejectionModal(context);
                      if (reason == null || reason.isEmpty) return;
                      await postProvider.rejectPost(
                        post.id,
                        reason: reason,
                        notificationProvider: notifProvider,
                      );
                    },
                    icon: const Icon(Icons.cancel, color: Color(0xFFDC2626)),
                    label: const Text('Từ chối'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDialog(BuildContext context, {required String title, required String message}) {
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

  Future<String?> _showRejectionModal(BuildContext context) {
    final reasonCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lý do từ chối'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập lý do từ chối bài đăng này...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}
