import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../routes/app_routes.dart';
import '../services/storage/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SecureStorageService _secureStorageService = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await _secureStorageService.readToken();
    final role = await _secureStorageService.readRole();

    if (!mounted) return;

    if (token != null && role != null) {
      _navigate(role);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.authPhone, (route) => false);
    }
  }

  void _navigate(UserRole role) {
    final target = role == UserRole.artisan ? AppRoutes.artisanDashboard : AppRoutes.home;
    Navigator.of(context).pushNamedAndRemoveUntil(target, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
