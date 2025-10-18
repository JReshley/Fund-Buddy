import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fund_buddy/pages/opening_page.dart';
import 'package:fund_buddy/pages/widgets/reset_password_page.dart';
import 'package:fund_buddy/pages/widgets/theme_toggle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SupabaseConfig.init();
  await themeController.loadTheme();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    // Listen for links when app is running
    _sub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) {
        debugPrint("Deep link error: $err");
      },
    );

    // Handle cold start
    final initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint("Received deep link: $uri");

    try {
      // Convert fragment (#...) to query params (needed for Supabase recovery links)
      Uri finalUri = uri;
      if (uri.fragment.isNotEmpty && !uri.toString().contains("access_token")) {
        finalUri = Uri.parse("${uri.scheme}://${uri.host}?${uri.fragment}");
      }

      // Restore Supabase session
      final response = await Supabase.instance.client.auth.getSessionFromUrl(
        finalUri,
      );
      if (response.session != null) {
        debugPrint("Supabase session restored from deep link");
      } else {
        debugPrint("No session found in deep link");
      }

      // Now safely navigate AFTER the frame is built
      if (finalUri.scheme == "fundbuddy" && finalUri.host == "reset-password") {
        debugPrint("Navigating to ResetPasswordPage...");
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => ResetPasswordPage(themeController: themeController,
                                      onThemeChanged: () {
                                        setState(() {});
                                      },)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Failed to handle deep link: $e");
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FundBuddy',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: themeController.backgroundColor,
        primaryColor: const Color(0xFF64B5F6),
      ),
      home: OpeningPage(onThemeChanged: refresh),
    );
  }
}
