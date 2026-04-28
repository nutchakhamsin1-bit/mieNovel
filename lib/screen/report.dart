import 'package:flutter/material.dart';
import 'package:mie_project/services/db_helper.dart';

class Report extends StatefulWidget {
  // ⭐ เพิ่ม Properties: novelId เพื่อการอ้างอิงถึงนิยายทั้งหมด
  final int novelId;
  final int chapterId;
  final String chapterTitle;
  final int reportingUserId;

  const Report({
    super.key,
    required this.novelId, // ⭐ NEW: ต้องรับ novelId
    required this.chapterId,
    required this.chapterTitle,
    required this.reportingUserId, // สมมติ User ID 1 คือคนรายงาน
  });

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  // -----------------------------------------------------------------
  // ⭐ ฟังก์ชัน: บันทึกรายงาน Chapter
  // -----------------------------------------------------------------
  Future<void> _submitReport(BuildContext context, String reason) async {
    // ปิด BottomSheet ก่อนแสดง SnackBar
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    try {
      // ⭐ เรียกใช้ DBHelper.reportChapter
      final success = await DBHelper.reportChapter(
        reportingUserId: widget.reportingUserId,
        chapterId: widget.chapterId,
        reason: reason,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ส่งรายงานบท "${widget.chapterTitle}" เรียบร้อยแล้ว! ✅',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถส่งรายงานได้ โปรดลองอีกครั้ง'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการส่งรายงาน: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // -----------------------------------------------------------------
  // ฟังก์ชัน: จัดการรายงานอื่นๆ และเปิด TextField
  // -----------------------------------------------------------------
  void _showOtherReasonDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ระบุเหตุผลอื่นๆ'),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'โปรดระบุรายละเอียดการรายงาน',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  Navigator.pop(context); // ปิด Dialog
                  // ส่งรายงานโดยใช้ข้อความที่ผู้ใช้กรอก
                  _submitReport(context, 'เหตุผลอื่นๆ: $reason');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาระบุรายละเอียด')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[400],
                foregroundColor: Colors.white,
              ),
              child: const Text('ส่งรายงาน'),
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // ฟังก์ชัน: แสดงเหตุผลการรายงาน (ปรับปรุง)
  // -----------------------------------------------------------------
  void _showReportReasons(BuildContext context) {
    final reasons = [
      'เนื้อหาลอกเลียน/ละเมิดลิขสิทธิ์',
      'เนื้อหาไม่เหมาะสม (รุนแรง, อนาจาร)',
      'มีการขาย/โปรโมทสินค้าผิดกฎหมาย',
      'เนื้อหาหมิ่นประมาท/สร้างความเกลียดชัง',
      'เหตุผลอื่นๆ',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เหตุผลที่รายงานเนื้อหา',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              // สร้างรายการเหตุผลจาก List
              ...reasons.map((reason) {
                return ListTile(
                  title: Text(reason),
                  onTap: () {
                    if (reason == 'เหตุผลอื่นๆ') {
                      Navigator.pop(context);
                      Future.delayed(Duration(milliseconds: 100), () {
                        _showOtherReasonDialog(context);
                      });
                    } else {
                      _submitReport(context, reason);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Widget Build
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('รายงานเนื้อหาบท'),
        backgroundColor: Colors.pink[400], // เปลี่ยนสี AppBar ให้เป็นสีเตือน
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gavel_outlined, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'รายงานบทนี้เพื่อแจ้งผู้ดูแลระบบ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'บทที่ถูกรายงาน:',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.chapterTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Novel ID: ${widget.novelId} | Chapter ID: ${widget.chapterId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.flag_outlined, color: Colors.white),
                label: const Text('เลือกเหตุผลการรายงาน 🚨'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => _showReportReasons(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
