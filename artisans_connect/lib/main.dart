import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'screens/artisan_dashboard_screen.dart';
import 'screens/artisan_detail_screen.dart';
import 'screens/artisan_list_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/phone_input_screen.dart';
import 'screens/home_screen.dart';
import 'screens/messaging_screen.dart';
import 'screens/my_realisations_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ArtisansConnectApp());
}

class ArtisansConnectApp extends StatelessWidget {
  const ArtisansConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artisans Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.authPhone: (_) => const PhoneInputScreen(),
        AppRoutes.authOtp: (_) => const OtpVerificationScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.artisanList: (_) => const ArtisanListScreen(),
        AppRoutes.artisanDetail: (_) => const ArtisanDetailScreen(),
        AppRoutes.messaging: (_) => const MessagingScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.myRealisations: (_) => const MyRealisationsScreen(),
        AppRoutes.artisanDashboard: (_) => const ArtisanDashboardScreen(),
      },
    );
  }
}
