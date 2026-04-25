import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://nxhzoggsxhzjwsolodlh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54aHpvZ2dzeGh6andzb2xvZGxoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwNTU5MjIsImV4cCI6MjA5MjYzMTkyMn0.WAkakYcsh5vAok9FTkP4cQQ94tL5yDZOlzGQaFNtsv0',
  );

  // Transparent status bar for immersive feel
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
          title: 'DayBooster — The Architect Protocol',
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
  bool _loading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final session = data.session;
      if (session?.user != null) {
        _ensureProfileExists(session!.user);
      }
      setState(() {
        _isAuthenticated = session != null;
        _loading = false;
      });
    });
  }

  void _checkAuth() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.user != null) {
      _ensureProfileExists(session!.user);
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
        'architect_name': (name != null && name.isNotEmpty) ? name : null,
        'age': age,
        'phone_number': (phoneNumber != null && phoneNumber.isNotEmpty) ? phoneNumber : null,
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
              const Text('⚡', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: const Color(0xFF00D4FF),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}
