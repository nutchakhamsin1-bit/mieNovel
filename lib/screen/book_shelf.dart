import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mie_project/screen/show_chapter.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookShelfScreen extends StatefulWidget {
  const BookShelfScreen({super.key});

  @override
  State<BookShelfScreen> createState() => _BookShelfScreenState();
}

class _BookShelfScreenState extends State<BookShelfScreen> {
  late Future<int> _userIdFuture;
  Future<List<Map<String, dynamic>>>? _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _userIdFuture = _loadUserId();
  }

  // 1. ฟังก์ชันสำหรับดึง user ID จาก SharedPreferences และเริ่มโหลด Favorites
  Future<int> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    
    // ⭐ ใช้ setState เพื่ออัปเดต Future ในกรณีที่โหลด userId สำเร็จ/ไม่สำเร็จ
    if (mounted) {
      setState(() {
        if (userId > 0) {
          // 🛑 ต้องมั่นใจว่า DBHelper.getFavoriteNovels ดึง 'is_banned' กลับมาด้วย
          _favoritesFuture = DBHelper.getFavoriteNovels(userId);
        } else {
          _favoritesFuture = Future.value([]);
        }
      });
    }
    return userId;
  }

  // 💡 ฟังก์ชันที่ใช้ในการ Refresh
  Future<void> _handleRefresh() async {
    // โหลด User ID ใหม่ (ซึ่งจะเรียก _favoritesFuture ใหม่ด้วย)
    await _loadUserId();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หนังสือโปรด', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF26A69A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFFFFFFF),
        // FutureBuilder ตัวแรก: รอ user ID
        child: FutureBuilder<int>(
          future: _userIdFuture,
          builder: (context, userIdSnapshot) {
            
            if (userIdSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final currentUserId = userIdSnapshot.data ?? 0;

            // ตรวจสอบว่ามี user ID หรือไม่
            if (currentUserId == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'กรุณาเข้าสู่ระบบเพื่อดูนิยายที่คุณชื่นชอบ', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              );
            }

            // FutureBuilder ตัวที่สอง: รอผลลัพธ์นิยายโปรด
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _favoritesFuture, 
              builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาดในการโหลดนิยาย: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                final favorites = snapshot.data ?? [];
                final bool hasFavorites = favorites.isNotEmpty;

                if (hasFavorites) {
                  // มีข้อมูลนิยายโปรด -> แสดงผลใน GridView
                  return RefreshIndicator(
                    onRefresh: _handleRefresh, // 💡 ใช้ _handleRefresh
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.6,
                        ),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final novel = favorites[index];
                          
                          // ⭐ ดึงสถานะการแบน: 1 คือถูกแบน, 0 คือไม่ถูกแบน
                          final isBanned = (novel['is_banned'] == 1); 

                          return _NovelCoverItem(
                            novelId: novel['novel_id'] as int,
                            title: novel['title'] as String? ?? 'ไม่มีชื่อ',
                            coverImage: novel['cover_image'] as String?,
                            isBanned: isBanned, // ⭐ ส่งสถานะการแบนไปด้วย
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  // ไม่มีข้อมูลนิยายโปรด -> แสดงข้อความแจ้งเตือน
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        Text(
                          'ยังไม่มีนิยายโปรด',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ลองเพิ่มนิยายลงในชั้นหนังสือของคุณสิ',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// ⭐ Widget สำหรับแสดงปกนิยายใน Grid (ปรับปรุง)
// ----------------------------------------------------------------------
class _NovelCoverItem extends StatelessWidget {
  final int novelId;
  final String title;
  final String? coverImage;
  final bool isBanned; // ⭐ เพิ่มสถานะการแบน

  const _NovelCoverItem({
    required this.novelId,
    required this.title,
    this.coverImage,
    this.isBanned = false, // ⭐ ค่าเริ่มต้นเป็น false
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () { 
        // 💡 นำทางไปหน้าแสดงรายละเอียดนิยาย
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChapterListScreen(
          novelId: novelId,
          novelTitle: title, 
          // ⭐ ต้องเพิ่ม isBanned เป็นพารามิเตอร์ของ ChapterListScreen ด้วย
          isBanned: isBanned, 
        )));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ส่วนปกนิยาย
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isBanned ? Colors.grey[400] : Colors.grey[200], // 💡 เปลี่ยนสีพื้นหลังถ้าถูกแบน
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isBanned ? Colors.red.shade600 : Colors.grey.shade300) // 💡 ขอบสีแดงถ้าถูกแบน
              ),
              child: Stack( // ⭐ ใช้ Stack เพื่อซ้อนสถานะแบนบนปก
                fit: StackFit.expand,
                children: [
                  // 1. รูปภาพปก
                  coverImage != null && coverImage!.isNotEmpty
                      ? ClipRRect( 
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(coverImage!),
                            fit: BoxFit.cover,
                            color: isBanned ? Colors.black54 : null, // 💡 ทำให้ภาพมืดลงถ้าถูกแบน
                            colorBlendMode: isBanned ? BlendMode.darken : null,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image, 
                                  size: 30, 
                                  color: isBanned ? Colors.red.shade100 : Colors.red[300]
                                ),
                              );
                            },
                          ),
                        )
                      : Center(child: Icon(Icons.menu_book, size: 30, color: Colors.grey[500])),
                  
                  // 2. ป้ายเตือนการแบน
                  if (isBanned)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ถูกแบน',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ชื่อนิยาย
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // 💡 เปลี่ยนสีชื่อเรื่องถ้าถูกแบน
            style: TextStyle(
              fontSize: 13, 
              color: isBanned ? Colors.red.shade700 : Colors.black87,
              fontWeight: isBanned ? FontWeight.bold : FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }
}