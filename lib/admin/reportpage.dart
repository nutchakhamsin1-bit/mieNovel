import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/admin/ReportedChapterDetailPage.dart';

class AdminReportManagePage extends StatefulWidget {
  final int? novelId;
  final String? initialAction;

  const AdminReportManagePage({
    super.key,
    this.novelId,
    this.initialAction,
  });

  @override
  State<AdminReportManagePage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportManagePage> {
  // ⭐ เปลี่ยนชื่อตัวแปรให้สอดคล้องกับข้อมูลที่มีรายละเอียดมากขึ้น
  List<Map<String, dynamic>> reportsWithDetails = []; 
  bool isLoading = true; 

  @override
  void initState() {
    super.initState();
    loadReports();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialAction();
    });
  }

  // -----------------------------------------------------------------
  // ฟังก์ชัน: โหลดรายงานจาก DB (ปรับปรุง)
  // -----------------------------------------------------------------
  Future<void> loadReports() async {
    setState(() => isLoading = true);
    try {
      // ⭐ สมมติว่าเมธอดนี้ดึงข้อมูลชื่อผู้ใช้, ชื่อบท, ชื่อนิยายมาให้แล้ว
      final data = await DBHelper.getPendingReportsWithDetails(); 
      setState(() => reportsWithDetails = data);
    } catch (e) {
      print('Error loading reports: $e');
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายงาน: $e')),
          );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  // -----------------------------------------------------------------
  // ฟังก์ชัน: จัดการ Action เมื่อเลือกใน PopupMenu (เหมือนเดิม)
  // -----------------------------------------------------------------
  Future<void> _processReportAction(
      int reportId, int chapterId, String action) async {
    String status = action;
    bool success = false;
    
    // 1. ดำเนินการตาม Action
    if (action == "warn") {
      // ⭐ เรียก warnNovel ซึ่งควรจะหา novelId จาก chapterId ใน DB
      await DBHelper.reportWarnChapter(chapterId); 
      status = "warned";
      success = true;
    } else if (action == "ban") {
      // ⭐ เรียก banNovel ซึ่งควรจะหา novelId จาก chapterId ใน DB
      await DBHelper.reportBanChapter(chapterId); 
      status = "banned";
      success = true;
    } else if (action == "ignore") {
      status = "ignored";
      success = true; 
    }

    // 2. อัปเดตสถานะในตาราง Reports
    if (success) {
      await DBHelper.updateReportStatus(reportId, status);
      await loadReports(); // รีโหลดรายการรายงาน
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ดำเนินการ $action รายงานที่ $reportId เรียบร้อยแล้ว')),
        );
      }
    }
  }
  
  // -----------------------------------------------------------------
  // ฟังก์ชัน: จัดการการกระทำเริ่มต้นที่ส่งมาจาก NovelDetailPage (เหมือนเดิม)
  // -----------------------------------------------------------------
  void _handleInitialAction() {
    if (widget.novelId != null && widget.initialAction != null) {
      String actionText = widget.initialAction == 'go_to_report'
          ? 'แบนนิยายนี้'
          : 'ส่งคำเตือน';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(actionText),
          content: Text('คุณต้องการ $actionText Novel ID: ${widget.novelId} ทันทีหรือไม่?\n(การดำเนินการนี้ควรทำหลังจากตรวจสอบรายงานแล้ว)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // ปิด dialog
                
                // ⭐ ดำเนินการแบน/เตือนนิยาย
                if (widget.initialAction == 'go_to_report') {
                  await DBHelper.updateNovelBanStatus(widget.novelId!, true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('นิยายถูกแบนเรียบร้อยแล้ว')),
                    );
                  }
                } else if (widget.initialAction == 'go_to_report_warn') {
                  await DBHelper.warnNovel(widget.novelId!);
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ส่งคำเตือนไปยังผู้เขียนแล้ว')),
                    );
                  }
                }
                
                // นำ Admin กลับไปหน้า Novel Detail เพื่อรีเฟรชข้อมูล
                Navigator.pop(context); 
              },
              child: Text(actionText),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "รายการรายงานที่รอดำเนินการ",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.red[100],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportsWithDetails.isEmpty
              ? Center(
                  child: Text(
                    "🎉 ไม่มีรายงานที่รอดำเนินการ",
                    style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: reportsWithDetails.length,
                  itemBuilder: (context, index) {
                    final r = reportsWithDetails[index];
                    // ⭐ ดึงค่าที่ JOIN มาใช้
                    final String novelTitle = r['novel_title'] ?? 'ไม่ระบุชื่อนิยาย';
                    final String chapterTitle = r['chapter_title'] ?? 'ไม่ระบุชื่อบท';
                    // ⭐ ใช้ชื่อผู้ใช้ (username) แทน user_id
                    final String reportedBy = r['username'] ?? 'User ID: ${r['user_id']}'; 
                    final String writerName = r['writer_name'] ?? 'ไม่ระบุผู้เขียน';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 1,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportedChapterDetailPage(
                                chapterId: r['chapter_id'],
                                novelId: r['novel_id'], // ✅ ส่ง novelId ไปด้วย
                                novelTitle: novelTitle,
                                chapterTitle: chapterTitle,
                                reportReason: r['remark'] ?? '',
                              ),
                            ),
                          );
                        },
                        leading: const Icon(Icons.warning_amber, color: Colors.orange),
                        title: Text(
                          // ⭐ แสดงชื่อบทและชื่อนิยาย
                          "$novelTitle (${chapterTitle})",
                          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ⭐ แสดงชื่อผู้รายงาน
                            Text(
                              "ผู้รายงาน: $reportedBy",
                              style: GoogleFonts.prompt(fontSize: 14, color: Colors.red[700]),
                            ),
                            // ⭐ เพิ่มชื่อผู้เขียนนิยาย
                            Text(
                              "ผู้เขียน: $writerName",
                              style: GoogleFonts.prompt(fontSize: 14, color: Colors.black54),
                            ),
                            Text(
                              "เหตุผล: ${r['remark']}",
                              style: GoogleFonts.prompt(fontSize: 14),
                            ),
                            Text(
                              "วันที่: ${r['created_at']}",
                              style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            _processReportAction(
                              r['report_id'],
                              r['chapter_id'], 
                              value,
                            );
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: "warn", child: Text("⚠️ เตือนผู้เขียน")),
                            PopupMenuItem(value: "ban", child: Text("🚨 แบนนิยาย")),
                            PopupMenuItem(value: "ignore", child: Text("✅ ปฏิเสธรายงาน")),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}