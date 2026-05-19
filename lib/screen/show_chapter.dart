import 'package:mie_project/services/image_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/screen/read_novel.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/models/novel.dart';

class Chapter {
  final int id;
  final String number;
  final String title;

  Chapter({required this.id, required this.number, required this.title});
}

class ChapterListScreen extends StatefulWidget {
  final int novelId;
  final String novelTitle;
  final bool isBanned;

  const ChapterListScreen({
    super.key,
    required this.novelId,
    required this.novelTitle,
    this.isBanned = false,
  });

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  // ... (State variables เหมือนเดิม) ...
  late Future<List<Chapter>> _chaptersFuture = Future.value([]); 
  late Future<Novel?> _novelDetailFuture;
  int? _userId; 
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _novelDetailFuture = _loadNovelDetail();
    
    // โหลด Chapters และตรวจสอบ Bookmark หลังจากโหลด Novel Detail เสร็จ
    _novelDetailFuture.then((_) {
      _chaptersFuture = _loadChapters(); 
      _checkBookmarkStatus();
    });
  }

  // -------------------------------------------------------------------
  // ⭐ เมธอดโหลดข้อมูล (ไม่มีการแก้ไขหลัก)
  // -------------------------------------------------------------------

  Future<Novel?> _loadNovelDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final tempUserId = prefs.getInt('user_id');
    setState(() {
      _userId = tempUserId;
    });

    try {
      final Map<String, dynamic>? map = await DBHelper.getNovelDetail(
        widget.novelId,
      );

      if (map == null) return null;

      await DBHelper.incrementNovelViews(widget.novelId); 
      
      return Novel.fromMap(map);
    } catch (e) {
      print('Error loading novel detail: $e');
      return null;
    }
  }

  Future<List<Chapter>> _loadChapters() async {
    try {
      final List<Map<String, dynamic>> maps = await DBHelper.getChapters(
        widget.novelId,
      );

      final List<Map<String, dynamic>> publishedMaps = maps.where((map) {
        final bool isPublished = map['is_published'] == 1;
        return isPublished;
      }).toList();

      final List<Chapter> chapters = publishedMaps.map((map) {
        return Chapter(
          id: map['chapter_id'] as int,
          number: (map['chapter_number'] as int).toString(),
          title: map['title'] as String,
        );
      }).toList();

      return chapters;
    } catch (e) {
      print('Error loading chapters: $e');
      return [];
    }
  }

  Future<void> _checkBookmarkStatus() async {
    if (_userId == null || _userId == 0) {
      return; 
    }
    
    final isBookmarked = await DBHelper.isNovelBookmarked(
      widget.novelId,
      _userId!,
    ); 

    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  // -------------------------------------------------------------------
  // ⭐ เมธอดที่แก้ไข: _toggleBookmark()
  // -------------------------------------------------------------------

  Future<void> _toggleBookmark() async {
    // 1. ตรวจสอบการเข้าสู่ระบบ
    if (_userId == null || _userId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อบันทึกนิยาย')),
        );
      }
      return;
    }
    
    // 2. จัดการ Logic เมื่อนิยายถูกแบน (isBanned = true)
    if (widget.isBanned) {
      if (!_isBookmarked) {
        // หากถูกแบน และยังไม่ได้บันทึก: ไม่อนุญาตให้บันทึกใหม่
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถบันทึกนิยายที่ถูกระงับได้')),
          );
        }
        return; // หยุดการทำงาน
      }
      // หากถูกแบน และบันทึกแล้ว: อนุญาตให้ไปขั้นตอนที่ 3 เพื่อยกเลิกการบันทึก
    }

    // 3. ดำเนินการ Toggle
    final newBookmarkStatus = !_isBookmarked;
    
    // อัปเดต UI ชั่วคราว
    setState(() {
      _isBookmarked = newBookmarkStatus;
    });

    try {
      if (newBookmarkStatus) {
        // บันทึกใหม่ (จะถูกเรียกก็ต่อเมื่อ !widget.isBanned หรือถูกแบนแต่ตอนแรกยังไม่บันทึก)
        // **หมายเหตุ:** Logic ที่ 2 ช่วยป้องกันการบันทึกใหม่เมื่อถูกแบนแล้ว
        await DBHelper.addBookmark(
          widget.novelId,
          _userId!,
        );
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('บันทึกเรื่องนี้แล้ว ⭐️')),
            );
        }
      } else {
        // ยกเลิกการบันทึก (อนุญาตให้ทำได้เสมอ)
        await DBHelper.removeBookmark(
          widget.novelId,
          _userId!,
        );
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ยกเลิกการบันทึกแล้ว')),
            );
        }
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      // ย้อนกลับสถานะ UI หากเกิดข้อผิดพลาด
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
        );
      }
    }
  }

  // -------------------------------------------------------------------
  // ⭐ Widget Builders (ไม่มีการแก้ไขหลัก)
  // -------------------------------------------------------------------

  Widget _buildCategoryTags(Novel? novelDetail) {
      final List<String> categories = [];

    if (novelDetail?.mainCategoryName != null &&
        novelDetail!.mainCategoryName!.isNotEmpty) {
      categories.add(novelDetail.mainCategoryName!);
    }

    if (novelDetail?.secondaryCategoryName != null &&
        novelDetail!.secondaryCategoryName!.isNotEmpty &&
        novelDetail.secondaryCategoryName != novelDetail.mainCategoryName) {
      categories.add(novelDetail.secondaryCategoryName!);
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0, 
        runSpacing: 4.0, 
        alignment: WrapAlignment.center, 
        children: categories.map((name) {
          return Chip(
            padding: EdgeInsets.zero,
            label: Text(
              name,
              style: GoogleFonts.prompt(
                fontSize: 13,
                color: const Color(0xFF26A69A),
              ),
            ),
            backgroundColor: const Color(0xFF26A69A).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ⭐ แถบคำเตือนเมื่อถูกแบน
          if (widget.isBanned)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ นิยายเรื่องนี้ถูกระงับการเผยแพร่ชั่วคราว/ถาวร',
                      style: GoogleFonts.prompt(
                          color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          
          FutureBuilder<Novel?>(
            future: _novelDetailFuture,
            builder: (context, novelSnapshot) {
              
               if (novelSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final novelDetail = novelSnapshot.data;

              return Column(
                children: [
                  const SizedBox(height: 20),
                  // ... (ปกนิยาย) ...
                  Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (novelDetail?.coverImage != null &&
                               novelDetail!.coverImage!.isNotEmpty)
                              ? buildCoverImage(
                                  novelDetail.coverImage!,
                                  width: 100,
                                  height: 140,
                                  fit: BoxFit.cover,
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
                  const SizedBox(height: 12),
                  // ชื่อเรื่อง
                  Text(
                    novelDetail?.title ?? widget.novelTitle,
                    style: GoogleFonts.prompt(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ชื่อผู้เขียน
                  Text(
                    novelDetail?.writerName ?? 'ไม่ทราบผู้เขียน',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                  // ส่วนแสดงยอด Views และ Likes
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${novelDetail?.numberOfViews ?? 0} views',
                        style: GoogleFonts.prompt(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.thumb_up, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${novelDetail?.likes ?? 0}',
                        style: GoogleFonts.prompt(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  // ⭐ ปุ่ม Bookmark: ปรับการแสดงผลตามสถานะ
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    // 💡 onPressed: เรียก _toggleBookmark เสมอ แล้วให้ Logic ภายในเมธอดจัดการ
                    onPressed: _toggleBookmark, 
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                      color: widget.isBanned && !_isBookmarked ? Colors.grey : Colors.white, // ไอคอนสีเทาถ้าถูกแบนและยังไม่ได้บันทึก
                    ),
                    label: Text(
                      _isBookmarked ? 'บันทึกแล้ว' : 'บันทึกเรื่องนี้',
                      style: GoogleFonts.prompt(
                          // Text สีเทาถ้าถูกแบนและยังไม่ได้บันทึก
                          color: widget.isBanned && !_isBookmarked ? Colors.grey : Colors.white, 
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      // พื้นหลังสีเทาถ้าถูกแบนและยังไม่ได้บันทึก
                      backgroundColor: widget.isBanned && !_isBookmarked 
                          ? Colors.grey[300] 
                          : const Color(0xFF26A69A),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: widget.isBanned && !_isBookmarked ? 0 : 2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ... (ส่วนคำอธิบายและ Tag เหมือนเดิม) ...
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        novelDetail?.description ?? 'ไม่มีคำอธิบายสำหรับนิยายเรื่องนี้',
                        textAlign: TextAlign.start,
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _buildCategoryTags(novelDetail),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // Chapter List
          Expanded(
            child: FutureBuilder<List<Chapter>>(
              future: _chaptersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('ไม่พบรายการบทที่เผยแพร่'));
                }

                final chaptersList = snapshot.data!;
                return ListView.separated(
                  itemCount: chaptersList.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chapter = chaptersList[index];
                    return ListTile(
                      title: Text(
                        '#${chapter.number} ${chapter.title}',
                        style: GoogleFonts.prompt(
                          fontSize: 16,
                          color: widget.isBanned ? Colors.grey : Colors.black87, // สีเทาถ้าถูกแบน
                        ),
                      ),
                      // ⭐ ปิดใช้งาน onTap ถ้าถูกแบน
                      onTap: widget.isBanned ? null : () async{ 
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReadNovelPage(
                              novelId: widget.novelId,
                              chapterNumber: chapter.number,
                            ),
                          ),
                        );
                        print('Navigating to Read Chapter ID: ${chapter.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}