import 'package:flutter/material.dart';
import 'package:mie_project/screen/new_chapter.dart';
import 'package:mie_project/screen/write_novel.dart';
import 'package:mie_project/services/db_helper.dart'; 
import 'dart:io';

class ManageNovelWriter extends StatefulWidget {
  final int novelId;

  const ManageNovelWriter({super.key, required this.novelId});

  @override
  State<ManageNovelWriter> createState() => _ManageNovelWriterState();
}

class _ManageNovelWriterState extends State<ManageNovelWriter> {
  // 💡 State variables
  Map<String, dynamic>? _novelData;
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;
  bool _isNovelBanned = false;
  int _warningCount = 0; // สถานะจำนวนคำเตือน

  @override
  void initState() {
    super.initState();
    _loadNovelAndChapters();
    _debugPrintAllNovels();
  }

  Future<void> _debugPrintAllNovels() async {
     try {
       List<Map<String, dynamic>> novels = await DBHelper.getAllNovels();

       print('================ NOVELS DATA START ================');
       if (novels.isEmpty) {
         print('ไม่พบข้อมูลนิยายในฐานข้อมูล.');
       } else {
         for (var novel in novels) {
           print(
             'Novel ID: ${novel['novel_id']}, Title: ${novel['title']}, Views: ${novel['number_of_views']}, Is Banned: ${novel['is_banned']}, Warnings: ${novel['number_of_warnings']}',
           );
         }
       }
       print('================ NOVELS DATA END ==================');
     } catch (e) {
       print('ERROR: ไม่สามารถดึงข้อมูลนิยายได้: $e');
     }
  }

  // ---------------------- DATA LOADING (แก้ไข) ----------------------
  Future<void> _loadNovelAndChapters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ดึงข้อมูลนิยาย (Novel)
      final novel = await DBHelper.getNovelById(widget.novelId);

      // 2. ดึงรายการบท (Chapters)
      final chapters = await DBHelper.getChapters(widget.novelId);
      
      // ⭐ ใช้เมธอดที่ให้มาเพื่อดึงจำนวนคำเตือน
      final int warningCount = await DBHelper.getNovelWarningCount(widget.novelId); 
      
      final bool bannedStatus = novel?['is_banned'] == 1; 

      if (mounted) {
        setState(() {
          _novelData = novel;
          _chapters = chapters;
          _isNovelBanned = bannedStatus;
          _warningCount = warningCount; // ⭐ อัปเดตจำนวนคำเตือน
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading novel and chapters: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------------- NAVIGATION & DELETION ----------------------
  void _navigateToChapter(Map<String, dynamic> chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteNovelScreen(
          novelId: widget.novelId,
          chapterId: chapter['chapter_id'],
          chapterNumber: chapter['chapter_number'],
          chapterTitle: chapter['title'],
        ),
      ),
    ).then((_) {
      _loadNovelAndChapters();
    });
  }

  void _navigateToNewChapter() {
    if (_novelData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเพิ่มบทได้: ข้อมูลนิยายยังไม่พร้อม'),
        ),
      );
      return;
    }

