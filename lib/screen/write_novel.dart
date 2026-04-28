import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/screen/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/screen/preview_novel.dart';

import 'dart:async'; // ตรวจสอบชื่อไฟล์ให้ถูกต้อง

class WriteNovelScreen extends StatefulWidget {
  // พารามิเตอร์ทั้งหมดถูกส่งผ่าน Widget
  final int novelId;
  final int chapterId;
  final int chapterNumber;
  final String chapterTitle;
  final String initialContent; // ใช้เป็นค่าสำรองหากเนื้อหาใน DB เป็น Null

  const WriteNovelScreen({
    super.key,
    required this.novelId,
    required this.chapterId,
    required this.chapterNumber,
    required this.chapterTitle,
    this.initialContent = '',
  });

  @override
  State<WriteNovelScreen> createState() => _WriteNovelScreenState();
}

class _WriteNovelScreenState extends State<WriteNovelScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  double _fontSize = 16.0;
  TextStyle _currentStyle = GoogleFonts.taviraj(
    fontSize: 16,
    height: 1.5,
    color: Colors.black87,
  );
  
  // AI support variables
  Timer? _analysisTimer;
  List<TextSpan> _analyzedText = [];
  bool _isAnalyzing = false;

  // State variables for data display
  bool _isLoading = true;
  String _title = 'กำลังโหลด...'; // Novel Title
  String _penName = 'กำลังโหลด...';
  int _chapterNumberState = 0;
  String _chapterTitleState = 'กำลังโหลด...';

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นจาก widget ก่อนการโหลด DB
    _chapterNumberState = widget.chapterNumber;
    _chapterTitleState = widget.chapterTitle;

    // โหลดข้อมูลจาก DB เพื่อดึงเนื้อหาที่บันทึกไว้ก่อนหน้า
    _loadChapterData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _analysisTimer?.cancel();
    super.dispose();
  }



  // 1. โหลดข้อมูลบทและนิยายจากฐานข้อมูล
  Future<void> _loadChapterData() async {
    setState(() => _isLoading = true);

    try {
      final int novelId = widget.novelId;
      final int chapterId = widget.chapterId;

      print('📼 WriteNovelScreen: novelId: $novelId, chapterId: $chapterId');

      // ดึงข้อมูลบท
      final Map<String, dynamic>? chapter = await DBHelper.getChapterById(
        novelId: novelId,
        chapterId: chapterId,
      );

      // ดึงข้อมูลนิยาย
      final Map<String, dynamic>? novel = await DBHelper.getNovelById(novelId);

      if (chapter == null || novel == null) {
        if (mounted) {
          setState(() {
            _title = 'ไม่พบข้อมูลบท/นิยายในฐานข้อมูล (ID: $chapterId / $novelId)';
            _isLoading = false;
          });
        }
        return;
      }

      // Logic เนื้อหา: ใช้เนื้อหาจาก DB (content) หากมี, มิฉะนั้นใช้ initialContent
      final String contentFromDb = chapter['content'] as String? ?? '';
      final String contentToUse =
          contentFromDb.isNotEmpty ? contentFromDb : widget.initialContent;

      if (mounted) {
        setState(() {
          _title = novel['title'] as String? ?? 'ชื่อนิยายไม่พบ';
          _penName = novel['writer_name'] as String? ?? 'ไม่ระบุชื่อปากกา';
          _chapterNumberState =
              chapter['chapter_number'] as int? ?? widget.chapterNumber;
          _chapterTitleState =
              chapter['title'] as String? ?? widget.chapterTitle;
          _textController.text = contentToUse;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chapter data: $e');
      if (mounted) {
        setState(() {
          _title = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
          _isLoading = false;
        });
      }
    }
  }

  // 2. บันทึก/อัปเดตบทในฐานข้อมูล
  Future<void> _saveNovelToDatabase({bool isPublish = false}) async {
    if (widget.chapterId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถบันทึกได้: ไม่พบ ID บท.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final int rowsAffected = await DBHelper.updateChapter(
        chapterId: widget.chapterId,
        content: _textController.text,
        isPublished: isPublish,
        newTitle: _chapterTitleState, // หากต้องการอัปเดตชื่อบทด้วย
      );

      if (mounted) {
        if (rowsAffected > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  isPublish ? 'เผยแพร่และบันทึกเรียบร้อยแล้ว! ✅' : 'บันทึกฉบับร่างเรียบร้อยแล้ว.'),
              backgroundColor: isPublish ? Colors.green : Colors.blueGrey,
            ),
          );
        } else {
          // แจ้งเตือนในกรณีที่ไม่มีการเปลี่ยนแปลง แต่ไม่มีข้อผิดพลาด
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกสำเร็จ (ไม่มีการเปลี่ยนแปลงเนื้อหา)'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving chapter data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 3. นำทางไป Preview
  void _navigateToPreview() async {
    if (_textController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเขียนเนื้อหาก่อนดูตัวอย่าง'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // บันทึกเนื้อหาล่าสุดก่อนดู Preview
    await _saveNovelToDatabase(isPublish: false);

    // บันทึก novelId และ chapterId ลง SharedPreferences เพื่อให้ PreviewNovelScreen ดึงไปใช้
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('novel_id', widget.novelId);
    await prefs.setInt('chapter_id', widget.chapterId); // ส่ง chapterId ไปด้วย

    // ไปยัง PreviewNovelScreen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PreviewNovelScreen(),
        ),
      );
    }
  }

  // 4. Dialog ยืนยันการบันทึกและเผยแพร่ (พร้อมเด้งกลับหน้าเดิม)
  void _showSaveConfirmationDialog() {
    // บันทึกแบบร่าง (Draft) ก่อนเข้า Dialog
    _saveNovelToDatabase(isPublish: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Context สำหรับ Dialog
        return AlertDialog(
          title: const Text('บันทึกสำเร็จ'),
          content: const Text(
              'คุณได้บันทึกเป็นฉบับร่างแล้ว คุณต้องการเผยแพร่บทนี้หรือไม่?'),
          actions: [
            // ปุ่ม 'ยังไม่เผยแพร่'
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _navigateToHome();
              },
              child: const Text('ยังไม่เผยแพร่'),
            ),

            // ปุ่ม 'เผยแพร่ตอนนี้'
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                print('User chose to publish the chapter now.');
                await _saveNovelToDatabase(isPublish: true);
                _navigateToHome();
              },
              child: const Text(
                'เผยแพร่ตอนนี้',
                style: TextStyle(
                    color: Color(0xFF26A69A), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // 5. ลบ Chapter จากฐานข้อมูล
  Future<void> _deleteChapter() async {
    try {
      final int rowsAffected =
          await DBHelper.deleteChapter(chapterId: widget.chapterId);

      if (mounted) {
        if (rowsAffected > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบบทเรียบร้อยแล้ว! 🗑️'),
              backgroundColor: Colors.orange,
            ),
          );
          // นำทางกลับหน้า Home/รายการบท
          _navigateToHome();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบบทที่ต้องการลบในฐานข้อมูล'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting chapter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการลบบท: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 6. Dialog ยืนยันการลบบท
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการลบบท'),
          content: Text(
              'คุณแน่ใจหรือไม่ว่าต้องการลบบทที่ ${_chapterNumberState}: "${_chapterTitleState}" นี้? การกระทำนี้ไม่สามารถยกเลิกได้'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // ปิด Dialog
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // ปิด Dialog
                await _deleteChapter(); // ดำเนินการลบ
              },
              child: const Text(
                'ลบ',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    // ตรวจสอบว่า State ยังคง mount อยู่ ก่อนนำทาง
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          // 💡 เปลี่ยนตรงนี้เป็นชื่อ Home Screen ของคุณ
          builder: (context) => const HomeScreen(),
        ),
        // 💡 Predicate: ลบทุกหน้าจนกว่าจะถึงหน้าแรกสุด (Root)
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _fontOptionButton(String name, TextStyle style) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentStyle = style.copyWith(
            fontSize: _fontSize,
            height: 1.5,
            color: Colors.black87,
          );
        });
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      child: Text(name),
    );
  }

  void _showFormatSettings() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ตั้งค่าการแสดงผล',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _fontOptionButton('Taviraj', GoogleFonts.taviraj()),
                  _fontOptionButton('Prompt', GoogleFonts.prompt()),
                  _fontOptionButton('Sarabun', GoogleFonts.sarabun()),
                  _fontOptionButton('Charm', GoogleFonts.charm()),
                  _fontOptionButton('Mali', GoogleFonts.mali()),
                  _fontOptionButton('Bai Jamjuree', GoogleFonts.baiJamjuree()),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'ขนาดตัวอักษร',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Slider(
                    value: _fontSize,
                    min: 14,
                    max: 24,
                    divisions: 5,
                    label: _fontSize.round().toString(),
                    activeColor: const Color(0xFF26A69A),
                    onChanged: (value) {
                      setModalState(() {
                        _fontSize = value;
                      });
                      setState(() {
                        _currentStyle =
                            _currentStyle.copyWith(fontSize: value);
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle Loading State
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF26A69A),
          title:
              const Text('กำลังโหลด...', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF26A69A)),
        ),
      );
    }

    // Handle Error State (e.g., ID not found)
    if (_title.startsWith('ไม่พบข้อมูล') || _title.startsWith('เกิดข้อผิดพลาด')) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF26A69A),
          title: const Text('เขียนนิยาย', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _title, // แสดงข้อความ error
              style: const TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Original Build content
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF26A69A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              // **บันทึกอัตโนมัติเมื่อกด Back** (เปลี่ยนจาก isPublish: true เป็น false เพื่อบันทึกเป็น Draft)
              // 💡 ควรบันทึกเป็น Draft เมื่อกด Back เพื่อป้องกันข้อมูลหาย
              _saveNovelToDatabase(isPublish: false);
              Navigator.pop(context);
            }),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white), // 🗑️ ปุ่มลบ
            onPressed: _showDeleteConfirmationDialog, // เรียก Dialog ยืนยันการลบ
          ),
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
            onPressed: _navigateToPreview,
          ),
          IconButton(
            icon: const Icon(Icons.text_format, color: Colors.white),
            onPressed: _showFormatSettings,
          ),
        ],
        title: const Text(
          'เขียนนิยาย',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _title, // ใช้ State variable
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF26A69A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('โดย $_penName', // ใช้ State variable
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26A69A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('บทที่ $_chapterNumberState', // ใช้ State variable
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF26A69A),
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        Text(_chapterTitleState, // ใช้ State variable
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF26A69A),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        style: _currentStyle,
                        
                        decoration: InputDecoration(
                          hintText: 'เริ่มเขียนนิยายของคุณที่นี่...',
                          hintStyle: _currentStyle.copyWith(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          suffixIcon: _isAnalyzing 
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26A69A)),
                                ),
                              )
                            : null,
                        ),
                      ),
                      if (_analyzedText.isNotEmpty && !_isAnalyzing)
                        Positioned.fill(
                          child: RichText(
                            text: TextSpan(
                              children: _analyzedText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSaveConfirmationDialog,
        backgroundColor: const Color(0xFF26A69A),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'บันทึก',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}