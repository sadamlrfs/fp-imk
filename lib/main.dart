import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'context/app_context.dart';
import 'context/theme_controller.dart';
import 'services/translation_service.dart';
import 'services/speech_service.dart';
import 'utils/app_colors.dart';
import 'utils/router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppContext()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        Provider(
          create: (_) => TranslationService()..ensureModelsReady(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider(
          create: (_) => SpeechService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: const IMKApp(),
    ),
  );
}

class IMKApp extends StatefulWidget {
  const IMKApp({super.key});

  @override
  State<IMKApp> createState() => _IMKAppState();
}

class _IMKAppState extends State<IMKApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supabase = Supabase.instance.client;
      // Already logged in at startup
      if (supabase.auth.currentUser != null) {
        context.read<AppContext>().loadData();
      }
      // Listen for sign-in events (Google OAuth callback, etc.)
      supabase.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        if (data.event == AuthChangeEvent.signedIn) {
          context.read<AppContext>().loadData();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    return MaterialApp.router(
      title: 'IMK Translate',
      debugShowCheckedModeBanner: false,
      themeMode: themeCtrl.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A56DB)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
      builder: (context, child) {
        // Honour the chosen text size globally, and tint the letterbox to
        // match the active brightness so dark mode reads as truly dark.
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // Keep AppColors (used by every screen) in sync with the resolved
        // brightness — covers Terang/Gelap/Sistem.
        AppColors.isDark = isDark;
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: themeCtrl.textScale,
          maxScaleFactor: themeCtrl.textScale,
          child: Container(
            color: isDark ? Colors.black : Colors.grey[400],
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child!,
            ),
          ),
        );
      },
    );
  }
}
