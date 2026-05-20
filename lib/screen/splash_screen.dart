import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/admin/adminhomepage.dart';
import 'package:mie_project/screen/home.dart';
import 'package:mie_project/screen/login.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/app_logger.dart';
import 'package:mie_project/utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _tagSlide;
  late final Animation<double> _tagFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _tagSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _tagFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final minSplashDuration = Future.delayed(const Duration(milliseconds: 1400));
    Widget destination = const LogRegis();
    try {
      await DBHelper.initDb();
      final adminId = await SessionManager.getAdminId();
      if (adminId != null) {
        destination = const Adminhomepage();
      } else {
        final userId = await SessionManager.getUserId();
        if (userId != null) {
          final user = await DBHelper.getUserById(userId);
          if (user != null && user['status'] == 'active') {
            destination = const HomeScreen();
          } else {
            await SessionManager.clear();
          }
        }
      }
    } catch (e, st) {
      AppLogger.error('Splash bootstrap failed', e, st);
    }

    await minSplashDuration;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fade,
                  child: Text(
                    'mie novel',
                    style: GoogleFonts.pacifico(
                      fontSize: 60,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _tagSlide.value),
                      child: Opacity(opacity: _tagFade.value, child: child),
                    );
                  },
                  child: Text(
                    'Your eyes begin the journey.',
                    style: GoogleFonts.prompt(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                FadeTransition(
                  opacity: _tagFade,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
