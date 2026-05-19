import 'package:flutter/material.dart';
import 'package:mie_project/services/image_helper.dart';
import 'package:mie_project/screen/show_chapter.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookShelfScreen extends StatefulWidget {
  const BookShelfScreen({super.key});

  @override
  State<BookShelfScreen> createState() => _BookShelfScreenState();
}

class _BookShelfScreenState extends State<BookShelfScreen> {
  late Future<int> _userIdFuture;
  Future<List<Map<String, dynamic>>>? _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _userIdFuture = _loadUserId();
  }

  Future<int> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    if (mounted) {
      setState(() {
        _favoritesFuture = userId > 0
            ? DBHelper.getFavoriteNovels(userId)
            : Future.value([]);
      });
    }
    return userId;
  }

  Future<void> _handleRefresh() async => await _loadUserId();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'ชั้นหนังสือของฉัน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<int>(
        future: _userIdFuture,
        builder: (context, userIdSnapshot) {
          if (userIdSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF26A69A)));
          }

          final currentUserId = userIdSnapshot.data ?? 0;

          if (currentUserId == 0) {
            return _buildEmptyState(
              icon: Icons.person_outline,
              title: 'ยังไม่ได้เข้าสู่ระบบ',
              subtitle: 'กรุณาเข้าสู่ระบบเพื่อดูนิยายที่คุณชื่นชอบ',
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF26A69A)));
              }

              if (snapshot.hasError) {
                return _buildEmptyState(
                  icon: Icons.error_outline,
                  title: 'เกิดข้อผิดพลาด',
                  subtitle: 'ไม่สามารถโหลดข้อมูลได้ ลองอีกครั้ง',
                  isError: true,
                );
              }

              final favorites = snapshot.data ?? [];

              if (favorites.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.bookmarks_outlined,
                  title: 'ชั้นหนังสือว่างเปล่า',
                  subtitle: 'ค้นหานิยายและกดบันทึกเพื่อเพิ่มที่นี่',
                );
              }

              return RefreshIndicator(
                onRefresh: _handleRefresh,
                color: const Color(0xFF26A69A),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF26A69A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_stories, size: 16, color: Color(0xFF26A69A)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${favorites.length} เรื่อง',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF26A69A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final novel = favorites[index];
                            final isBanned = novel['is_banned'] == 1;
                            return _NovelCoverItem(
                              novelId: novel['novel_id'] as int,
                              title: novel['title'] as String? ?? 'ไม่มีชื่อ',
                              coverImage: novel['cover_image'] as String?,
                              isBanned: isBanned,
                            );
                          },
                          childCount: favorites.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.58,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.shade50
                  : const Color(0xFF26A69A).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 56,
              color: isError ? Colors.red.shade300 : const Color(0xFF26A69A).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Novel Cover Item ───────────────────────────
class _NovelCoverItem extends StatelessWidget {
  final int novelId;
  final String title;
  final String? coverImage;
  final bool isBanned;

  const _NovelCoverItem({
    required this.novelId,
    required this.title,
    this.coverImage,
    this.isBanned = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChapterListScreen(
            novelId: novelId,
            novelTitle: title,
            isBanned: isBanned,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover ──
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // cover image
                    coverImage != null && coverImage!.isNotEmpty
                        ? buildCoverImage(
                            coverImage!,
                            fit: BoxFit.cover,
                            color: isBanned ? Colors.black54 : null,
                            colorBlendMode: isBanned ? BlendMode.darken : null,
                            errorBuilder: (_, __, ___) => _placeholderCover(),
                          )
                        : _placeholderCover(),

                    // gradient overlay at bottom for title legibility
                    if (!isBanned)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    // banned badge
                    if (isBanned)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ถูกแบน',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── Title ──
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: isBanned ? Colors.red.shade700 : const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 28, color: Color(0xFF80CBC4)),
      ),
    );
  }
}
