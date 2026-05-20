import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/services/image_helper.dart';

class EditNovelScreen extends StatefulWidget {
  final int novelId;

  const EditNovelScreen({super.key, required this.novelId});

  @override
  State<EditNovelScreen> createState() => _EditNovelScreenState();
}

class _EditNovelScreenState extends State<EditNovelScreen> {
  final _titleController = TextEditingController();
  final _penNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _categories = [];
  String? _selectedMainCategory;
  String? _selectedSecondaryCategory;
  String? _selectedAgeLevel;

  // Image state
  String? _existingCoverPath; // path already saved in DB
  String? _newImagePath;      // newly picked file path (native)
  Uint8List? _newWebImage;    // newly picked bytes (web)

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _ageLevels = ['ทุกวัย', '13+', '15+', '18+'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _penNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        DBHelper.getNovelById(widget.novelId),
        DBHelper.getAllCategoryNames(),
      ]);

      final novel = results[0] as Map<String, dynamic>?;
      final categories = results[1] as List<String>;

      if (novel == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get category names for pre-selection
      String? mainCatName;
      String? secCatName;
      if (novel['category_id'] != null) {
        final allCats = await DBHelper.getAllCategories();
        for (final cat in allCats) {
          if (cat['category_id'] == novel['category_id']) mainCatName = cat['category_name'];
          if (cat['category_id'] == novel['secondary_category_id']) secCatName = cat['category_name'];
        }
      }

      if (mounted) {
        setState(() {
          _titleController.text = novel['title'] ?? '';
          _penNameController.text = novel['writer_name'] ?? '';
          _descriptionController.text = novel['description'] ?? '';
          _selectedAgeLevel = novel['age_limit'];
          _existingCoverPath = novel['cover_image'];
          _categories = categories;
          _selectedMainCategory = mainCatName;
          _selectedSecondaryCategory = secCatName;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ EditNovelScreen load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newWebImage = bytes;
        _newImagePath = picked.path;
      });
    } else {
      setState(() {
        _newImagePath = picked.path;
      });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _penNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedMainCategory == null ||
        _selectedAgeLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final mainCatId = await DBHelper.getCategoryIdByName(_selectedMainCategory!);
      final secCatId = _selectedSecondaryCategory != null
          ? await DBHelper.getCategoryIdByName(_selectedSecondaryCategory!)
          : null;

      if (mainCatId == null) throw Exception('ไม่พบ ID หมวดหมู่');

      // Determine final cover path
      String? coverPath;
      if (_newImagePath != null && _newImagePath!.isNotEmpty) {
        if (kIsWeb) {
          coverPath = _newImagePath; // on web just store the path/name
        } else {
          final fileName = _newImagePath!.split('/').last;
          coverPath = await DBHelper.copyAssetToFile(_newImagePath!, fileName);
        }
      }

      await DBHelper.updateNovel(
        novelId: widget.novelId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        writerName: _penNameController.text.trim(),
        ageLimit: _selectedAgeLevel!,
        mainCategoryId: mainCatId,
        secondaryCategoryId: secCatId,
        coverImagePath: coverPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกข้อมูลนิยายสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // return true → triggers reload
      }
    } catch (e) {
      print('❌ EditNovelScreen save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ บันทึกล้มเหลว: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF26A69A),
          title: const Text('แก้ไขนิยาย', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'แก้ไขนิยาย',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCoverCard(),
              const SizedBox(height: 16),
              _buildFormCard(),
              const SizedBox(height: 16),
              _buildCategoryCard(),
              const SizedBox(height: 16),
              _buildAgeLevelCard(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverCard() {
    Widget imageWidget;

    if (_newWebImage != null) {
      imageWidget = Image.memory(_newWebImage!, height: 180, width: 180, fit: BoxFit.cover);
    } else if (_newImagePath != null && _newImagePath!.isNotEmpty) {
      imageWidget = buildCoverImage(_newImagePath!, height: 180, width: 180, fit: BoxFit.cover);
    } else if (_existingCoverPath != null && _existingCoverPath!.isNotEmpty) {
      imageWidget = buildCoverImage(_existingCoverPath!, height: 180, width: 180, fit: BoxFit.cover);
    } else {
      imageWidget = Column(
        children: [
          Image.asset('assets/images/up_cover.png', height: 180, width: 180, fit: BoxFit.cover),
          const SizedBox(height: 8),
          const Text('คลิกเพื่อเปลี่ยนภาพปก', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('ปกนิยาย'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageWidget,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text('แตะเพื่อเปลี่ยนรูปปก', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              decoration: const InputDecoration(hintText: 'ชื่อเรื่อง', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 16),
            _buildLabel('นามปากกา'),
            TextField(
              controller: _penNameController,
              decoration: const InputDecoration(hintText: 'นามปากกา', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 16),
            _buildLabel('คำนำ / รายละเอียด'),
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
              isExpanded: true,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() {
                _selectedMainCategory = v;
                if (_selectedSecondaryCategory == v) _selectedSecondaryCategory = null;
              }),
              decoration: const InputDecoration(border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 16),
            _buildLabel('หมวดหมู่รอง (ไม่บังคับ)'),
            DropdownButtonFormField<String>(
              initialValue: _selectedSecondaryCategory,
              hint: const Text('เลือกหมวดหมู่รอง'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('— ไม่ระบุ —')),
                ..._categories
                    .where((c) => c != _selectedMainCategory)
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _selectedSecondaryCategory = v),
              decoration: const InputDecoration(border: UnderlineInputBorder()),
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
            _buildLabel('ระดับอายุ'),
            DropdownButtonFormField<String>(
              initialValue: _selectedAgeLevel,
              hint: const Text('เลือกระดับอายุ'),
              isExpanded: true,
              items: _ageLevels.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) => setState(() => _selectedAgeLevel = v),
              decoration: const InputDecoration(border: UnderlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF26A69A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('บันทึกการแก้ไข',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF26A69A)),
    );
  }
}
