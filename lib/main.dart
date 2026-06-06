import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/beranda/providers/beranda_provider.dart';
import 'features/akademik/providers/akademik_provider.dart';
import 'features/keuangan/providers/keuangan_provider.dart';
import 'features/cbt/providers/cbt_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/auth/screens/splash_screen.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const CbtApp());
}

class CbtApp extends StatelessWidget {
  const CbtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BerandaProvider()),
        ChangeNotifierProvider(create: (_) => AkademikProvider()),
        ChangeNotifierProvider(create: (_) => KeuanganProvider()),
        ChangeNotifierProvider(create: (_) => CbtProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'CBT & Sistem Informasi',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2F58E5), // Primary Blue from design
            brightness: Brightness.light,
            primary: const Color(0xFF2F58E5),
            secondary: const Color(0xFF1E293B),
            surface: const Color(0xFFF8FAFC),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF1E293B)),
            titleTextStyle: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF2F58E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
