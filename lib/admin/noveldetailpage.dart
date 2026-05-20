import 'package:mie_project/services/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/admin/adminNovelAction.dart';
import 'package:mie_project/screen/read_novel.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/models/novel.dart';

class NovelDetailPage extends StatefulWidget {
  final int novelId;
  final String title;

  const NovelDetailPage({
    super.key,
    required this.novelId,
    required this.title,
  });

  @override
  State<NovelDetailPage> createState() => _NovelDetailPageState();
}

class _NovelDetailPageState extends State<NovelDetailPage> {
  Novel? novelDetail;
  bool isLoadingNovelDetail = true;

  int warningCount = 0;

  List<Map<String, dynamic>> episodes = [];
  bool isLoadingEpisodes = true;

  final int currentUserId = 1;

  @override
  void initState() {
    super.initState();
    _loadNovelDetail();
    _loadWarningCount();
    loadEpisodes();
  }

  Future<void> _loadWarningCount() async {
    try {
      final count = await DBHelper.getNovelWarningCount(widget.novelId);
      if (mounted) {
        setState(() {
          warningCount = count;
        });
      }
    } catch (e) {
      print('Admin: Error loading warning count: $e');
    }
  }

  Future<void> _loadNovelDetail() async {
    try {
      final Map<String, dynamic>? map = await DBHelper.getNovelDetail(
        widget.novelId,
      );
      if (mounted) {
        setState(() {
          novelDetail = map != null ? Novel.fromMap(map) : null;
          isLoadingNovelDetail = false;
        });
        _loadWarningCount();
      }
    } catch (e) {
      print('Admin: Error loading novel detail: $e');
      if (mounted) {
        setState(() => isLoadingNovelDetail = false);
      }
    }
  }

  Future<void> loadEpisodes() async {
    try {
      final data = await DBHelper.getEpisodesByNovelId(widget.novelId);
      setState(() {
        episodes = data;
        isLoadingEpisodes = false;
      });
    } catch (e) {
      print('Admin: Error loading episodes: $e');
      if (mounted) {
        setState(() => isLoadingEpisodes = false);
      }
    }
  }

