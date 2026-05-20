import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:intl/intl.dart'; // อย่าลืมเพิ่ม dependency: intl: ^0.18.1 ใน pubspec.yaml

// สมมติว่ามีหน้า NovelDetailPage (สำหรับ User) ที่สามารถนำทางไปได้
// import 'package:mie_project/screen/novel_detail_user.dart'; 

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchNotifications();
  }

  Future<void> _loadUserAndFetchNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');

    if (userId == null || userId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนใช้งาน')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    _currentUserId = userId;
    await _fetchNotifications();
    
    // อัปเดตสถานะทั้งหมดเป็น "อ่านแล้ว" เมื่อโหลดหน้านี้
    await DBHelper.markAllNotificationsAsRead(_currentUserId!);
  }

  Future<void> _fetchNotifications() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      // ดึงข้อมูลการแจ้งเตือนพร้อมชื่อนิยาย (ที่ JOIN มาใน DBHelper)
      final notifications = await DBHelper.getNotificationsForUser(_currentUserId!); 
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // แสดงข้อผิดพลาดจากฐานข้อมูลที่พบ (เช่น no such table)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดแจ้งเตือน: ${e.toString()}')),
        );
      }
    }
  }

  // Helper function: จัดการเวลาให้เป็นรูปแบบที่อ่านง่าย
  String _formatDateTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('d MMM yyyy, HH:mm').format(dateTime.toLocal()); // แสดงวันที่และเวลาท้องถิ่น
    } catch (e) {
      return '';
    }
  }

  // Helper function ในการกำหนดไอคอนตามประเภท
  IconData _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'ban':
        return Icons.gavel_rounded;
      case 'report_update':
        return Icons.rule_folder;
      default:
        return Icons.info_outline;
    }
  }
  
  // Helper function ในการกำหนดสีตามประเภท
  Color _getColorForType(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange.shade700;
      case 'ban':
        return Colors.red.shade700;
      case 'report_update':
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'การแจ้งเตือน',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF26A69A)))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text(
                        'ไม่มีการแจ้งเตือนใหม่',
                        style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 70), // เส้นแบ่งบางลง
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final String type = notification['type'] ?? 'info';
                    final bool isRead = notification['is_read'] == 1;
                    
                    // ⭐ ดึงชื่อนิยายที่ JOIN มาใช้
                    final String novelTitle = notification['novel_title'] ?? 'นิยายถูกลบแล้ว';
                    
                    // กำหนดข้อความหลัก
                    String mainTitle;
                    if (type == 'warning') {
                        mainTitle = '⚠️ คำเตือนเรื่องนิยาย: $novelTitle'; 
                    } else if (type == 'ban') {
                        mainTitle = '❌ นิยายถูกระงับ: $novelTitle'; 
                    } else if (type == 'report_update') {
                        mainTitle = '📋 สถานะคำร้องอัปเดต: $novelTitle';
                    } else {
                        mainTitle = 'การแจ้งเตือนทั่วไป';
                    }

                    final Color iconColor = _getColorForType(type);

                    return Container(
                      color: isRead ? Colors.white : Colors.lightBlue.withValues(alpha: 0.05), // ไฮไลท์ยังไม่อ่านอ่อน ๆ
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(type),
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          mainTitle,
                          style: GoogleFonts.prompt(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['message'] ?? 'ไม่มีรายละเอียด',
                              style: GoogleFonts.prompt(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(notification['created_at']),
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        trailing: isRead 
                            ? null 
                            : Container( // จุดสีแดงเล็ก ๆ สำหรับ "ยังไม่ได้อ่าน"
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () {
                          // TODO: นำทางไปหน้า NovelDetailPage หรือ ChapterPage ที่เกี่ยวข้อง
                          
                          // หากมีการนำทาง ควรเรียก _fetchNotifications() อีกครั้ง เมื่อกลับมา
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('กำลังนำทางไปที่ ${notification['novel_id']} - $novelTitle')),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}