    final String novelTitle =
        _novelData!['title'] as String? ?? 'ไม่ระบุชื่อเรื่อง';
    final String writerName =
        _novelData!['writer_name'] as String? ?? 'ไม่ระบุชื่อปากกา';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewChapterScreen(
          novelId: widget.novelId,
          title: novelTitle,
          penName: writerName,
          imagePath: _novelData!['cover_image'] as String? ?? '',
        ),
      ),
    ).then((_) {
      _loadNovelAndChapters();
    });
  }

  Future<void> _confirmAndDeleteNovel() async {
    if (_novelData == null) return;
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบนิยาย'),
          content: Text(
            'คุณแน่ใจหรือไม่ที่จะลบนิยาย "${_novelData!['title']}"? การกระทำนี้ไม่สามารถย้อนกลับได้ และจะลบทุกบท, ความคิดเห็น และข้อมูลที่เกี่ยวข้องทั้งหมด',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), 
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final int rowsAffected = await DBHelper.deleteNovel(widget.novelId);

        if (rowsAffected > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ลบนิยาย "${_novelData!['title']}" สำเร็จแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
          if (mounted) {
            Navigator.pop(context, true); 
          }
        } else {
          throw Exception('ไม่สามารถลบนิยายได้ (Novel ID ไม่ถูกต้อง)');
        }
      } catch (e) {
        print('ERROR deleting novel: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาดในการลบนิยาย: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------------- UI BUILDER (แก้ไข) ----------------------

  // ⭐ ฟังก์ชันสร้างแถบคำเตือนที่แสดงจำนวนครั้ง
  Widget _buildWarningBanner() {
    final bool hasWarnings = _warningCount > 0;
    
    // แถบจะแสดงผลเมื่อถูกแบน OR ได้รับคำเตือน
    if (!_isNovelBanned && !hasWarnings) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color fgColor;
    IconData icon;
    String title;
    String message;

    if (_isNovelBanned) {
      // 1. กรณีถูกแบน (สีแดง)
      bgColor = Colors.red.shade100;
      fgColor = Colors.red.shade800;
      icon = Icons.gavel_rounded;
      title = '⚠️ นิยายนี้ถูกระงับ/แบน';
      message = 'นิยายเรื่องนี้ถูกระงับการเผยแพร่ชั่วคราวหรือถาวรจากผู้ดูแลระบบ ผู้อ่านทั่วไปจะไม่เห็นและเข้าถึงได้ (ได้รับคำเตือนมาแล้ว $_warningCount ครั้ง)';
    } else { 
      // 2. กรณีมีคำเตือนแต่ยังไม่ถูกแบน (สีส้ม/เหลือง)
      bgColor = Colors.amber.shade100;
      fgColor = Colors.amber.shade800;
      icon = Icons.warning_amber_rounded;
      title = 'ได้รับคำเตือน (${_warningCount} ครั้ง)';
      message = 'นิยายเรื่องนี้ได้รับคำเตือนจากผู้ดูแลระบบ โปรดตรวจสอบเนื้อหาและแก้ไขให้เหมาะสมก่อนได้รับบทลงโทษเพิ่มเติม';
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fgColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('กำลังโหลด...', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF26A69A),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF26A69A)),
        ),
      );
    }

    if (_novelData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'ไม่พบหนังสือนิยาย',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF26A69A),
        ),
        body: Center(child: Text('ไม่พบข้อมูลนิยาย ID: ${widget.novelId}')),
      );
    }

    final String novelTitle =
        _novelData!['title'] as String? ?? 'ไม่ระบุชื่อเรื่อง';
    final String coverImagePath = _novelData!['cover_image'] as String? ?? '';
    final int chapterCount = _chapters.length;

    final ImageProvider imageProvider =
        coverImagePath.isNotEmpty && File(coverImagePath).existsSync()
        ? FileImage(File(coverImagePath)) as ImageProvider
        : const AssetImage('assets/placeholder.png');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        title: Text(
          novelTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_forever,
              color: Colors.white,
            ),
            onPressed: _confirmAndDeleteNovel, 
          ),
        ],
      ),
      body: Column(
        children: [
          // ⭐ แถบคำเตือน/สถานะ
          _buildWarningBanner(), 

          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child:
                      coverImagePath.isEmpty ||
                              !File(coverImagePath).existsSync()
                          ? const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 80,
                            )
                          : null,
                ),
                const SizedBox(height: 8),
                Text(
                  novelTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'โดย ${_novelData!['writer_name']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'จำนวนบททั้งหมด ($chapterCount)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: _navigateToNewChapter, 
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFF26A69A),
                    size: 18,
                  ),
                  label: const Text(
                    'เพิ่มบทใหม่',
                    style: TextStyle(
                      color: Color(0xFF26A69A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: ListView.separated(
              itemCount: chapterCount,
              separatorBuilder: (context, index) =>
                  const Divider(thickness: 1, height: 1),
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                final bool isPublished = chapter['is_published'] == 1;

                return ListTile(
                  title: Text(
                    '#${chapter['chapter_number']} ${chapter['title']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPublished ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  subtitle: isPublished
                      ? null
                      : const Text(
                          'ฉบับร่าง (Draft)',
                          style: TextStyle(color: Colors.red),
                        ),
                  trailing: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Color(0xFF26A69A),
                  ),
                  onTap: () => _navigateToChapter(chapter),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}