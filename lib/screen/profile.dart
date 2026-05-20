import 'package:flutter/material.dart';
import 'package:mie_project/screen/splash_screen.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/services/image_provider_helper.dart';
import 'package:mie_project/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

   @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 💡 ตัวแปรสำหรับเก็บ Future (สำคัญสำหรับการรีโหลด)
  late Future<Map<String, String>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    // 🔴 กำหนดค่าเริ่มต้นของ Future ใน initState
    _userDataFuture = _fetchUserData();
  }

  // Simulate fetching user data (replace this with your actual data source)
  Future<Map<String, String>> _fetchUserData() async {
    final db = await DBHelper.initDb();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    AppLogger.debug('Fetching profile for user_id: $userId');

    final List<Map<String, dynamic>> result = await db.query(
      'Users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      final user = result.first;
      return {
        'name': user['name'] ?? 'Unknown User',
        'email': user['email'] ?? 'No Email',
        'profileImage': user['avatar_image'] ?? '',
      };
    } else {
      return {
        'name': 'Unknown User',
        'email': 'No Email',
        'profileImage': '',
      };
    }
  }

   void _reloadProfileData() {
    // 🔴 เรียก setState เพื่อสั่งให้ FutureBuilder โหลดข้อมูลใหม่
    setState(() {
      _userDataFuture = _fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 240),
      appBar: AppBar(
        backgroundColor: Color(0xFF26A69A),
        elevation: 0,
        title: Text(
          'โปรไฟล์',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(color: Colors.brown[800]),
              ),
            );
          } else if (snapshot.hasData) {
            final userData = snapshot.data!;
            return Stack(
              children: [

                // Main content
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 50,
                        spreadRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF26A69A),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: userData['profileImage']!.isNotEmpty
                              ? (userData['profileImage']!.startsWith('http')
                                  ? NetworkImage(userData['profileImage']!)
                                  : buildImageProvider(userData['profileImage']!))
                              : null,
                          child: userData['profileImage']!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.brown[300],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.brown.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              userData['name']!,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF26A69A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Color(0xFF26A69A).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'อีเมล: ${userData['email']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () async {
                            final bool? isUpdated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfilePage(isWriter: false),
                              ),
                            );
                            if (isUpdated == true) {
                              _reloadProfileData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF26A69A),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'แก้ไขโปรไฟล์',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('user_id');
                            await prefs.remove('admin_id');
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SplashScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              80,
                              41,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'ออกจากระบบ',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
              ],
            );
          } else {
            // Handle unexpected cases
            return const Center(child: Text('No user data available'));
          }
        },
      ),
    );
  }
}
