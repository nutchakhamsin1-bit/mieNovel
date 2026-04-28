import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/services/db_helper.dart';

class MemberDetailPage extends StatefulWidget {
  final int userId; // ✅ ต้องส่ง userId เสมอ

  const MemberDetailPage({super.key, required this.userId});

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  
  // ⭐ 1. เพิ่ม TextEditingController สำหรับกรอกเหตุผล
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }
  
  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetail() async {
    final data = await DBHelper.getUserDetail(widget.userId);

    setState(() {
      user = data;
      isLoading = false;
    });
  }

  // ----------------------------------------------------------------------
  // ⭐ 2. ปรับปรุงฟังก์ชัน _toggleStatus ให้แสดง Pop-up ยืนยันพร้อมเหตุผล
  // ----------------------------------------------------------------------
  Future<void> _toggleStatus() async {
    if (user == null) return;

    final isCurrentlyActive = user!['status'] == "active";
    final newStatus = isCurrentlyActive ? "banned" : "active";
    final actionText = isCurrentlyActive ? 'ระงับการใช้งาน' : 'ปลดแบนผู้ใช้';
    final color = isCurrentlyActive ? Colors.red : Colors.green;

    // ⭐️ แสดง Pop-up ยืนยันและให้กรอกเหตุผล
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => 
          _buildConfirmationDialog(actionText, color, isCurrentlyActive),
    );

    // ตรวจสอบว่าผู้ใช้กด 'ยืนยัน'
    if (confirm == true) {
      final remark = _remarkController.text.trim();
      _remarkController.clear(); // ล้างค่าใน controller ทันที

      // ตรวจสอบเหตุผลเฉพาะกรณี 'ระงับการใช้งาน' (แบน)
      if (isCurrentlyActive && remark.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('เกิดข้อผิดพลาด: กรุณาระบุเหตุผลในการระงับ'), backgroundColor: Colors.red),
        );
        return;
      }
      
      try {
        // ⭐ เรียกใช้ DBHelper.updateUserStatus พร้อมส่งเหตุผล (Remark)
        // (ต้องมั่นใจว่าเมธอดนี้ใน DBHelper รับ remark ได้)
        await DBHelper.updateUserStatus(
            widget.userId, newStatus, remark: remark);
        
        await _loadUserDetail(); // โหลดข้อมูลผู้ใช้ใหม่

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "$actionText: ${user!['name']} ${user!['surname']} ${newStatus == 'active' ? 'เป็นปกติ' : 'ถูกระงับ'}"),
            backgroundColor: color,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาดในการดำเนินการ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ----------------------------------------------------------------------
  // ⭐ 3. Widget สำหรับ Pop-up ยืนยัน
  // ----------------------------------------------------------------------
  Widget _buildConfirmationDialog(String actionText, Color color, bool isBanning) {
    _remarkController.text = ''; // เคลียร์ค่าเก่าก่อนเปิด

    return AlertDialog(
      title: Text(
        'ยืนยันการ${isBanning ? 'ระงับ' : 'ปลดแบน'}ผู้ใช้',
        style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              'คุณแน่ใจหรือไม่ว่าต้องการ $actionText ผู้ใช้ ${user!['name']}?',
              style: GoogleFonts.prompt(),
            ),
            const SizedBox(height: 15),
            // แสดงช่องกรอกเหตุผลเมื่อต้องการระงับ/แบนเท่านั้น
            if (isBanning) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เหตุผลในการระงับ (จำเป็น):',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _remarkController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'เช่น: "ละเมิดกฎการใช้งานซ้ำ"',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: color, width: 2),
                      ),
                    ),
                    // ไม่ใช้ validator ที่นี่ แต่ตรวจสอบตอนกดปุ่ม 'ยืนยัน'
                  ),
                ],
              ),
            if (!isBanning) // ข้อความสำหรับปลดแบน
              Text(
                'เมื่อปลดแบน ผู้ใช้จะเข้าสู่ระบบได้ตามปกติ',
                style: GoogleFonts.prompt(color: Colors.grey.shade700),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.black54)),
        ),
        // ใช้ Builder เพื่อเข้าถึง ScaffoldMessenger ในบริบทของ Dialog
        Builder(
          builder: (dialogContext) {
            return TextButton(
              onPressed: () {
                // ตรวจสอบเหตุผลก่อนปิด Pop-up (สำหรับกรณีแบน)
                if (isBanning && _remarkController.text.trim().isEmpty) {
                   ScaffoldMessenger.of(dialogContext).showSnackBar(
                     const SnackBar(content: Text('กรุณาระบุเหตุผลในการระงับ'), backgroundColor: Colors.red),
                   );
                } else {
                   Navigator.of(context).pop(true); // ปิดพร้อมส่งค่า true
                }
              },
              child: Text(
                isBanning ? 'ยืนยันระงับ' : 'ยืนยันปลดแบน',
                style: GoogleFonts.prompt(color: color, fontWeight: FontWeight.bold),
              ),
            );
          }
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ข้อมูลสมาชิก",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Text(
                    "ไม่พบข้อมูลสมาชิก",
                    style: GoogleFonts.prompt(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          // Note: ควรตรวจสอบว่า 'avater_image' เป็น Path หรือ URL 
                          // และจัดการการโหลดภาพด้วย FileImage ถ้าเป็น Path 
                          backgroundImage: user!['avater_image'] != null
                              ? NetworkImage(user!['avater_image']) as ImageProvider<Object>?
                              : null,
                          child: user!['avater_image'] == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _infoRow("ชื่อ", "${user!['name']} ${user!['surname']}"),
                      _infoRow("อีเมล", user!['email']),
                      _infoRow("สถานะ",
                          user!['status'] == "active" ? "ปกติ" : "ถูกแบน"),
                      _infoRow("บทบาท",
                          user!['is_writer'] == 1 ? "นักเขียน" : "ผู้อ่าน"),
                      _infoRow("วันที่เข้าร่วม", user!['created_at']),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user!['status'] == "active"
                                ? Colors.red[300]
                                : Colors.green[400],
                            foregroundColor: Colors.white, // เพิ่มเพื่อให้ปุ่มมีสีตัวอักษรที่ชัดเจน
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _toggleStatus,
                          child: Text(
                            user!['status'] == "active"
                                ? "ระงับการใช้งาน"
                                : "ปลดแบนผู้ใช้",
                            style: GoogleFonts.prompt(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$title:",
              style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "-",
              style: GoogleFonts.prompt(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}