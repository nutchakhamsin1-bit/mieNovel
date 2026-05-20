import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/screen/comment.dart';
import 'package:mie_project/screen/report.dart';

class ReadNovelPage extends StatefulWidget {
  final int novelId;
  final String chapterNumber;

  const ReadNovelPage({
    super.key,
    required this.novelId,
    required this.chapterNumber,
  });

  @override
  State<ReadNovelPage> createState() => _ReadNovelPageState();
}

class _ReadNovelPageState extends State<ReadNovelPage>
    with TickerProviderStateMixin {
  String _chapterTitle = 'กำลังโหลด...';
  String _chapterContent = '';
  bool _isLoading = true;

  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black87;
  double _fontSize = 16.0;
  String _currentFontName = 'Taviraj';
  late TextStyle _currentStyle;

  late TabController _tabController;
  int _likeCount = 0;
  int _viewCount = 0;
  bool _hasLiked = false;
  int? _userId;
  int? _chapterId;

  final List<Map<String, dynamic>> _fontOptions = [
    {'name': 'Taviraj', 'style': GoogleFonts.taviraj()},
    {'name': 'Prompt', 'style': GoogleFonts.prompt()},
    {'name': 'Sarabun', 'style': GoogleFonts.sarabun()},
    {'name': 'Charm', 'style': GoogleFonts.charm()},
    {'name': 'Mali', 'style': GoogleFonts.mali()},
    {'name': 'Bai Jamjuree', 'style': GoogleFonts.baiJamjuree()},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentStyle = GoogleFonts.taviraj(
      fontSize: _fontSize,
      height: 1.5,
      color: _textColor,
    );
    _loadChapterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------- โหลดข้อมูลตอน + View + Like ----------------------
  Future<void> _loadChapterData() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('user_id');

      Map<String, dynamic>? chapterData;

      if (widget.chapterNumber == 'ล่าสุด') {
        final allChapters = await DBHelper.getChapters(widget.novelId);
        if (allChapters.isNotEmpty) {
          chapterData = allChapters.last;
        }
      } else {
        final int chapterNumber = int.tryParse(widget.chapterNumber) ?? 1;
        chapterData = await DBHelper.getChapterByNumber(
          novelId: widget.novelId,
          chapterNumber: chapterNumber,
        );
      }

      if (chapterData != null) {
        final chapterId = (chapterData['chapter_id'] ?? 0) as int;
        _chapterId = chapterId;

        // ✅ เพิ่มจำนวนวิว + บันทึก event การอ่าน
        await DBHelper.incrementChapterViews(chapterId);
        await DBHelper.logChapterView(
          chapterId: chapterId,
          userId: _userId,
        );
        final viewCount = await DBHelper.getChapterViews(chapterId);

        // ✅ โหลดจำนวนไลค์
        final likeCount = await DBHelper.getChapterLikes(chapterId);

        // ✅ ตรวจว่าผู้ใช้คนนี้เคยไลค์หรือยัง
        bool userLiked = false;
        if (_userId != null) {
          userLiked = await DBHelper.getUserLikeStatus(_userId!, chapterId);
        }

        setState(() {
          _chapterTitle = chapterData!['title'] ?? 'ไม่มีชื่อบท';
          _chapterContent = chapterData['content'] ?? 'ไม่มีเนื้อหาในบทนี้';
          _viewCount = viewCount;
          _likeCount = likeCount;
          _hasLiked = userLiked;
          _isLoading = false;
        });

      } else {
        setState(() {
          _chapterTitle = 'ไม่พบบทที่ ${widget.chapterNumber}';
          _chapterContent = 'ไม่มีข้อมูลในฐานข้อมูลสำหรับบทนี้';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading chapter: $e');
      setState(() {
        _chapterTitle = 'เกิดข้อผิดพลาด';
        _chapterContent = 'ไม่สามารถโหลดข้อมูลได้';
        _isLoading = false;
      });
    }
  }

  // ---------------------- Like ----------------------
  Future<void> _handleLike() async {
    if (_userId == null || _chapterId == null) return;

    if (_hasLiked) {
      // ✅ ยกเลิกไลค์
      await DBHelper.removeUserLike(_userId!, _chapterId!);
      setState(() {
        _hasLiked = false;
        _likeCount--;
      });
    } else {
      // ✅ กดไลค์
      await DBHelper.setUserLikeStatus(_userId!, _chapterId!, true);
      setState(() {
        _hasLiked = true;
        _likeCount++;
      });
    }
  }

  // ---------------------- Font Settings ----------------------
  void _updateReadingStyle({
    Color? newBgColor,
    Color? newTextColor,
    String? newFontName,
    TextStyle? newBaseStyle,
    double? newFontSize,
  }) {
    setState(() {
      _backgroundColor = newBgColor ?? _backgroundColor;
      _textColor = newTextColor ?? _textColor;
      _fontSize = newFontSize ?? _fontSize;
      _currentFontName = newFontName ?? _currentFontName;

      TextStyle baseStyle = newBaseStyle ?? _currentStyle;
      if (newFontName != null) {
        final selectedFont = _fontOptions.firstWhere(
          (opt) => opt['name'] == newFontName,
          orElse: () => _fontOptions.first,
        );
        baseStyle = selectedFont['style'] as TextStyle;
      }

      _currentStyle = baseStyle.copyWith(
        fontSize: _fontSize,
        height: 1.5,
        color: _textColor,
      );
    });
  }

  void _showFontSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'ตัวอักษร'),
                        Tab(text: 'พื้นหลัง'),
                      ],
                      labelColor: const Color(0xFF26A69A),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF26A69A),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFontTab(setModalState),
                          _buildBackgroundTab(setModalState),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFontTab(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เลือกรูปแบบตัวอักษร',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _fontOptions.map((option) {
            return ElevatedButton(
              onPressed: () {
                setModalState(() {
                  _updateReadingStyle(
                    newFontName: option['name'],
                    newBaseStyle: option['style'],
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentFontName == option['name']
                    ? const Color(0xFF26A69A)
                    : Colors.grey[200],
              ),
              child: Text(option['name'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'ขนาดตัวอักษร',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _fontSize,
          min: 12,
          max: 28,
          divisions: 8,
          activeColor: const Color(0xFF26A69A),
          label: _fontSize.round().toString(),
          onChanged: (value) {
            setModalState(() {
              _fontSize = value;
            });
            _updateReadingStyle(newFontSize: value);
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundTab(StateSetter setModalState) {
    final colorOptions = [
      {'color': Colors.white, 'label': 'ขาว'},
      {'color': const Color(0xFFFDF6E3), 'label': 'ครีม'},
      {'color': const Color(0xFFE0F2F1), 'label': 'เขียวมิ้นต์'},
      {'color': const Color(0xFF2B2B2B), 'label': 'ดำ'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colorOptions.map((opt) {
        final color = opt['color'] as Color;
        final isDark = color == const Color(0xFF2B2B2B);
        final selected = _backgroundColor == color;
        return InkWell(
          onTap: () {
            setModalState(() {
              _updateReadingStyle(
                newBgColor: color,
                newTextColor: isDark ? Colors.white : Colors.black87,
              );
            });
          },
          child: Container(
            width: 100,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: selected ? const Color(0xFF26A69A) : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              (opt['label'] ?? '') as String,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: _textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: _textColor),
                    onPressed: _showFontSettings,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          _chapterTitle,
                          style: GoogleFonts.prompt(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '👁️ $_viewCount views',
                          style: TextStyle(color: _textColor.withValues(alpha: 0.7)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(_chapterContent, style: _currentStyle),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInteractiveButton(
                              icon: Icons.thumb_up_alt_outlined,
                              count: _likeCount,
                              isActive: _hasLiked,
                              activeColor: Colors.green,
                              onTap: _handleLike,
                            ),
                            _buildCommentButton(),
                            // ⭐ NEW: ปุ่มสำหรับรายงานเนื้อหา
                            _buildReportButton(),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? activeColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? activeColor : _textColor),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(color: isActive ? activeColor : _textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton() {
    return InkWell(
      onTap: () async => {
      print('Navigating to comments for chapter ID: $_chapterId, Chapter Number: ${widget.chapterNumber}'),
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CommentPage(chapterId: _chapterId ?? 0, chapterNumber: widget.chapterNumber,)),
      )
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF26A69A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.comment_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'แสดงความคิดเห็น',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ NEW: เมธอดสำหรับสร้างปุ่ม Report
  Widget _buildReportButton() {
    return InkWell(
      onTap: () {
        if (_chapterId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถรายงานได้: ข้อมูลบทไม่สมบูรณ์')),
          );
          return;
        }

        print('Navigating to report page for novel ID: ${widget.novelId}, chapter ID: $_chapterId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Report(
              novelId: widget.novelId,
              chapterId: _chapterId!,
              chapterTitle: _chapterTitle,         
              reportingUserId: _userId!,   
              ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, color: Colors.red),
            const SizedBox(width: 6),
            Text(
              'รายงาน',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}