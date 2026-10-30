import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/ui.dart';
import 'core/theme_reveal.dart';
import 'core/preferences.dart';
import 'core/biometrics.dart';
import 'core/avatar.dart';
import 'screens/auth.dart';
import 'screens/home.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.instance.restore();
  await ThemeController.instance.restore();
  runApp(const CatCheckApp());
  await Session.instance.restore();
  final userId = Session.instance.user?['id'] as String?;
  if (userId != null) {
    await AvatarStore.instance.recover(userId).catchError((_) {});
  }
}

class CatCheckApp extends StatelessWidget {
  const CatCheckApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      ThemeController.instance,
      AppPreferences.instance,
    ]),
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roll call',
      themeMode: ThemeController.instance.mode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(1) *
                AppPreferences.instance.textScale,
          ),
        ),
        child: ThemeReveal(child: child ?? const SizedBox.shrink()),
      ),
      home: const AppRoot(),
    ),
  );
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool ready = false;
  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => ready = true);
        },
      );
    }
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final s = Session.instance;
        final Widget target = s.loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : s.error != null
            ? Scaffold(
                body: Center(
                  child: Empty('Chưa kết nối được', s.error!, retry: s.restore),
                ),
              )
            : s.user == null
            ? const AuthScreen()
            : const HomeScreen();
        final navigator = Navigator(
          key: ValueKey(
            '${s.loading}:${s.user?['id']}:${s.user?['role']}:${s.error}',
          ),
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => target),
        );
        return s.user == null
            ? navigator
            : BiometricGate(
                key: ValueKey(s.user!['id']),
                userId: s.user!['id'],
                child: navigator,
              );
      },
    );
  }
}
