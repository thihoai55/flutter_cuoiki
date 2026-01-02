import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import 'post_detail_screen.dart';
import '../widgets/main_layout.dart';
import '../widgets/post_image.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final postProvider = context.watch<PostProvider>();
    
    if (currentUser == null) {
      return const MainLayoutWithCustomAppBar(
        title: 'Bài đăng đã lưu',
        showDrawer: true,
        child: Center(child: Text('Vui lòng đăng nhập để xem bài đăng đã lưu')),
      );
    }
    
    // Filter saved posts by current user
    final savedPosts = postProvider.savedPostsForUser(currentUser.id)
        .where((post) => postProvider.isPostSavedByUser(post.id, currentUser.id))
        .toList();

    return MainLayoutWithCustomAppBar(
      title: 'Bài đăng đã lưu',
      showDrawer: true,
      child: savedPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài đăng nào được lưu',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 920;
                final isTablet = constraints.maxWidth >= 640;
                final crossAxisCount = isWide
                    ? 3
                    : (isTablet ? 2 : 1); // 1 cột trên màn nhỏ để tránh tràn
                const padding = 16.0;
                const spacing = 14.0;
                final tileWidth =
                    (constraints.maxWidth - padding * 2 - spacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                final tileHeight = tileWidth * (isWide ? 1.1 : 1.4);

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: tileHeight,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: savedPosts.length,
                  itemBuilder: (context, index) {
                    final post = savedPosts[index];
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: post.images.isNotEmpty
                                    ? PostImage(
                                        url: post.images.first,
                                        fit: BoxFit.cover,
                                        placeholder: Container(
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
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    post.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    post.price,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite, size: 13, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${post.likes}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.visibility, size: 13, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${post.views}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
