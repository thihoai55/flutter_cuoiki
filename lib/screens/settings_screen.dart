import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/main_layout.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNoti = true;
  bool _emailNoti = false;

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return MainLayoutWithCustomAppBar(
      title: 'Cài đặt',
      showDrawer: true,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Thông báo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text('Nhận thông báo đẩy'),
            subtitle: const Text('Thông báo về tin nhắn, giao dịch, bài viết'),
            value: _pushNoti,
            onChanged: (v) => setState(() => _pushNoti = v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Nhận email'),
            subtitle: const Text('Cập nhật khuyến mãi và tin mới'),
            value: _emailNoti,
            onChanged: (v) => setState(() => _emailNoti = v),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Hiển thị',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          SwitchListTile.adaptive(
            title: const Text('Chế độ tối'),
            subtitle: const Text('Bật để chuyển ngay sang nền tối'),
            value: theme.isDark,
            onChanged: theme.setDark,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu cài đặt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
