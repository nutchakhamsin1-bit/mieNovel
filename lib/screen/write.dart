import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mie_project/screen/NotificationPage.dart';
import 'package:mie_project/screen/manage_novel_writer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/screen/new_novel.dart';
import 'package:mie_project/services/db_helper.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  List<Map<String, dynamic>> _novels = [];
  bool _isLoading = true;
  int? _currentUserId;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchNovels();
  }

  // ⭐ ฟังก์ชันใหม่: โหลดจำนวนแจ้งเตือนที่ยังไม่ได้อ่าน
  Future<void> _loadUnreadNotifications() async {
    if (_currentUserId == null) return;
    try {
      final count = await DBHelper.getUnreadNotificationCount(_currentUserId!);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread notifications: $e');
    }
  }

  Future<void> _loadUserAndFetchNovels() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');

    if (userId == null) {
      print('❌ Error: User ID not found in SharedPreferences.');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเข้าสู่ระบบก่อนใช้งาน'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _currentUserId = userId;
    // ⭐ เรียกโหลดแจ้งเตือนตั้งแต่เริ่มต้น
    await _loadUnreadNotifications();
    await _fetchNovels();
  }

  // ⭐ ปรับปรุง: เรียกโหลดแจ้งเตือนด้วยเมื่อดึงข้อมูลนิยาย
  Future<void> _fetchNovels() async {
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // *** เมธอดนี้ต้องดึงคอลัมน์ 'is_banned' มาด้วย (สมมติว่าดึงมาแล้ว) ***
      final novels = await DBHelper.getNovelsByUser(_currentUserId!);
      await Future.delayed(const Duration(milliseconds: 500));

      print('📖 Fetched novels for User ID $_currentUserId: $novels');

      setState(() {
        _novels = novels;
        _isLoading = false;
      });

      // ⭐ โหลดแจ้งเตือนอีกครั้งเผื่อมีการแจ้งเตือนใหม่เข้ามาขณะรอ
      await _loadUnreadNotifications();

    } catch (e) {
      print('Error fetching user novels: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลนิยายได้ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ----------------------------------------------------------------------
  // ⭐ Widget สำหรับ Icon แจ้งเตือน (Notification Icon)
  // ----------------------------------------------------------------------
  Widget _buildNotificationIcon() {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.notifications_none, color: Colors.white, size: 28),
          // แสดงจุดสีแดงพร้อมจำนวน ถ้ามีแจ้งเตือนที่ยังไม่ได้อ่าน
          if (_unreadNotificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  // จำกัดจำนวนไม่ให้ใหญ่เกินไป เช่น แสดง '99+'
                  _unreadNotificationCount > 99
                      ? '99+'
                      : _unreadNotificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
        ],
      ),
      onPressed: () async {
        // นำทางไปหน้าแจ้งเตือน และรอผลกลับมา
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationPage(),
          ),
        );
        // เมื่อกลับมา ให้โหลดจำนวนแจ้งเตือนที่ยังไม่ได้อ่านใหม่
        _loadUnreadNotifications();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF26A69A)),
        ),
      );
    }

    final bool hasNovels = _novels.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        automaticallyImplyLeading: false,
        title: const Text(
          'ผลงานเขียน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // ⭐ เพิ่ม Actions
        actions: [
          _buildNotificationIcon(),
          const SizedBox(width: 8), // เว้นระยะขอบ
        ],
      ),
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: hasNovels
            ? RefreshIndicator(
                onRefresh: _fetchNovels,
                color: const Color(0xFF26A69A),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _novels.length,
                  itemBuilder: (context, index) {
                    final novel = _novels[index];
                    return _buildNovelCard(novel);
                  },
                ),
              )
            : _buildEmptyState(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewNovelScreen(),
            ),
          );
          _fetchNovels(); // โหลดรายการใหม่เมื่อกลับมา
        },
        backgroundColor: const Color(0xFF26A69A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    // ... (ส่วน _buildEmptyState เหมือนเดิม)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.create_rounded,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'ยังไม่มีนิยายที่คุณเขียน',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'เริ่มสร้างนิยายเรื่องแรกของคุณได้เลย!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ⭐ แก้ไข: _buildNovelCard เพื่อจัดการสถานะการแบน
  // ----------------------------------------------------------------------
  Widget _buildNovelCard(Map<String, dynamic> novel) {
    final String title = novel['title']?.toString() ?? 'ไม่มีชื่อเรื่อง';
    final String imagePath = novel['cover_image']?.toString() ?? '';
    final int novelId = novel['novel_id'] as int? ?? 0;
    
    // ⭐ ดึงสถานะการแบน
    final bool isBanned = novel['is_banned'] == 1;

    // ⭐ กำหนดสีและรูปแบบตามสถานะ
    final Color cardColor = isBanned ? Colors.red.shade50 : Colors.white;
    final Color titleColor = isBanned ? Colors.red.shade800 : Colors.black;
    final String subtitleText = isBanned ? '🚨 ถูกแบน' : 'อัปเดต: ${_formatDate(novel['last_updated'])}';
    
    ImageProvider imageProvider;
    if (imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        imageProvider = FileImage(file);
      } else {
        imageProvider = const AssetImage('assets/images/logo.png');
      }
    } else {
      imageProvider = const AssetImage('assets/images/logo.png');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      color: cardColor, // ใช้สีตามสถานะการแบน
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: ColorFiltered( // ใช้ ColorFiltered เพื่อลดความสว่างถ้าถูกแบน
                colorFilter: isBanned
                    ? ColorFilter.mode(Colors.grey.withOpacity(0.5), BlendMode.saturation)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Image(
                  image: imageProvider,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.book_outlined, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            if (isBanned) // แสดงไอคอนแบนทับภาพปก
              const Icon(
                Icons.block,
                color: Colors.red,
                size: 30,
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: titleColor, // ใช้สีตามสถานะการแบน
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitleText, // แสดงข้อความสถานะแบน
          style: TextStyle(
            color: isBanned ? Colors.red.shade600 : Colors.grey[600],
            fontWeight: isBanned ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 16,
          color: isBanned ? Colors.red.shade400 : null,
        ),
        onTap: () async {
          // ยังคงสามารถเข้าหน้าจัดการได้เหมือนเดิมแม้ถูกแบน
          if (novelId != 0) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageNovelWriter(novelId: novelId),
              ),
            );
            _fetchNovels(); // โหลดรายการนิยายใหม่เมื่อกลับมา
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ไม่พบ Novel ID')),
            );
          }
        },
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'ไม่ทราบวันที่';
    final dateStr = dateValue.toString();
    if (dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    } else {
      return dateStr;
    }
  }
}