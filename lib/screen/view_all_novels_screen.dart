import 'package:flutter/material.dart';
import 'package:mie_project/screen/show_chapter.dart';
import 'package:mie_project/services/novel_type.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/models/novel.dart';

class ViewAllNovelsScreen extends StatefulWidget {
  final String title;
  final NovelListType listType;
  final String? categoryFilter; // ใช้สำหรับ AI หรือ Category

  const ViewAllNovelsScreen({
    super.key,
    required this.title,
    required this.listType,
    this.categoryFilter,
  });

  @override
  State<ViewAllNovelsScreen> createState() => _ViewAllNovelsScreenState();
}

class _ViewAllNovelsScreenState extends State<ViewAllNovelsScreen> {
  late Future<List<Novel>> _novelsFuture;

  @override
  void initState() {
    super.initState();
    _novelsFuture = _fetchNovels();
  }

  Future<List<Novel>> _fetchNovels() async {
    try {
      switch (widget.listType) {
        case NovelListType.hot:
          return DBHelper.getHotNovels();

        case NovelListType.latest:
          return DBHelper.getLatestNovels();

        case NovelListType.recommended:
          // ✅ สำหรับ AI Recommendation
          if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
            print('🧠 Loading AI Recommended Novels for: ${widget.categoryFilter}');
            final result = await DBHelper.getRecommendedNovelsByAI(widget.categoryFilter!);
            print('✅ AI Recommended Novels Loaded: ${result.length}');
            return result;
          } else {
            print('⚠️ No AI category provided');
            return [];
          }

        case NovelListType.category:
          // ✅ สำหรับดูทั้งหมดของหมวดหมู่
          if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
            return await DBHelper.getNovelsByCategory(widget.categoryFilter!);
          } else {
            return [];
          }

        default:
          return [];
      }
    } catch (e) {
      print('❌ Error loading novels: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Novel>>(
        future: _novelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบรายการนิยาย'));
          }

          final novels = snapshot.data!;
          return ListView.builder(
            itemCount: novels.length,
            itemBuilder: (context, index) {
              final novel = novels[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.book, color: Colors.blueAccent),
                  title: Text(
                    novel.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('โดย ${novel.writerName}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
        },
      ),
    );
  }
}
