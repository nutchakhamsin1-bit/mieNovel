import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreviewNovelScreen extends StatefulWidget {
  const PreviewNovelScreen({super.key});

  @override
  State<PreviewNovelScreen> createState() => _PreviewNovelScreenState();
}

class _PreviewNovelScreenState extends State<PreviewNovelScreen> {
  bool _isLoading = true;
  int? _novelIdFromPrefs;

  String _title = '';
  String _penName = '';
  int _chapterNumber = 0;
  String _chapterTitle = '';
  String _content = '';
  TextStyle _contentStyle = GoogleFonts.taviraj(fontSize: 18, height: 1.8);

  @override
  void initState() {
    super.initState();
    _loadNovelIdAndFetchData();
  }

  // โหลด novel_id จาก SharedPreferences
  Future<void> _loadNovelIdAndFetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? id = prefs.getInt('novel_id');
      print('📼 PreviewNovelScreen initialized with novelId: $id');

      if (id == null) {
        setState(() {
          _isLoading = false;
          _title = 'ไม่พบ ID นิยายในเครื่อง';
        });
        return;
      }

      setState(() {
        _novelIdFromPrefs = id;
      });

      await _fetchNovelChapterData();
    } catch (e) {
      print('Error loading novel ID from SharedPreferences: $e');
      setState(() {
        _isLoading = false;
        _title = 'เกิดข้อผิดพลาดในการโหลด ID';
      });
    }
  }

  // ดึงข้อมูลนิยาย + ตอนแรกจากฐานข้อมูล
  Future<void> _fetchNovelChapterData() async {
    print('📖 Fetching data for novelId: $_novelIdFromPrefs');
    if (_novelIdFromPrefs == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 🔹 ดึงข้อมูลนิยาย
      final db = await DBHelper.initDb();
      final novels = await db.query('Novels',
          where: 'novel_id = ?', whereArgs: [_novelIdFromPrefs]);

      print('📚 All novels in DB: $novels');

      if (novels.isEmpty) {
        setState(() {
          _isLoading = false;
          _title = 'ไม่พบนิยายในฐานข้อมูล';
        });
        return;
      }

      final novelData = Map<String, dynamic>.from(novels.first);

      print('📘 Fetched novel data: $novelData');

      final chapterAlls = await DBHelper.getChapters(_novelIdFromPrefs!);

      print('📄 All chapters for novelId $_novelIdFromPrefs: $chapterAlls');
      
      // 🔹 ดึงตอนแรก (chapter_number = 1)
      final chapters = await db.query(
        'Chapters',
        where: 'novel_id = ? AND chapter_number = ?',
        whereArgs: [_novelIdFromPrefs, 1],
      );

      Map<String, dynamic> chapterData;

      if (chapters.isNotEmpty) {
        chapterData = Map<String, dynamic>.from(chapters.first);
      } else {
        // ถ้าไม่มีตอนในฐานข้อมูล ให้จำลองข้อมูลขึ้นมา
        chapterData = {
          'chapter_number': 1,
          'title': 'บทนำ: จุดเริ่มต้นของเรื่องราว',
          'content':
              'นี่คือเนื้อหาทดสอบของนิยาย "${novelData['title']}" ซึ่งจะใช้สำหรับการแสดงตัวอย่างหน้าอ่าน หากไม่มีข้อมูลตอนในฐานข้อมูลจริง.'
        };
      }

      setState(() {
        _title = novelData['title'] ?? 'ชื่อเรื่องไม่ระบุ';
        _penName = novelData['writer_name'] ?? 'ไม่ระบุชื่อปากกา';
        _chapterNumber = chapterData['chapter_number'] ?? 0;
        _chapterTitle = chapterData['title'] ?? 'ไม่ระบุชื่อบท';
        _content = chapterData['content'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching novel chapter data: $e');
      setState(() {
        _isLoading = false;
        _title = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF26A69A)),
        ),
      );
    }

    // กรณีไม่พบนิยาย
    if (_title.contains('ไม่พบ') || _title.contains('ข้อผิดพลาด')) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF26A69A),
          title: const Text('ข้อผิดพลาดในการแสดงผล',
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _title,
              style: const TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ตัวอย่างนิยาย',
          style: GoogleFonts.taviraj(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อเรื่อง
            Center(
              child: Text(
                _title,
                style: _contentStyle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // ชื่อปากกา
            Center(
              child: Text(
                'โดย: $_penName',
                style: _contentStyle.copyWith(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ชื่อตอน
            Center(
              child: Text(
                '#$_chapterNumber $_chapterTitle',
                style: _contentStyle.copyWith(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // เนื้อหา
            Text(
              _content,
              style: _contentStyle.copyWith(
                fontSize: 18,
                color: Colors.black87,
                height: 1.8,
              ),
              textAlign: TextAlign.justify,
            ),

            

          ],
        ),
      ),
    );
  }
}
