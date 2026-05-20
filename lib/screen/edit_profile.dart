import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final bool isWriter;

  const EditProfilePage({Key? key, this.isWriter = false}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _imageFile;
  Uint8List? _imageBytes; // for web
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _pennameController = TextEditingController();

  // 📸 เลือกรูปจากแกลเลอรี่
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  // 💾 ฟังก์ชันบันทึกข้อมูลโปรไฟล์
  Future<void> _editProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้')),
      );
      return;
    }

    Map<String, dynamic> updatedData = {};

    if (_nameController.text.isNotEmpty) {
      updatedData['name'] = _nameController.text;
    }
    if (_emailController.text.isNotEmpty) {
      updatedData['email'] = _emailController.text;
    }
    if (kIsWeb ? _imageBytes != null : _imageFile != null) {
      updatedData['avatar_image'] = _imageFile?.path ?? '';
    }

    if (updatedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีข้อมูลที่ถูกแก้ไข')),
      );
      return;
    }

    final rows = await DBHelper.updateUser(userId, updatedData);

    if (rows > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
      Navigator.pop(context, true); // ส่ง true กลับไปเพื่อ reload หน้าโปรไฟล์
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถบันทึกข้อมูลได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFF26A69A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: kIsWeb
                                        ? (_imageBytes != null
                                            ? MemoryImage(_imageBytes!) as ImageProvider
                                            : null)
                                        : (_imageFile != null
                                            ? FileImage(_imageFile!) as ImageProvider
                                            : null),
                                    child: (kIsWeb ? _imageBytes == null : _imageFile == null)
                                        ? Icon(Icons.person,
                                            size: 60, color: Colors.grey[400])
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF26A69A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          size: 20, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildInputField(
                            label: 'ชื่อจริง',
                            controller: _nameController,
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 24),
                          _buildInputField(
                            label: 'อีเมล',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            isEmail: true,
                          ),
                          if (widget.isWriter) ...[
                            const SizedBox(height: 24),
                            _buildInputField(
                              label: 'นามปากกา',
                              controller: _pennameController,
                              icon: Icons.edit_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'บันทึกการเปลี่ยนแปลง',
                        style: TextStyle(
                          color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return null; // กรอกหรือไม่กรอกก็ได้
            }
            if (isEmail && !value.contains('@')) {
              return 'กรุณากรอกอีเมลที่ถูกต้อง';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _pennameController.dispose();
    super.dispose();
  }
}
