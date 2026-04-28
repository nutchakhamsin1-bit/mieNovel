import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mie_project/screen/ai_recommend.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _comfirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  DateTime? _selectedDate;
  dynamic _profileImage;

  void _sign_in () async{
    // Implement sign-in logic here
    final email = _emailController.text;
    final newPassword = _passwordController.text;
    final confirmPassword = _comfirmPasswordController.text;
    final username = _usernameController.text;
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final dateTime = _selectedDate.toString();
    final profileImage = _profileImage.toString();
    if (email.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty ||
        username.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        _selectedDate == null ||
        profileImage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสผ่านให้ตรงกัน')),
      );
      return;
    }
    try {
      final userId = await DBHelper.signIn(email, newPassword, username, firstName, lastName, dateTime, profileImage);
      if (userId > 0) {
        // Save user_id to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PersonalityQuizPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกไม่สำเร็จ')),
        );
        return;
      }
    } catch (e) {
      print("Sign-in error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการสมัครสมาชิก')),
      );
    }
  }

  // Function to show the DatePicker
  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImage = bytes;
        });
      } else {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    }
  }

  // Function to validate the form
//   void _validateAndSubmit() {
//     if (_emailController.text.isEmpty ||
//         _passwordController.text.isEmpty ||
//         _usernameController.text.isEmpty ||
//         _firstNameController.text.isEmpty ||
//         _lastNameController.text.isEmpty ||
//         _selectedDate == null ||
//         _profileImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } else {
//        Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const PersonalityQuizPage(),
//       ),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        title: const Text(
          'Sign-up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00897B), Color(0xFF26A69A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
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
                    // Profile Picture
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFBDBDBD),
                          backgroundImage: _profileImage != null
                              ? (kIsWeb
                                  ? MemoryImage(_profileImage as Uint8List)
                                  : FileImage(_profileImage as File)) as ImageProvider
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 30,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Fields
                    _buildTextField('อีเมล', _emailController, Icons.email),
                    const SizedBox(height: 16),
                    _buildTextField('รหัสผ่าน', _passwordController, Icons.lock, obscureText: true),
                    const SizedBox(height: 16),
                    _buildTextField('ยืนยันรหัสผ่าน', _comfirmPasswordController, Icons.lock, obscureText: true),
                    const SizedBox(height: 16),
                    _buildTextField('ชื่อผู้ใช้', _usernameController, Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField('ชื่อ', _firstNameController, Icons.text_fields),
                    const SizedBox(height: 16),
                    _buildTextField('นามสกุล', _lastNameController, Icons.text_fields),
                    const SizedBox(height: 16),

                    // Birthday Picker
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'กรุณาเลือกวันเกิด'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign-up Button
                    ElevatedButton(
                      onPressed: _sign_in,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'ลงทะเบียน',
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
          ),
        ),
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: 'กรุณาใส่ $label',
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
