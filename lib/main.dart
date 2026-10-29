import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/ui.dart';
import 'screens/auth.dart';
import 'screens/home.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.restore();
  runApp(const CatCheckApp());
  await Session.instance.restore();
}

class CatCheckApp extends StatelessWidget {
  const CatCheckApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ThemeController.instance,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roll call',
      themeMode: ThemeController.instance.mode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
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
        return Navigator(
          key: ValueKey(
            '${s.loading}:${s.user?['id']}:${s.user?['role']}:${s.error}',
          ),
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => target),
        );
      },
    );
  }
}
