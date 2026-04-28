import 'dart:io';
import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/models/novel.dart';
import 'package:mie_project/screen/show_chapter.dart';
import 'package:mie_project/screen/view_all_novels_screen.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/services/novel_type.dart';
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
    print("🔹 เริ่มโหลดข้อมูลนิยาย...");
    try {
      final hotData = await DBHelper.getHotNovels();
      print('✅ Hot Novels: $hotData');

      final latestData = await DBHelper.getLatestNovels();
      print('✅ Latest Novels: $latestData');

      final currentUser = await DBHelper.getLoggedInUser();
      print('👤 Current User: $currentUser');

      List<Novel> aiData = [];
      String? aiGenre;

      if (currentUser != null && currentUser['ai_analysis_data'] != null) {
        aiGenre = currentUser['ai_analysis_data'];
        print('🧠 AI Preferred Genre: $aiGenre');
        aiData = await DBHelper.getRecommendedNovelsByAI(aiGenre!);
        print('✅ AI Recommended Novels: $aiData');
      }

      // ถ้าไม่มีนิยายแนะนำ ให้ใช้นิยายล่าสุดแทน
      if (aiData.isEmpty) {
        print('⚠️ No AI recommendations available, using latest novels instead');
        aiData = latestData;
        aiGenre = 'อัพเดตล่าสุด';
      }

      setState(() {
        _hotNovels = hotData;
        _latestNovels = latestData;
        _aiPreferredGenre = aiGenre;
        _aiRecommendedNovels = aiData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching novel data: $e');
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
                                      ? Image.file(
                                          File(novel.coverImage!),
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
                              color: Colors.grey.withOpacity(0.1),
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
                                      color: (category['color'] as Color).withOpacity(0.1),
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
                  color: (categories[index]['color'] as Color).withOpacity(0.1),
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

  // 🔍 Search (เหมือนเดิม)
  final TextEditingController _searchController = TextEditingController();
  List<Novel> _searchResults = [];
  bool _isSearching = false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final allNovels = [
      ..._hotNovels,
      ..._latestNovels,
      ..._aiRecommendedNovels,
    ];
    final results = allNovels
        .where(
          (novel) =>
              novel.title.toLowerCase().contains(query.toLowerCase()) ||
              novel.writerName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    setState(() {
      _searchResults = results;
    });
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'ไม่พบนิยายที่คุณค้นหา',
          style: GoogleFonts.sarabun(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final novel = _searchResults[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              child: novel.coverImage != null && novel.coverImage!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(novel.coverImage!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image);
                        },
                      ),
                    )
                  : const Icon(Icons.book),
            ),
            title: Text(
              novel.title,
              style: GoogleFonts.sarabun(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              novel.writerName,
              style: GoogleFonts.sarabun(fontSize: 14, color: Colors.grey[600]),
            ),
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
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                        child: TextField(
                          controller: _searchController,
                          onChanged: _performSearch,
                          decoration: InputDecoration(
                            hintText: 'ค้นหานิยาย...',
                            hintStyle: GoogleFonts.sarabun(
                              color: Colors.grey[400],
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF26A69A),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isSearching
                            ? _buildSearchResults()
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
