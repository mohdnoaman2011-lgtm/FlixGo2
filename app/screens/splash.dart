import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final s = context.read<AppState>();
    while (!s.ready) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const Shell()));
  }

  @override
  Widget build(BuildContext context) {
    const grey = Color(0xFF5B6270);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/flixgo-logo.png', width: 260, height: 260),
            const SizedBox(height: 8),
            const Text('فيديو وصوت من منصات التواصل بضغطة واحدة',
                style: TextStyle(color: grey, fontSize: 15)),
            const SizedBox(height: 48),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: Color(0xFF0560FF),
                backgroundColor: Color(0xFFE6E8EE),
                minHeight: 6,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('الإصدار 1.0', style: TextStyle(color: grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
