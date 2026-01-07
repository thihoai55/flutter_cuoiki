import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/follow_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/public_home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/post_storage_service.dart';
import 'services/notification_storage_service.dart';
import 'services/chat_storage_service.dart';
import 'services/follow_storage_service.dart';
import 'services/auth_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PostStorageService.init();
  await NotificationStorageService.init();
  await ChatStorageService.init();
  await FollowStorageService.init();
  await AuthStorageService.init(); // ← Khởi tạo auth storage
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => FollowProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          // Initialize notifications on app start
          notifProvider.init();
          
          return Consumer<ThemeProvider>(
            builder: (context, theme, _) {
              final baseLight = ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFFF6F8FB),
                fontFamily: 'Roboto',
              );
              final baseDark = ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A), brightness: Brightness.dark),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            fontFamily: 'Roboto',
          );

          return MaterialApp(
            title: 'Sàn Trao Đổi SV',
            debugShowCheckedModeBanner: false,
            theme: baseLight,
            darkTheme: baseDark,
            themeMode: theme.themeMode,
            home: const RootRouter(),
          );
            },
          );
        },
      ),
    );
  }
}

class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final posts = context.read<PostProvider>();
    await Future.wait([
      auth.tryAutoLogin(),  // ← Tự động đăng nhập nếu có userId đã lưu
      auth.loadUsers(),
      posts.loadPosts(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final auth = context.watch<AuthProvider>();
    if (auth.currentUser == null) {
      return const LoginScreen();
    }
    
    // Route to admin dashboard if user is admin
    if (auth.currentUser?.role == 'admin') {
      return const AdminDashboardScreen();
    }
    
    return const PublicHomeScreen();
  }
}
