import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/stats_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await AdService.instance.init();
  await StatsService.instance.init();

  runApp(const MathVibeApp());
}

class MathVibeApp extends StatelessWidget {
  const MathVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        // Keep status bar icons in sync with theme
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: mode == ThemeMode.dark
                ? AppTheme.background
                : AppTheme.lightBackground,
            systemNavigationBarIconBrightness:
                mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
          ),
        );
        return MaterialApp(
          title: 'The Math Vibe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
