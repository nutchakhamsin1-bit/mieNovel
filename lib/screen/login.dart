import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/admin/adminhomepage.dart';
import 'package:mie_project/screen/forget_password.dart';
import 'package:mie_project/screen/home.dart';
import 'package:mie_project/screen/sign_in.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/app_logger.dart';
import 'package:mie_project/utils/session_manager.dart';

class LogRegis extends StatefulWidget {
  const LogRegis({super.key});

  @override
  State<LogRegis> createState() => _LogRegisState();
}

class _LogRegisState extends State<LogRegis> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final admin = await DBHelper.adminLogin(username, password);
      if (!mounted) return;
      if (admin != null) {
        await SessionManager.saveAdminId(admin['admin_id'] as int);
        if (!mounted) return;
        _showSnack('เข้าสู่ระบบผู้ดูแลสำเร็จ');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Adminhomepage()),
        );
        return;
      }

      final user = await DBHelper.loginUser(username, password);
      if (!mounted) return;
      if (user == null) {
        _showSnack('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง', error: true);
        return;
      }

      final status = user['status'];
      if (status != 'active') {
        final message = status == 'banned'
            ? 'บัญชีของคุณถูกแบน ไม่สามารถเข้าสู่ระบบได้'
            : 'บัญชีของคุณถูกระงับการใช้งาน';
        _showSnack(message, error: true);
        return;
      }

      await SessionManager.saveUserId(user['user_id'] as int);
      if (!mounted) return;
      _showSnack('เข้าสู่ระบบสำเร็จ');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e, st) {
      AppLogger.error('Login failed', e, st);
      _showSnack('เกิดข้อผิดพลาดในการเข้าสู่ระบบ', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'mie novel',
                    style: GoogleFonts.pacifico(
                      fontSize: 56,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your eyes begin the journey.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: 360,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: AppDecorations.card(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'เข้าสู่ระบบ',
                            style: GoogleFonts.sarabun(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'ชื่อผู้ใช้หรืออีเมล',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกชื่อผู้ใช้หรืออีเมล'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'รหัสผ่าน',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'กรุณากรอกรหัสผ่าน'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Forgetpass(),
                                ),
                              ),
                              child: const Text('ลืมรหัสผ่าน?'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('เข้าสู่ระบบ'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text.rich(
                      TextSpan(
                        text: 'ยังไม่มีบัญชี? ',
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: 'ลงทะเบียน',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
