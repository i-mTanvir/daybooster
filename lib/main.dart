import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/user_storage.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
  bool _onboarded = false;
  String _architectName = '';

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final onboarded = await UserStorage.isOnboarded();
    final name = await UserStorage.getArchitectName();
    setState(() {
      _onboarded = onboarded;
      _architectName = name ?? '';
      _loading = false;
    });
  }

  void _onOnboardingComplete() async {
    final name = await UserStorage.getArchitectName();
    setState(() {
      _onboarded = true;
      _architectName = name ?? '';
    });
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

    if (!_onboarded) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    return MainShell(architectName: _architectName);
  }
}

