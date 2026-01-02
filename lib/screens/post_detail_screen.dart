import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import 'user_profile_screen.dart';
import 'chat_screen.dart';
import 'edit_post_screen.dart';
import '../widgets/purchase_confirm_dialog.dart';
import '../providers/notification_provider.dart';
import '../widgets/main_layout.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  late PageController _pageController;
  int _currentImageIndex = 0;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostProvider>();
      provider.incrementView(widget.postId);
      provider.loadComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    final post = postProvider.posts.firstWhere(
      (p) => p.id == widget.postId,
      orElse: () => PostItem(
        id: 'notfound',
        title: 'Không tìm thấy',
        content: '',
        category: 'Khác',
        type: 'sell',
        price: '',
        authorId: '',
        authorName: '',
      ),
    );

    if (post.id == 'notfound') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Không tìm thấy'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Bài đăng không tồn tại')),
      );
    }

    final isLiked = currentUser != null && post.likedBy.contains(currentUser.id);
    final isSaved = currentUser != null && post.savedBy.contains(currentUser.id);
    final comments = postProvider.commentsOf(widget.postId);
    final relatedPosts = postProvider.posts
        .where((p) =>
            p.id != post.id &&
            p.category == post.category &&
            p.type == post.type)
        .take(6)
        .toList();

    return MainLayoutWithCustomAppBar(
      title: 'Chi tiết',
      showDrawer: true,
      actions: [
        if (currentUser != null && currentUser.id == post.authorId)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPostScreen(post: post),
                  ),
                );
              } else if (value == 'hide' || value == 'unhide') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận'),
                    content: Text('Bạn có chắc chắn muốn ${post.hidden ? 'hiện' : 'ẩn'} bài đăng này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(post.hidden ? 'Hiện' : 'Ẩn'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await postProvider.toggleHidePost(post.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(post.hidden ? 'Đã hiện bài đăng' : 'Đã ẩn bài đăng')),
                    );
                  }
                }
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận xóa'),
                    content: const Text('Bạn có chắc chắn muốn xóa bài đăng này? Hành động này không thể hoàn tác.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await postProvider.deletePost(post.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa bài đăng')),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) {
              if (post.hidden) {
                return const [
                  PopupMenuItem(
                    value: 'unhide',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 12),
                        Text('Đăng lại'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Xóa bài đăng', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              } else if (post.sold) {
                return const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Xóa bài đăng', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              } else {
                return [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hide',
                    child: Row(
                      children: [
                        Icon(post.hidden ? Icons.visibility : Icons.visibility_off, size: 20),
                        const SizedBox(width: 12),
                        Text(post.hidden ? 'Hiện bài đăng' : 'Ẩn bài đăng'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Xóa bài đăng', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              }
            },
          )
        else
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              if (currentUser != null) {
                postProvider.toggleSave(post.id, currentUser.id);
              }
            },
          ),
      ],
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSlider(post),
                const SizedBox(height: 16),
                _buildAuthorSection(post, context),
                const SizedBox(height: 16),
                _buildContentSection(post),
                const SizedBox(height: 16),
                _buildActionBar(post, isLiked, currentUser, postProvider, comments.length),
                const Divider(height: 1),
                if (_showComments) _buildCommentSection(comments, post, currentUser, postProvider),
                const SizedBox(height: 16),
                if (relatedPosts.isNotEmpty) _buildRelatedPosts(relatedPosts),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (currentUser != null && currentUser.id != post.authorId)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomActionBar(post, currentUser, authProvider),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSlider(PostItem post) {
    final images = post.images.isNotEmpty ? post.images : [post.image ?? 'https://via.placeholder.com/800x600'];

    return Container(
      height: 400,
      color: Colors.black,
      child: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                ),
              );
            },
          ),

          // Category tag (top left)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Price tag (bottom left)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                post.price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Navigation arrows (if multiple images)
          if (images.length > 1) ...[
            // Previous arrow
            if (_currentImageIndex > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 40, color: Colors.white),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            // Next arrow
            if (_currentImageIndex < images.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 40, color: Colors.white),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
          ],

          // Image indicators (dots)
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthorSection(PostItem post, BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final authProvider = context.read<AuthProvider>();
              final user = await authProvider.getUserById(post.authorId);
              if (user != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(user: user),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF2563EB),
              backgroundImage: post.authorAvatar != null
                  ? NetworkImage(post.authorAvatar!)
                  : null,
              child: post.authorAvatar == null
                  ? Text(
                      post.authorName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (post.condition != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Text(
                post.condition!,
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentSection(PostItem post) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (post.location != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  post.location!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (post.contact != null)
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  post.contact!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(PostItem post, bool isLiked, AppUser? currentUser, PostProvider postProvider, int commentCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Like button
          InkWell(
            onTap: () {
              if (currentUser != null) {
                postProvider.toggleLike(
                  post.id,
                  currentUser.id,
                  currentUser.name,
                  currentUser.avatar,
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: isLiked ? Colors.red : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Comment button
          InkWell(
            onTap: () {
              setState(() => _showComments = !_showComments);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bình luận ($commentCount)',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Share button
          InkWell(
            onTap: () => _sharePost(post),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.share_outlined, color: Colors.grey[600], size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'Chia sẻ',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(List<dynamic> comments, PostItem post, AppUser? currentUser, PostProvider postProvider) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bình luận',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Comment input
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2563EB),
                    backgroundImage: currentUser.avatar != null
                        ? NetworkImage(currentUser.avatar!)
                        : null,
                    child: currentUser.avatar == null
                        ? Text(
                            currentUser.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
                    onPressed: () => _submitComment(post, currentUser, postProvider),
                  ),
                ],
              ),
            ),

          // Comments list with scroll
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: comments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Chưa có bình luận nào',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF2563EB),
                              backgroundImage: comment.authorAvatar != null
                                  ? NetworkImage(comment.authorAvatar!)
                                  : null,
                              child: comment.authorAvatar == null
                                  ? Text(
                                      comment.authorName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.authorName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.content,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRelatedPosts(List<PostItem> relatedPosts) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bài đăng liên quan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedPosts.length,
              itemBuilder: (context, index) {
                final relatedPost = relatedPosts[index];
                final imageUrl = relatedPost.images.isNotEmpty
                    ? relatedPost.images.first
                    : relatedPost.image ?? 'https://via.placeholder.com/300x400';

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(postId: relatedPost.id),
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            imageUrl,
                            height: 160,
                            width: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  relatedPost.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  relatedPost.price,
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment(PostItem post, AppUser currentUser, PostProvider postProvider) {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    postProvider.addComment(
      postId: post.id,
      authorId: currentUser.id,
      authorName: currentUser.name,
      authorAvatar: currentUser.avatar,
      content: text,
    );

    // Gửi thông báo tới người đăng bài nếu không phải người comment
    if (post.authorId != currentUser.id) {
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.addNotification(
        userId: post.authorId,
        type: 'comment',
        message: '${currentUser.name} đã bình luận bài: ${post.title}',
        postId: post.id,
      );
    }

    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _sharePost(PostItem post) {
    // Copy link to clipboard
    Clipboard.setData(ClipboardData(text: 'Chia sẻ: ${post.title} - ${post.price}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép liên kết bài đăng'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBottomActionBar(PostItem post, AppUser currentUser, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nhắn tin button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final author = await authProvider.getUserById(post.authorId);
                if (author != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: author.id,
                        otherUserName: author.name,
                        otherUserAvatar: author.avatar,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Nhắn tin'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF2563EB)),
                foregroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Mua ngay button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showBuyNowDialog(post, currentUser),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Mua ngay'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBuyNowDialog(PostItem post, AppUser currentUser) async {
    await PurchaseConfirmDialog.show(
      context,
      postTitle: post.title,
      postPrice: post.price,
      postImage: post.image,
      initialName: currentUser.name,
      initialPhone: currentUser.phone,
      initialAddress: currentUser.address,
      onConfirm: (buyerInfo) {
        // Tạo giao dịch mua và thông báo đến người bán
        final postProvider = context.read<PostProvider>();
        final notifProvider = context.read<NotificationProvider>();
        final tx = PurchaseTransaction(
          id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
          postId: post.id,
          sellerId: post.authorId,
          sellerName: post.authorName,
          buyerId: currentUser.id,
          buyerName: currentUser.name,
          timestamp: DateTime.now(),
          status: buyerInfo.paymentMethod == 'bank_transfer' ? 'awaiting_payment' : 'pending',
          buyerInfo: buyerInfo,
          sellerAvatar: post.authorAvatar,
          buyerAvatar: currentUser.avatar,
        );
        postProvider.addTransaction(tx);

        // Gửi thông báo tới người bán
        notifProvider.addNotification(
          userId: post.authorId,
          type: 'transaction',
          message: '${currentUser.name} đã gửi yêu cầu mua bài: ${post.title}',
          postId: post.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu mua hàng!')),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
