import 'package:flutter/material.dart';
import 'package:mie_project/admin/managemember.dart';
import 'package:mie_project/admin/managenovel.dart';
import 'package:mie_project/screen/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/admin/reportpage.dart';
import 'package:mie_project/services/db_helper.dart';

class Adminhomepage extends StatefulWidget {
  const Adminhomepage({super.key});

  @override
  // ⭐ 1. เพิ่ม with WidgetsBindingObserver
  State<Adminhomepage> createState() => _AdminhomepageState();
}

class _AdminhomepageState extends State<Adminhomepage>
    with WidgetsBindingObserver {
  int _pendingReportCount = 0;

  @override
  void initState() {
    super.initState();
    // เพิ่ม Observer ใน initState
    WidgetsBinding.instance.addObserver(this);
    _checkPendingReports();
  }

  @override
  void dispose() {
    // ลบ Observer ออกใน dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 2. ดักจับเมื่อแอปกลับมาทำงานจากพื้นหลัง
    if (state == AppLifecycleState.resumed) {
      _checkPendingReports();
    }
  }

  Future<void> _checkPendingReports() async {
    try {
      final int count = await DBHelper.getPendingReportCount();
      if (mounted) {
        setState(() {
          _pendingReportCount = count;
        });
      }
    } catch (e) {
      print("Error checking pending reports: $e");
    }
  }

  // ฟังก์ชันสำหรับการออกจากระบบ
  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // กำหนด Style ปุ่มหลัก (Normal)
    final normalButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00897B),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผู้ดูแลระบบ'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'ออกจากระบบ',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ปุ่มจัดการนิยาย
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: normalButtonStyle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Managenovel()),
                  ).then((_) {
                    // ⭐ เพิ่ม: โหลดซ้ำเมื่อกลับมาจากหน้านี้
                    _checkPendingReports();
                  });
                },
                child: const Text(
                  'จัดการนิยาย',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ปุ่มจัดการสมาชิก
            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: normalButtonStyle,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Managemember()),
                  ).then((_) {
                    // ⭐ เพิ่ม: โหลดซ้ำเมื่อกลับมาจากหน้านี้
                    _checkPendingReports();
                  });
                },
                child: const Text(
                  'จัดการสมาชิก',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ปุ่มจัดการคำร้อง
            SizedBox(
              width: 200,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ปุ่มจัดการคำร้อง (ฐาน)
                  ElevatedButton(
                    style: normalButtonStyle.copyWith(
                      minimumSize: MaterialStateProperty.all(
                        const Size(double.infinity, 0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminReportManagePage(),
                        ),
                      ).then((_) {
                        // โหลดซ้ำเมื่อกลับมาจากหน้านี้ (มีอยู่เดิม)
                        _checkPendingReports();
                      });
                    },
                    child: const Text(
                      'จัดการคำร้อง',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  // Badge สีแดง พร้อมตัวเลข
                  if (_pendingReportCount > 0)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          _pendingReportCount > 99
                              ? '99+'
                              : '$_pendingReportCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
