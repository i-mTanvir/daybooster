import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/data/offline_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/first_launch_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppTheme.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://nxhzoggsxhzjwsolodlh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54aHpvZ2dzeGh6andzb2xvZGxoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwNTU5MjIsImV4cCI6MjA5MjYzMTkyMn0.WAkakYcsh5vAok9FTkP4cQQ94tL5yDZOlzGQaFNtsv0',
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DayBoosterApp());
}

class DayBoosterApp extends StatelessWidget {
  const DayBoosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeType>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, themeType, _) {
        return MaterialApp(
          title: 'Day Booster',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getThemeData(themeType),
          home: const AppRouter(),
        );
      },
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  static const _splashSeenKey = 'first_launch_splash_seen_v1';

  bool _loading = true;
  bool _isAuthenticated = false;
  bool _showFirstLaunchSplash = false;

  @override
  void initState() {
    super.initState();
    _initBoot();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final session = data.session;
      if (session?.user != null) {
        _ensureProfileExists(session!.user);
        unawaited(OfflineSyncService.instance.initForUser(session.user.id));
      } else {
        unawaited(OfflineSyncService.instance.stop());
      }
      setState(() {
        _isAuthenticated = session != null;
        _loading = false;
      });
    });
  }

  Future<void> _initBoot() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_splashSeenKey) ?? false;
    _checkAuth();
    if (!mounted) return;
    setState(() {
      _showFirstLaunchSplash = !seen;
    });
  }

  void _checkAuth() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.user != null) {
      _ensureProfileExists(session!.user);
      unawaited(OfflineSyncService.instance.initForUser(session.user.id));
    }
    setState(() {
      _isAuthenticated = session != null;
      _loading = false;
    });
  }

  Future<void> _ensureProfileExists(User user) async {
    try {
      final metadata = user.userMetadata ?? {};
      final name = (metadata['name'] as String?)?.trim();
      final age = (metadata['age'] as num?)?.toInt();
      final phoneNumber = (metadata['phone_number'] as String?)?.trim();

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'architect_name':
            (name != null && name.isNotEmpty) ? name : null,
        'age': age,
        'phone_number':
            (phoneNumber != null && phoneNumber.isNotEmpty) ? phoneNumber : null,
      });
    } catch (_) {
      // Keep auth flow non-blocking if profile sync fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, size: 48, color: Color(0xFF00D4FF)),
              const SizedBox(height: 16),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFF00D4FF),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showFirstLaunchSplash) {
      return FirstLaunchSplashScreen(
        onFinish: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_splashSeenKey, true);
          if (!mounted) return;
          setState(() => _showFirstLaunchSplash = false);
        },
      );
    }

    if (_isAuthenticated) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}
