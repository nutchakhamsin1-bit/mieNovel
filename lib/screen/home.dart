import 'package:mie_project/services/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/models/novel.dart';
import 'package:mie_project/screen/search.dart';
import 'package:mie_project/screen/show_chapter.dart';
import 'package:mie_project/screen/view_all_novels_screen.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/services/novel_type.dart';
import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/app_logger.dart';
import 'package:mie_project/utils/session_manager.dart';
import 'book_shelf.dart';
import 'write.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Novel> _hotNovels = [];
  List<Novel> _latestNovels = [];
  List<Novel> _aiRecommendedNovels = [];
  List<Map<String, dynamic>> _recentReads = const [];
  bool _isLoading = true;
  String? _aiPreferredGenre;

  final List<Widget> _pages = [
    SizedBox.shrink(),
    BookShelfScreen(),
    WriteScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchNovelData();
  }

  Future<void> _fetchNovelData() async {
    AppLogger.debug('Loading novel data...');
    try {
      final hotData = await DBHelper.getHotNovels();
      final latestData = await DBHelper.getLatestNovels();
      final currentUser = await DBHelper.getLoggedInUser();

      List<Novel> aiData = [];
      String? aiGenre;

      if (currentUser != null && currentUser['ai_analysis_data'] != null) {
        aiGenre = currentUser['ai_analysis_data'];
        aiData = await DBHelper.getRecommendedNovelsByAI(aiGenre!);
      }

      if (aiData.isEmpty) {
        aiData = latestData;
        aiGenre = 'อัพเดตล่าสุด';
      }

      List<Map<String, dynamic>> recent = const [];
      final userId = await SessionManager.getUserId();
      if (userId != null) {
        recent = await DBHelper.getRecentReadHistory(userId, limit: 6);
      }

      setState(() {
        _hotNovels = hotData;
        _latestNovels = latestData;
        _aiPreferredGenre = aiGenre;
        _aiRecommendedNovels = aiData;
        _recentReads = recent;
        _isLoading = false;
      });
    } catch (e, st) {
      AppLogger.error('Error fetching novel data', e, st);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildNovelSection({
    required String title,
    required List<Novel> novels,
    required IconData icon,
    required NovelListType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
             
                child: Row(
                  children: [
                    Icon(icon, color: const Color(0xFF26A69A)),
                    const SizedBox(width: 8),
                    Expanded(
                   
                      child: Text(
                        title,
                        style: GoogleFonts.sarabun(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis, 
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewAllNovelsScreen(
                        title: title,
                        listType: type,
                        categoryFilter: _aiPreferredGenre,
                      ),
                    ),
                  );
                },
                child: Text(
                  'ดูทั้งหมด',
                  style: GoogleFonts.prompt(
                    color: const Color(0xFF26A69A),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 220,
          child: novels.isEmpty
              ? Center(
                  child: Text(
                    'ไม่มีนิยายในหมวดหมู่นี้',
                    style: GoogleFonts.sarabun(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: novels.length,
                  itemBuilder: (context, index) {
                    final novel = novels[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChapterListScreen(
                                novelId: novel.novelId,
                                novelTitle: novel.title,
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 110,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 160,
                                width: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300],
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(1, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      novel.coverImage != null &&
                                          novel.coverImage!.isNotEmpty
                                      ? buildCoverImage(
                                          novel.coverImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.red,
                                                    size: 40,
                                                  ),
                                                );
                                              },
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.book_outlined,
                                            color: Colors.grey,
                                            size: 40,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 40,
                                child: Text(
                                  novel.title,
                                  style: GoogleFonts.sarabun(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                height: 15,
                                child: Text(
                                  novel.writerName,
                                  style: GoogleFonts.sarabun(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {
        'icon': Icons.auto_awesome,
        'name': 'แฟนตาซี',
        'color': Colors.purple[300],
        'categoryName': 'แฟนตาซี',
      },
      {
        'icon': Icons.favorite,
        'name': 'โรแมนติก',
        'color': Colors.pink[300],
        'categoryName': 'โรแมนติก',
      },
      {
        'icon': Icons.science_rounded,
        'name': 'ไซไฟ',
        'color': Colors.blue[300],
        'categoryName': 'ไซไฟ',
      },
      {
        'icon': Icons.mood_bad_outlined,
        'name': 'สยองขวัญ',
        'color': Colors.grey[700],
        'categoryName': 'สยองขวัญ',
      },
      {
        'icon': Icons.psychology,
        'name': 'สืบสวน',
        'color': Colors.amber[700],
        'categoryName': 'สืบสวน',
      },
      {
        'icon': Icons.sports_martial_arts,
        'name': 'แอคชั่น',
        'color': Colors.red[300],
        'categoryName': 'แอคชั่น',
      },
      {
        'icon': Icons.sentiment_very_satisfied,
        'name': 'คอมเมดี้',
        'color': Colors.orange[300],
        'categoryName': 'คอมเมดี้',
      },
      {
        'icon': Icons.history_edu,
        'name': 'ย้อนยุค',
        'color': Colors.brown[300],
        'categoryName': 'ย้อนยุค',
      },
      {
        'icon': Icons.military_tech,
        'name': 'กำลังภายใน',
        'color': Colors.red[700],
        'categoryName': 'กำลังภายใน',
      },
      {
        'icon': Icons.theater_comedy,
        'name': 'ดราม่า',
        'color': Colors.deepPurple[300],
        'categoryName': 'ดราม่า',
      },
      {
        'icon': Icons.favorite_border,
        'name': 'วาย',
        'color': Colors.pink[200],
        'categoryName': 'วาย (Yaoi / BL)',
      },
      {
        'icon': Icons.favorite_border,
        'name': 'ยูริ',
        'color': Colors.pink[100],
        'categoryName': 'ยูริ (Yuri / GL)',
      },
      {
        'icon': Icons.games,
        'name': 'ระบบ/เกม',
        'color': Colors.green[400],
        'categoryName': 'ระบบ / เกม',
      },
      {
        'icon': Icons.travel_explore,
        'name': 'ต่างโลก',
        'color': Colors.indigo[300],
        'categoryName': 'ต่างโลก (Isekai)',
      },
      {
        'icon': Icons.local_cafe,
        'name': 'ชีวิตประจำวัน',
        'color': Colors.brown[200],
        'categoryName': 'ชีวิตประจำวัน',
      },
      {
        'icon': Icons.school,
        'name': 'โรงเรียน',
        'color': Colors.blue[300],
        'categoryName': 'โรงเรียน',
      },
      {
        'icon': Icons.star,
        'name': 'เกาหลี/ไอดอล',
        'color': Colors.purple[200],
        'categoryName': 'เกาหลี / ไอดอล',
      },
      {
        'icon': Icons.short_text,
        'name': 'นิยายสั้น',
        'color': Colors.grey[600],
        'categoryName': 'นิยายสั้น',
      },
      {
        'icon': Icons.auto_awesome_motion,
        'name': 'วายแฟนตาซี',
        'color': Colors.deepPurple[200],
        'categoryName': 'นิยายวายแฟนตาซี',
      },
      {
        'icon': Icons.emoji_emotions,
        'name': 'รักวัยรุ่น',
        'color': Colors.pink[200],
        'categoryName': 'นิยายรักวัยรุ่น',
      },
      {
        'icon': Icons.search,
        'name': 'สืบสวนแฟนตาซี',
        'color': Colors.teal[300],
        'categoryName': 'สืบสวนแฟนตาซี',
      },
      {
        'icon': Icons.work,
        'name': 'ธุรกิจ/การทำงาน',
        'color': Colors.blueGrey[300],
        'categoryName': 'ธุรกิจ / ชีวิตการทำงาน',
      },
      {
        'icon': Icons.emergency,
        'name': 'ระทึกขวัญ',
        'color': Colors.red[900],
        'categoryName': 'ระทึกขวัญ (Thriller)',
      },
      {
        'icon': Icons.blur_on,
        'name': 'เวทมนตร์ร่วมสมัย',
        'color': Colors.deepPurple[400],
        'categoryName': 'เวทมนตร์ร่วมสมัย',
      },
      {
        'icon': Icons.rocket_launch,
        'name': 'ไซไฟโรแมนติก',
        'color': Colors.cyan[300],
        'categoryName': 'ไซไฟโรแมนติก',
      },
      {
        'icon': Icons.mood_bad,
        'name': 'ตลกร้าย',
        'color': Colors.deepOrange[300],
        'categoryName': 'ตลกร้าย (Dark Comedy)',
      },
      {
        'icon': Icons.psychology_alt,
        'name': 'ปรัชญา/จิตวิทยา',
        'color': Colors.indigo[400],
        'categoryName': 'ปรัชญา / จิตวิทยา',
      },
      {
        'icon': Icons.memory,
        'name': 'AI/เทคโนโลยี',
        'color': Colors.blue[400],
        'categoryName': 'AI / เทคโนโลยี',
      },
      {
        'icon': Icons.token,
        'name': 'แนวทดลอง',
        'color': Colors.deepPurple[300],
        'categoryName': 'แนวทดลอง (Experimental)',
      },
      {
        'icon': Icons.public,
        'name': 'สงคราม/การเมือง',
        'color': Colors.red[800],
        'categoryName': 'สงคราม / การเมือง',
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 8, 
      itemBuilder: (context, index) {
        if (index == 7) {
        
          return InkWell(
            onTap: () {
            
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.9,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) => Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'หมวดหมู่ทั้งหมด',
                              style: GoogleFonts.sarabun(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, idx) {
                            final category = categories[idx];
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context); // ปิด bottom sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewAllNovelsScreen(
                                      title: category['name'] as String,
                                      listType: NovelListType.category,
                                      categoryFilter: category['categoryName'] as String,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (category['color'] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      category['icon'] as IconData,
                                      color: category['color'] as Color?,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category['name'] as String,
                                    style: GoogleFonts.sarabun(fontSize: 12, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.grid_view,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ดูทั้งหมด',
                  style: GoogleFonts.sarabun(fontSize: 12, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final category = categories[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllNovelsScreen(
                  title: category['name'] as String,
                  listType: NovelListType.category,
                  categoryFilter: category['categoryName'] as String,
                ),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (categories[index]['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categories[index]['icon'] as IconData,
                  color: categories[index]['color'] as Color?,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                categories[index]['name'] as String,
                style: GoogleFonts.sarabun(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentReads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.history, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'อ่านล่าสุด',
                style: GoogleFonts.sarabun(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _recentReads.length,
            itemBuilder: (context, index) {
              final entry = _recentReads[index];
              final cover = entry['cover_image'] as String?;
              final title = (entry['novel_title'] as String?) ?? 'ไม่มีชื่อ';
              final novelId = entry['novel_id'] as int?;
              if (novelId == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterListScreen(
                        novelId: novelId,
                        novelTitle: title,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: SizedBox(
                            width: 90,
                            height: 110,
                            child: cover != null && cover.isNotEmpty
                                ? buildCoverImage(cover, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.book),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: GoogleFonts.sarabun(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _currentIndex == 0
          ? _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF26A69A)),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'ค้นหานิยาย ผู้เขียน หมวดหมู่...',
                                  style: GoogleFonts.sarabun(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.tune,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _fetchNovelData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_recentReads.isNotEmpty)
                                  _buildRecentReads(),
                                const SizedBox(height: 8),
                                _buildNovelSection(
                                  title: 'นิยายมาแรง',
                                  novels: _hotNovels,
                                  icon: Icons.whatshot,
                                  type: NovelListType.hot,
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    'หมวดหมู่นิยาย',
                                    style: GoogleFonts.sarabun(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildCategoryGrid(),
                                const SizedBox(height: 24),
                                _buildNovelSection(
                                  title: 'อัพเดตล่าสุด',
                                  novels: _latestNovels,
                                  icon: Icons.update,
                                  type: NovelListType.latest,
                                ),
                                const SizedBox(height: 24),
                                _buildNovelSection(
                                  title: _aiPreferredGenre != null
                                      ? 'แนะนำสำหรับคุณ (${_aiPreferredGenre!})'
                                      : 'แนะนำสำหรับคุณ',
                                  novels: _aiRecommendedNovels,
                                  icon: Icons.star,
                                  type: NovelListType.recommended,
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
          : _pages[_currentIndex],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.react,
        backgroundColor: const Color(0xFF00897B),
        color: Colors.black,
        activeColor: Colors.white,
        items: const [
          TabItem(icon: Icons.home, title: 'หน้าหลัก'),
          TabItem(icon: Icons.book, title: 'รายการโปรด'),
          TabItem(icon: Icons.edit, title: 'การเขียน'),
          TabItem(icon: Icons.person, title: 'ฉัน'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
