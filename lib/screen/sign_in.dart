import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mie_project/screen/ai_recommend.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/app_logger.dart';
import 'package:mie_project/utils/security.dart';
import 'package:mie_project/utils/session_manager.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  DateTime? _selectedDate;
  dynamic _profileImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => _profileImage = bytes);
    } else {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      _showSnack('กรุณาเลือกวันเกิด', error: true);
      return;
    }

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();

    setState(() => _isLoading = true);
    try {
      final exists =
          await DBHelper.userExists(username: username, email: email);
      if (!mounted) return;
      if (exists) {
        _showSnack('ชื่อผู้ใช้หรืออีเมลนี้ถูกใช้แล้ว', error: true);
        return;
      }

      final imagePath = _profileImage is File
          ? (_profileImage as File).path
          : '';

      final userId = await DBHelper.signIn(
        email,
        _passwordController.text,
        username,
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _selectedDate!.toIso8601String(),
        imagePath,
      );

      if (!mounted) return;
      if (userId <= 0) {
        _showSnack('สมัครสมาชิกไม่สำเร็จ', error: true);
        return;
      }

      await SessionManager.saveUserId(userId);
      if (!mounted) return;
      _showSnack('สมัครสมาชิกสำเร็จ');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalityQuizPage()),
      );
    } catch (e, st) {
      AppLogger.error('Sign-up failed', e, st);
      _showSnack('เกิดข้อผิดพลาดในการสมัครสมาชิก', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('สมัครสมาชิก'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFE0E0E0),
                            backgroundImage: _profileImage != null
                                ? (kIsWeb
                                        ? MemoryImage(_profileImage as Uint8List)
                                        : FileImage(_profileImage as File))
                                    as ImageProvider
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _textField(
                    controller: _emailController,
                    label: 'อีเมล',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: InputValidator.validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _textField(
                    controller: _usernameController,
                    label: 'ชื่อผู้ใช้',
                    icon: Icons.alternate_email,
                    validator: InputValidator.validateUsername,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: _firstNameController,
                          label: 'ชื่อ',
                          icon: Icons.badge_outlined,
                          validator: (v) =>
                              InputValidator.validateName(v, field: 'ชื่อ'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _textField(
                          controller: _lastNameController,
                          label: 'นามสกุล',
                          icon: Icons.person_outline,
                          validator: (v) =>
                              InputValidator.validateName(v, field: 'นามสกุล'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _textField(
                    controller: _passwordController,
                    label: 'รหัสผ่าน',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: InputValidator.validatePassword,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _textField(
                    controller: _confirmPasswordController,
                    label: 'ยืนยันรหัสผ่าน',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                      if (v != _passwordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cake_outlined,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate == null
                                ? 'เลือกวันเกิด'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('ลงทะเบียน'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
      ),
    );
  }
}
