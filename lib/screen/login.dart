import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/admin/adminhomepage.dart';
import 'package:mie_project/screen/sign_in.dart';
import 'package:mie_project/screen/home.dart';
import 'package:mie_project/screen/forget_password.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogRegis extends StatefulWidget {
  const LogRegis({super.key});

  @override
  State<LogRegis> createState() => _LogRegisState();
}

class _LogRegisState extends State<LogRegis> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF26A69A)], // Gradient colors
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Logo
                    Text(
                      'mie novel',
                      style: GoogleFonts.pacifico(
                        fontSize: 48, // Reduced font size for better balance
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your eyes begin the journey. This is mie.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Login Form
                    Center(
                      child: Container(
                        width: 320, // Slightly reduced width for better fit
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              controller: usernameController,
                              hint: 'ชื่อผู้ใช้หรืออีเมล',
                              obscureText: false,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: passwordController,
                              hint: 'รหัสผ่าน',
                              obscureText: true,
                              icon: Icons.lock_outline,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Forgetpass(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'ลืมรหัสผ่าน?',
                                  style: TextStyle(
                                    color: Color(0xFF00897B),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () async {
                                final username = usernameController.text.trim();
                                final password = passwordController.text.trim();

                                if (username.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => isLoading = true);

                                try {
                                  // 1. ตรวจสอบ Admin
                                  final admin = await DBHelper.adminLogin(
                                    username,
                                    password,
                                  );

                                  if (!mounted) return;

                                  if (admin != null) {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setInt(
                                      'admin_id',
                                      admin['admin_id'],
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'เข้าสู่ระบบผู้ดูแลสำเร็จ!',
                                        ),
                                      ),
                                    );

                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );

                                    if (!mounted) return;

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Adminhomepage(), // ✅ admin redirect
                                      ),
                                    );
                                    return; // ✅ ป้องกันไม่ให้ไปตรวจสอบ User
                                  }

                                  // 2. ตรวจสอบ User
                                  final user = await DBHelper.loginUser(
                                    username,
                                    password,
                                  );

                                  if (user != null) {
                                    // ⭐️ ส่วนที่เพิ่ม: ตรวจสอบสถานะผู้ใช้
                                    if (user['status'] != 'active') {
                                      String message = 'บัญชีของคุณถูกระงับการใช้งาน';
                                      if (user['status'] == 'banned') {
                                        message = 'บัญชีของคุณถูกแบน ไม่สามารถเข้าสู่ระบบได้';
                                      } 
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return; // ❌ ไม่อนุญาตให้ล็อกอินต่อ
                                    }
                                    // ⭐️ จบส่วนที่เพิ่ม

                                    // 3. สถานะ active: ดำเนินการล็อกอิน
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setInt(
                                      'user_id',
                                      user['user_id'],
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('เข้าสู่ระบบสำเร็จ!'),
                                      ),
                                    );

                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );

                                    if (!mounted) return;

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen(),
                                      ),
                                    );
                                  } else {
                                    // 4. ล็อกอินไม่สำเร็จ (ทั้ง Admin และ User)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print("Login error: $e");
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'เกิดข้อผิดพลาดในการเข้าสู่ระบบ',
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted)
                                    setState(() => isLoading = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00897B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 3,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'เข้าสู่ระบบ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sign Up Link
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: "ยังไม่มีบัญชีใช่หรือไม่ ",
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: 'ลงทะเบียน',
                              style: TextStyle(color: Colors.white),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.roboto(
        color: const Color.fromARGB(255, 89, 89, 89),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          color: const Color.fromARGB(255, 188, 188, 188),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}