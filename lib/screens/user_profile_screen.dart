import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/follow_provider.dart';
import 'post_detail_screen.dart';
import 'chat_screen.dart';
import 'edit_post_screen.dart';
import 'followers_following_screen.dart';
import 'view_ratings_screen.dart';
import '../widgets/main_layout.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.user,
    this.initialTab,
  });

  final AppUser user;
  final String? initialTab;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _postFilter = 'selling';
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _postFilter = widget.initialTab!;
    }
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final auth = context.read<AuthProvider>();
    final followProvider = context.read<FollowProvider>();
    final currentUser = auth.currentUser;
    
    if (currentUser != null && currentUser.id != widget.user.id) {
      final following = await followProvider.isFollowing(currentUser.id, widget.user.id);
      setState(() {
        _isFollowing = following;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthProvider>();
    final followProvider = context.read<FollowProvider>();
    final currentUser = auth.currentUser;
    
    if (currentUser == null) return;

    await followProvider.toggleFollow(
      userId: currentUser.id,
      targetId: widget.user.id,
      userName: currentUser.name,
      userAvatar: currentUser.avatar,
    );

    setState(() {
      _isFollowing = !_isFollowing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing
            ? 'Đã theo dõi ${widget.user.name}'
            : 'Đã hủy theo dõi ${widget.user.name}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();
    final followProvider = context.watch<FollowProvider>();
    final currentUser = auth.currentUser;
    final isOwnProfile = currentUser?.id == widget.user.id;

    final allUserPosts = postProvider.posts.where((p) => p.authorId == widget.user.id).toList();
    
    final filteredPosts = allUserPosts.where((p) {
      if (_postFilter == 'selling') return !p.sold && !p.hidden && p.status == 'approved';
      if (_postFilter == 'pending') return p.status == 'pending';
      if (_postFilter == 'sold') return p.sold;
      if (_postFilter == 'hidden') return p.hidden;
      return true;
    }).toList();

    final followers = followProvider.getFollowers(widget.user.id);
    final following = followProvider.getFollowing(widget.user.id);

    return MainLayoutWithCustomAppBar(
      title: 'Trang cá nhân',
      showDrawer: true,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.user.avatar != null
                        ? NetworkImage(widget.user.avatar!)
                        : null,
                    child: widget.user.avatar == null
                        ? Text(
                            widget.user.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (widget.user.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.user.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  
                  // Rating
                  if (widget.user.rating > 0) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewRatingsScreen(user: widget.user),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < widget.user.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.user.rating.toStringAsFixed(1)} (${widget.user.ratingCount} đánh giá)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Stats
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('Bài đăng', '${allUserPosts.length}'),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersFollowingScreen(
                                userId: widget.user.id,
                                initialTab: 0, // Mở tab Người theo dõi
                              ),
                            ),
                          );
                        },
                        child: _buildStat('Người theo dõi', '${followers.length}'),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersFollowingScreen(
                                userId: widget.user.id,
                                initialTab: 1, // Mở tab Đang theo dõi
                              ),
                            ),
                          );
                        },
                        child: _buildStat('Đang theo dõi', '${following.length}'),
                      ),
                    ],
                  ),

                  // Action buttons
                  if (!isOwnProfile) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleFollow,
                            icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                            label: Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? Colors.grey[300]
                                  : const Color(0xFF2563EB),
                              foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: widget.user.id,
                                    otherUserName: widget.user.name,
                                    otherUserAvatar: widget.user.avatar,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('Nhắn tin'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Post filter tabs
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterTab('Đang bán', 'selling'),
                  _buildFilterTab('Chờ duyệt', 'pending'),
                  _buildFilterTab('Đã bán', 'sold'),
                  if (isOwnProfile) _buildFilterTab('Đã ẩn', 'hidden'),
                ],
              ),
            ),

            // Posts grid
            const SizedBox(height: 16),
            filteredPosts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Chưa có bài đăng nào',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return _buildPostCard(post, isOwnProfile);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _postFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _postFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(post, bool isOwnProfile) {
    final postProvider = context.read<PostProvider>();
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: post.id),
          ),
        );
      },
      child: Container(
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
            // Image với menu 3 chấm
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: post.images.isNotEmpty
                        ? Image.network(
                            post.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                  ),
                ),
                // Menu 3 chấm chỉ hiển thị nếu là chủ bài đăng
                if (isOwnProfile)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPostScreen(post: post),
                            ),
                          );
                        } else if (value == 'hide') {
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
                          if (confirm == true) {
                            await postProvider.toggleHidePost(post.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(post.hidden ? 'Đã hiện bài đăng' : 'Đã ẩn bài đăng')),
                              );
                            }
                          }
                        } else if (value == 'unhide') {
                          await postProvider.toggleHidePost(post.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã đăng lại bài đăng')),
                            );
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
                          if (confirm == true) {
                            await postProvider.deletePost(post.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã xóa bài đăng')),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) {
                        // Tùy thuộc vào tab hiện tại (dựa vào trạng thái post)
                        if (post.hidden) {
                          // Tab "Đã ẩn": Đăng lại, Xóa
                          return [
                            const PopupMenuItem(
                              value: 'unhide',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 12),
                                  Text('Đăng lại'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Xóa', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ];
                        } else if (post.sold) {
                          // Tab "Đã bán": chỉ Xóa
                          return [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Xóa', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ];
                        } else {
                          // Tab "Đang bán": Sửa, Ẩn, Xóa
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
                            const PopupMenuItem(
                              value: 'hide',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_off, size: 20),
                                  SizedBox(width: 12),
                                  Text('Ẩn bài đăng'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text('Xóa', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ];
                        }
                      },
                    ),
                  ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      post.price,
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
  }
}