  // ***************************************************************
  // แก้ไข: _showChapterActions - เหลือแค่ ซ่อน/ยกเลิกการเผยแพร่ และ ลบ chapter
  // ***************************************************************
  void _showChapterActions(
    BuildContext context,
    int chapterId,
    String chapterTitle,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'จัดการบท: "$chapterTitle"',
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 1. ซ่อน/ยกเลิกการเผยแพร่
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: Text('ซ่อน/ยกเลิกการเผยแพร่', style: GoogleFonts.prompt()),
              onTap: () {
                Navigator.pop(context);
                _toggleChapterPublish(chapterId, chapterTitle);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(
                'ลบ chapter',
                style: GoogleFonts.prompt(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteChapter(chapterId, chapterTitle);
              },
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันใหม่: จัดการการลบ Chapter พร้อม Pop-up ยืนยัน
  Future<void> _deleteChapter(int chapterId, String chapterTitle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ยืนยันการลบ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการลบ Chapter "$chapterTitle" ออกจากระบบอย่างถาวรหรือไม่? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ลบถาวร', style: GoogleFonts.prompt(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DBHelper.deleteChapter(chapterId: chapterId); // เรียกใช้เมธอดลบ
        await loadEpisodes(); // รีโหลดรายการ Chapter เพื่ออัปเดต UI

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chapter "$chapterTitle" ถูกลบเรียบร้อยแล้ว'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error deleting chapter: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาดในการลบ Chapter: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ฟังก์ชันใหม่: เพื่อจัดการการเปลี่ยนสถานะการเผยแพร่
  Future<void> _toggleChapterPublish(int chapterId, String chapterTitle) async {
    final chapter = episodes.firstWhere((e) => e['chapter_id'] == chapterId);

    final bool currentStatus = chapter['is_published'] == 1;
    final bool newStatus = !currentStatus;

    String action = newStatus ? 'เผยแพร่' : 'ซ่อน';

    try {
      await DBHelper.updateChapterPublishStatus(chapterId, newStatus);

      await loadEpisodes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บท "$chapterTitle" ถูก $action เรียบร้อยแล้ว'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error toggling chapter publish status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการดำเนินการ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // ***************************************************************

  // -----------------------------------------------------------------
  // ฟังก์ชัน: ดำเนินการแบน/เลิกแบนทันที (ไม่มี Notification/Snackbar)
  // -----------------------------------------------------------------
  Future<void> _toggleBanNovel() async {
    final bool isCurrentlyBanned = novelDetail?.isBanned ?? false;
    final bool targetStatus = !isCurrentlyBanned;

    String successMessage;

    try {
      // **ไม่มีการเรียกใช้ DBHelper.createNotification()**
      await DBHelper.updateNovelBanStatus(widget.novelId, targetStatus);

      if (targetStatus) {
        successMessage = "นิยายถูกแบนเรียบร้อย ✅ (ซ่อนจากผู้ใช้แล้ว)";
      } else {
        successMessage = "นิยายถูกเลิกแบนเรียบร้อย 🟢 (กลับมาแสดงแล้ว)";
      }

      await _loadNovelDetail(); // รีโหลดข้อมูลเพื่ออัปเดต UI

      // **Snackbar ยืนยันการดำเนินการเท่านั้น (ถ้ามีในโค้ดเดิมของคุณ)**
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: targetStatus ? Colors.red[400] : Colors.green[400],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการดำเนินการ: $e")),
        );
      }
    }
  }

  // -----------------------------------------------------------------
  // Widget: Novel Header (เหมือนเดิม)
  // -----------------------------------------------------------------
  Widget _buildNovelHeader() {
    final String? coverImagePath = novelDetail?.coverImage;
    final bool isBanned = novelDetail?.isBanned ?? false;
    final int currentWarningCount = warningCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (coverImagePath != null && coverImagePath.isNotEmpty)
                      ? buildCoverImage(
                          coverImagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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
                if (isBanned)
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black54,
                    ),
                    child: Text(
                      'ถูกแบน',
                      style: GoogleFonts.prompt(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (currentWarningCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'เคยถูกเตือนแล้ว ${currentWarningCount} ครั้ง',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'ยังไม่เคยมีคำเตือน',
                style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 12),

          Text(
            novelDetail?.title ?? widget.title,
            style: GoogleFonts.prompt(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isBanned ? Colors.red[700] : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          Text(
            novelDetail?.writerName ?? 'ไม่ทราบผู้เขียน',
            style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),

          Text(
            novelDetail?.description ?? 'ไม่มีคำอธิบาย',
            style: GoogleFonts.prompt(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Widget: Build (หน้าจอหลัก)
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isBanned = novelDetail?.isBanned ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.title,
          style: GoogleFonts.prompt(fontSize: 18, color: Colors.black),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isBanned ? Colors.green[400] : Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: isLoadingNovelDetail
                  ? null
                  : () async {
                      final selected = await showMenu<String>(
                        context: context,
                        position: const RelativeRect.fromLTRB(200, 80, 20, 0),
                        items: [
                          const PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'เครื่องมือผู้ดูแล',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'go_to_report',
                            child: Text(
                              isBanned ? '🟢 เลิกแบนนิยาย' : '🚨 แบนนิยาย',
                              style: GoogleFonts.prompt(),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'go_to_report_warn',
                            child: Text(
                              '⚠️ เตือนผู้เขียน',
                              style: GoogleFonts.prompt(),
                            ),
                          ),
                          // *** ลบ PopupMenuItem<String> 'report_manage' (จัดการคำร้อง) ออกไปแล้ว ***
                        ],
                      );

                      if (selected == null) return;

                      final novelTitle = novelDetail?.title ?? widget.title;
                      final bool currentIsBanned =
                          novelDetail?.isBanned ?? false;

                      switch (selected) {
                        case 'go_to_report':
                          if (currentIsBanned) {
                            await _toggleBanNovel();
                          } else {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminNovelActionPage(
                                  novelId: widget.novelId,
                                  initialAction: selected,
                                  novelTitle: novelTitle,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadNovelDetail();
                            }
                          }
                          break;

                        case 'go_to_report_warn':
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminNovelActionPage(
                                novelId: widget.novelId,
                                initialAction: selected,
                                novelTitle: novelTitle,
                              ),
                            ),
                          );

                          if (result == true) {
                            _loadNovelDetail();
                          }
                          break;
                      }
                    },
              child: Text('จัดการ', style: GoogleFonts.prompt(fontSize: 14)),
            ),
          ),
        ],
      ),

      body: isLoadingNovelDetail
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildNovelHeader(),

                isLoadingEpisodes
                    ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : episodes.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Text(
                            "ยังไม่มีตอนในเรื่องนี้ 📝",
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Text(
                                'รายการตอนทั้งหมด (${episodes.length} ตอน)',
                                style: GoogleFonts.prompt(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemCount: episodes.length,
                                itemBuilder: (context, index) {
                                  final ep = episodes[index];
                                  final isPublished = ep['is_published'] == 1;
                                  final chapterId = ep['chapter_id'] as int;
                                  final chapterTitle = ep['title'] as String;

                                  return ListTile(
                                    leading: Icon(
                                      isPublished
                                          ? Icons.check_circle_outline
                                          : Icons.drafts_outlined,
                                      color: isPublished
                                          ? const Color(0xFF26A69A)
                                          : Colors.orange,
                                    ),
                                    title: Text(
                                      'ตอนที่ ${ep['chapter_number'] ?? ep['episode_number']}. $chapterTitle',
                                      style: GoogleFonts.prompt(
                                        fontSize: 16,
                                        color: isPublished
                                            ? Colors.black87
                                            : Colors.grey[600],
                                        fontWeight: isPublished
                                            ? FontWeight.normal
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        _showChapterActions(
                                          context,
                                          chapterId,
                                          chapterTitle,
                                        );
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReadNovelPage(
                                            novelId: widget.novelId,
                                            chapterNumber: ep['chapter_number']
                                                .toString(),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
    );
  }
}
