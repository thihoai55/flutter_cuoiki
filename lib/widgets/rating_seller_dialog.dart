import 'package:flutter/material.dart';

class RatingSellerDialog extends StatefulWidget {
  const RatingSellerDialog({
    super.key,
    required this.sellerName,
    this.sellerAvatar,
    required this.onSubmit,
  });

  final String sellerName;
  final String? sellerAvatar;
  final void Function(double rating, String review) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String sellerName,
    String? sellerAvatar,
    required void Function(double rating, String review) onSubmit,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingSellerDialog(
        sellerName: sellerName,
        sellerAvatar: sellerAvatar,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RatingSellerDialog> createState() => _RatingSellerDialogState();
}

class _RatingSellerDialogState extends State<RatingSellerDialog> {
  double _rating = 5;
  final _reviewCtrl = TextEditingController();

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Đánh giá người bán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: widget.sellerAvatar != null && widget.sellerAvatar!.isNotEmpty
                      ? NetworkImage(widget.sellerAvatar!)
                      : null,
                  child: widget.sellerAvatar == null || widget.sellerAvatar!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Chia sẻ trải nghiệm của bạn', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final filled = _rating >= star;
                      return IconButton(
                        onPressed: () => setState(() => _rating = star.toDouble()),
                        icon: Icon(
                          Icons.star,
                          size: 32,
                          color: filled ? Colors.amber : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Chia sẻ trải nghiệm của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Gửi đánh giá'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    final review = _reviewCtrl.text.trim();
    if (review.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đánh giá.')),
      );
      return;
    }
    widget.onSubmit(_rating, review);
    Navigator.of(context).pop();
  }
}
