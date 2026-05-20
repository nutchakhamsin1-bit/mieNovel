import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mie_project/services/image_helper.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'new_chapter.dart';

class NewNovelScreen extends StatefulWidget {
  const NewNovelScreen({super.key});

  @override
  State<NewNovelScreen> createState() => _NewNovelScreenState();
}

class _NewNovelScreenState extends State<NewNovelScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _penNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedMainCategory;
  String? _selectedSecondaryCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories(); // 🔴 เรียกใช้ฟังก์ชันโหลดข้อมูลเมื่อหน้าจอถูกสร้างขึ้น
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DBHelper.getAllCategoryNames();

      // เมื่อโหลดเสร็จแล้ว ให้ setState เพื่ออัปเดต UI
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        // อาจจะแสดง SnackBar หรือข้อความผิดพลาดที่นี่
      });
    }
  }

  String? _imagePath;
  Uint8List? _webImage;
  String? _selectedAgeLevel;

  final List<String> _ageLevels = ['ทุกวัย', '13+', '15+', '18+'];

  @override
  void dispose() {
    _titleController.dispose();
    _penNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imagePath = pickedFile.path; // For file name
        });
      } else {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    }
  }

  // Age levels for novels

  void _validateAndNavigate() async {
    if (_titleController.text.isEmpty ||
        _penNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedMainCategory == null ||
        _selectedSecondaryCategory == null ||
        _selectedAgeLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด: ไม่พบ ID ผู้ใช้'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final mainCategoryId = await DBHelper.getCategoryIdByName(
      _selectedMainCategory!,
    );
    final secondaryCategoryId = await DBHelper.getCategoryIdByName(
      _selectedSecondaryCategory!,
    );

    if (mainCategoryId == null || secondaryCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด: ไม่พบ ID หมวดหมู่'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกภาพปกนิยาย'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final novelId = await DBHelper.insertNovel(
        userId: userId,
        mainCategoryId: mainCategoryId,
        secondaryCategoryId: secondaryCategoryId,
        title: _titleController.text,
        description: _descriptionController.text,
        ageLimit: _selectedAgeLevel!,
        writerName: _penNameController.text,
        coverImagePath: _imagePath!,
      );
      print('✅ Novel created with ID: $novelId');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewChapterScreen(
            // 🔴 เพิ่ม novelId ที่เพิ่งสร้างไปใน constructor ของ NewChapterScreen
            novelId: novelId,
            title: _titleController.text,
            penName: _penNameController.text,
            imagePath: _imagePath!,
            imageBytes: kIsWeb ? _webImage : null,
            mainCategory: _selectedMainCategory,
            secondaryCategory: _selectedSecondaryCategory,
            ageLevel: _selectedAgeLevel,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error inserting novel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกนิยายล้มเหลว โปรดลองอีกครั้ง'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สร้างนิยาย',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCoverImageCard(),
              const SizedBox(height: 16),
              _buildFormCard(),
              const SizedBox(height: 16),
              _buildCategoryCard(),
              const SizedBox(height: 16),
              _buildAgeLevelCard(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ปกนิยาย',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF26A69A),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: _imagePath == null
                    ? Column(
                        children: [
                          Image.asset(
                            'assets/images/up_cover.png',
                            height: 180,
                            width: 180,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'คลิกเพื่อเพิ่มภาพปกนิยาย (ขนาดแนะนำ 180x180)',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? (_webImage != null
                                  ? Image.memory(
                                      _webImage!,
                                      height: 180,
                                      width: 180,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.broken_image,
                                      size: 100,
                                      color: Colors.red,
                                    ))
                            : buildCoverImage(
                                _imagePath!,
                                height: 180,
                                width: 180,
                                fit: BoxFit.cover,
                              ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('ชื่อเรื่อง'),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'ใส่ชื่อเรื่องของคุณ',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('นามปากกา'),
            TextField(
              controller: _penNameController,
              decoration: const InputDecoration(
                hintText: 'ใส่นามปากกาของคุณ',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('คำนำ'),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'คำอธิบายเกี่ยวกับนิยาย',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('หมวดหมู่หลัก'),
            DropdownButtonFormField<String>(
              initialValue: _selectedMainCategory,
              hint: const Text('เลือกหมวดหมู่หลัก'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMainCategory = newValue;
                  if (_selectedSecondaryCategory == newValue) {
                    _selectedSecondaryCategory = null;
                  }
                });
              },
              decoration: const InputDecoration(border: UnderlineInputBorder()),
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            _buildLabel('หมวดหมู่รอง'),
            DropdownButtonFormField<String>(
              initialValue: _selectedSecondaryCategory,
              hint: const Text('เลือกหมวดหมู่รอง'),
              items: _categories
                  .where((category) => category != _selectedMainCategory)
                  .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  })
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSecondaryCategory = newValue;
                });
              },
              decoration: const InputDecoration(border: UnderlineInputBorder()),
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeLevelCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('เลือกระดับอายุ'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAgeLevel,
                    hint: const Text('เลือกระดับอายุ'),
                    items: _ageLevels.map((ageLevel) {
                      return DropdownMenuItem(
                        value: ageLevel,
                        child: Text(ageLevel),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedAgeLevel = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('ข้อมูลระดับอายุ'),
                        content: const Text(
                          'All Ages: เหมาะกับทุกเพศทุกวัย\n'
                          '13+: เนื้อหามีความรุนแรงบ้าง\n'
                          '15+: เนื้อหาสำหรับผู้ใหญ่\n'
                          '17+: เกี่ยวกับเรื่องเพศและความรุนแรง',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ปิด'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _validateAndNavigate,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF26A69A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 22),
      ),
      child: const Text(
        'สร้าง',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF26A69A),
      ),
    );
  }
}
