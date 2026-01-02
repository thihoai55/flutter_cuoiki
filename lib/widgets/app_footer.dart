import 'package:flutter/material.dart';

class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  late Map<String, bool> _hoveredLinks;
  late Map<String, bool> _hoveredSocial;

  @override
  void initState() {
    super.initState();
    _hoveredLinks = {};
    _hoveredSocial = {};
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: isMobile ? 24 : 48,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(top: BorderSide(color: Color(0xFF374151), width: 1)),
      ),
      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Column
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sàn Trao Đổi SV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 250,
                    child: Text(
                      'Nền tảng trao đổi an toàn, minh bạch cho sinh viên. Mua bán, chia sẻ và giao lưu với cộng đồng.',
                      style: TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Links Column
            Expanded(
              flex: 1,
              child: _buildLinksColumn(
                'Công ty',
                ['Về chúng tôi', 'Quy tắc cộng đồng', 'Hướng dẫn sử dụng', 'Sự kiện'],
              ),
            ),
            // Support Column
            Expanded(
              flex: 1,
              child: _buildLinksColumn(
                'Hỗ trợ',
                ['Liên hệ chúng tôi', 'Chính sách bảo mật', 'Điều khoản sử dụng', 'Báo cáo vi phạm'],
              ),
            ),
            // Social Column
            Expanded(
              flex: 1,
              child: _buildSocialColumn(),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFF374151), height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '© 2024 Sàn Trao Đổi SV. Tất cả quyền được bảo lưu.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
            Row(
              children: [
                _buildFooterLink('Chính sách bảo mật'),
                const SizedBox(width: 24),
                _buildFooterLink('Điều khoản sử dụng'),
                const SizedBox(width: 24),
                _buildFooterLink('Tuyên bố về cookie'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.store, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sàn Trao Đổi SV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Nền tảng trao đổi an toàn, minh bạch cho sinh viên. Mua bán, chia sẻ và giao lưu với cộng đồng.',
          style: TextStyle(
            color: Color(0xFFD1D5DB),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        // Links
        _buildMobileLinksSection('Công ty', ['Về chúng tôi', 'Quy tắc cộng đồng', 'Hướng dẫn sử dụng', 'Sự kiện']),
        _buildMobileLinksSection('Hỗ trợ', ['Liên hệ chúng tôi', 'Chính sách bảo mật', 'Điều khoản sử dụng', 'Báo cáo vi phạm']),
        const SizedBox(height: 24),
        // Social
        const Text(
          'Kết nối với chúng tôi',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildSocialIcons(),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFF374151), height: 1),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '© 2024 Sàn Trao Đổi SV.\nTất cả quyền được bảo lưu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) {
          final key = '$title-$link';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredLinks[key] = true),
              onExit: (_) => setState(() => _hoveredLinks[key] = false),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _hoveredLinks[key] ?? false ? Color(0xFF60A5FA) : Color(0xFFD1D5DB),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                child: Text(link),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSocialColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kết nối',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildSocialIcons(),
      ],
    );
  }

  Widget _buildSocialIcons() {
    final socials = [
      ('facebook', Icons.facebook),
      ('instagram', Icons.photo_camera),
      ('tiktok', Icons.videocam),
      ('twitter', Icons.alternate_email),
      ('telegram', Icons.chat),
      ('youtube', Icons.play_circle_outline),
      ('linkedin', Icons.mail_outline),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: socials.map((social) {
        final key = 'social-${social.$1}';
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredSocial[key] = true),
          onExit: (_) => setState(() => _hoveredSocial[key] = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hoveredSocial[key] ?? false ? Color(0xFF3B82F6) : Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hoveredSocial[key] ?? false ? Color(0xFF60A5FA) : Color(0xFF374151),
                width: 1,
              ),
            ),
            child: Icon(
              social.$2,
              color: _hoveredSocial[key] ?? false ? Colors.white : Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileLinksSection(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...links.map((link) {
          final key = '$title-$link';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: GestureDetector(
              onTap: () {},
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _hoveredLinks[key] ?? false ? Color(0xFF60A5FA) : Color(0xFFD1D5DB),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                child: Text(link),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    final key = 'footer-$text';
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredLinks[key] = true),
      onExit: (_) => setState(() => _hoveredLinks[key] = false),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: _hoveredLinks[key] ?? false ? Color(0xFF60A5FA) : Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        child: Text(text),
      ),
    );
  }
}
