import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kIsWeb
import 'package:mie_project/services/db_helper.dart';
import 'write_novel.dart'; // อิมพอร์ตหน้าจอสำหรับเขียน

class NewChapterScreen extends StatefulWidget {
  final int novelId;
  final String title;
  final String penName;
  final String imagePath;
  final Uint8List? imageBytes;
  final String? mainCategory;
  final String? secondaryCategory;
  final String? ageLevel;

  const NewChapterScreen({
    super.key,
    required this.novelId,
    required this.title,
    required this.penName,
    required this.imagePath,
    this.imageBytes,
    this.mainCategory,
    this.secondaryCategory,
    this.ageLevel,
  });

  @override
  State<NewChapterScreen> createState() => _NewChapterScreenState();
}

class _NewChapterScreenState extends State<NewChapterScreen> {
  final TextEditingController _chapterNumberController = TextEditingController();
  final TextEditingController _chapterTitleController = TextEditingController();

  @override
  void dispose() {
    _chapterNumberController.dispose();
    _chapterTitleController.dispose();
    super.dispose();
  }

  void _onStartWriting() async{
    final String chapterNumberText = _chapterNumberController.text.trim();
    final String chapterTitleText = _chapterTitleController.text.trim();

    // ตรวจสอบค่าว่าง
    if (chapterNumberText.isEmpty || chapterTitleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ตรวจสอบตัวเลข
    final int? chapterNumber = int.tryParse(chapterNumberText);
    if (chapterNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('หมายเลขบทต้องเป็นตัวเลข'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

     final chapterData = {
    'novel_id': widget.novelId,
    'chapter_number': chapterNumber,
    'title': chapterTitleText,
    'content': '', // เนื้อหายังเป็นค่าว่างในตอนนี้
    'last_updated': DateTime.now().toIso8601String(), // เพิ่มการบันทึกเวลา
    'is_published': 0, // 0 สำหรับ false
  };

  int newChapterId = 0;
  try {
    // 💡 สมมติว่า DBHelper.insertChapter พร้อมใช้งาน
    // ต้องมีการ import DBHelper มาด้วย หากยังไม่มี
    // import 'package:mie_project/services/db_helper.dart'; 
    newChapterId = await DBHelper.insertChapter(chapterData);
    print('✅ Chapter inserted with ID: $newChapterId');

  } catch (e) {
    print('Error inserting chapter: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ไม่สามารถสร้างบทใหม่ได้: $e'),
        backgroundColor: Colors.red,
      ),
    );
    return; // หยุดทำงานหาก insert ไม่สำเร็จ
  }

    // ไปหน้าการเขียน
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteNovelScreen(
          novelId: widget.novelId,
          chapterId: newChapterId, // 💡 ส่ง chapter_id ที่สร้างใหม่ไป
          chapterNumber: chapterNumber,
          chapterTitle: chapterTitleText,
          initialContent: '', // เนื้อหาเริ่มต้นเป็นค่าว่าง
        ),
      ),
    );

    // ล้างค่าหลังจาก push แล้ว
    _chapterNumberController.clear();
    _chapterTitleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = kIsWeb
        ? (widget.imageBytes != null
            ? Image.memory(
                widget.imageBytes!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.image_not_supported, size: 100))
        : (widget.imagePath.isNotEmpty &&
                File(widget.imagePath).existsSync()
            ? Image.file(
                File(widget.imagePath),
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.image_not_supported, size: 100));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สร้างบทใหม่',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color.fromARGB(255, 252, 244, 255),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageWidget,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF26A69A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'นามปากกา: ${widget.penName}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      if (widget.ageLevel != null &&
                          widget.ageLevel!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'ระดับอายุ: ${widget.ageLevel!}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      const Divider(height: 32),

                      const Text(
                        'บทที่ (Chapter Number)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextField(
                        controller: _chapterNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'เช่น 1, 2, 3...',
                          prefixIcon: const Icon(Icons.numbers,
                              color: Color(0xFF26A69A)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'ชื่อบท (Chapter Title)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      TextField(
                        controller: _chapterTitleController,
                        decoration: InputDecoration(
                          hintText: 'เช่น บทที่ 1: การเริ่มต้นของนักเดินทาง',
                          prefixIcon: const Icon(Icons.title,
                              color: Color(0xFF26A69A)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _onStartWriting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26A69A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          elevation: 5,
                        ),
                        child: const Text(
                          'เริ่มเขียน',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
