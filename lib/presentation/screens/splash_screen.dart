import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../logic/providers/auth_provider.dart';
import '../../data/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        // Check Maintenance Mode
        final settings = await SupabaseService().getAppSettings();
        if (mounted && settings != null) {
          // Check if maintenance mode is enabled or app is not active
          if (settings['is_app_active'] == false) {
            context.go('/maintenance');
            return;
          }
        }

        final authProvider = context.read<AuthProvider>();
        final prefs = await SharedPreferences.getInstance();
        final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

        if (mounted) {
          if (authProvider.isLoggedIn || seenOnboarding) {
            context.go('/home');
          } else {
            context.go('/onboarding');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/images/logo.jpeg',
            width: 250,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
