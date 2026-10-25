import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/main_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'auth_provider.dart';
import 'auth_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _proceed();
  }

  Future<void> _proceed() async {
    final auth = context.read<AuthProvider>();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    while (!auth.ready) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => auth.hasSession ? const MainShell() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.soft,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/images/logo.png', width: 96, height: 96),
            ),
            const SizedBox(height: 20),
            const Text('GreenCart', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.dark)),
            const SizedBox(height: 6),
            Text('Dari Petani untuk Dapurmu', style: AppText.body.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      );
}
