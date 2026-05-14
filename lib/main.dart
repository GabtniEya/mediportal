import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_controller.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nwhavwgkhyopjuscsodk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53aGF2d2draHlvcGp1c2Nzb2RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxNDkyMjAsImV4cCI6MjA5MjcyNTIyMH0.tSHzMLks9xW25aVpxSCjjTn_XG-m3oTCxFD3ucnROq0',
  );

  runApp(const MediPortalApp());
}

final supabase = Supabase.instance.client;

class MediPortalApp extends StatefulWidget {
  const MediPortalApp({super.key});

  static _MediPortalAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MediPortalAppState>();

  @override
  State<MediPortalApp> createState() => _MediPortalAppState();
}

class _MediPortalAppState extends State<MediPortalApp> {
  bool _isDarkMode = true;

  void toggleTheme(bool value) {
    AppThemeController.setDark(value);
    setState(() => _isDarkMode = value);
  }

  bool get isDarkMode => _isDarkMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediPortal',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Thème clair
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color.fromARGB(255, 0, 0, 0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 2, 42, 15),
          brightness: Brightness.light,
          primary: const Color.fromARGB(255, 0, 14, 6),
          secondary: const Color.fromARGB(255, 2, 15, 5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),

      // Thème sombre
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color.fromARGB(255, 1, 52, 8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 3, 54, 2),
          brightness: Brightness.dark,
          primary: const Color.fromARGB(255, 76, 175, 146),
          secondary: const Color.fromARGB(255, 2, 37, 2),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D2B22),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        useMaterial3: true,
      ),

      home: supabase.auth.currentSession != null
          ? DashboardPage()
          : LoginPage(),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              left: 12,
              bottom: 88,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => toggleTheme(!_isDarkMode),
                    child: Semantics(
                      button: true,
                      label: _isDarkMode ? 'Mode clair' : 'Mode sombre',
                      child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (_isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF132E24))
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (_isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF132E24))
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: Icon(
                            _isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: _isDarkMode
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF132E24),
                            size: 22,
                          ),
                        ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
