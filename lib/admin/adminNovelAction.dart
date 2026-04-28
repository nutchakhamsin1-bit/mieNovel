import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mie_project/services/db_helper.dart';

class AdminNovelActionPage extends StatefulWidget {
  final int novelId;
  final String initialAction;
  final String novelTitle; // เพื่อแสดงบนหน้าจอ

  const AdminNovelActionPage({
    super.key,
    required this.novelId,
    required this.initialAction,
    required this.novelTitle,
  });

  @override
  State<AdminNovelActionPage> createState() => _AdminNovelActionPageState();
}

class _AdminNovelActionPageState extends State<AdminNovelActionPage> {
  // ⭐ 1. เพิ่ม TextEditingController สำหรับ Remark
  final TextEditingController _remarkController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late bool isBanAction;
  late String actionText;
  late IconData actionIcon;
  late Color actionColor;
  
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    isBanAction = widget.initialAction == 'go_to_report';
    actionText = isBanAction ? 'แบนนิยาย' : 'เตือนผู้เขียน';
    actionIcon = isBanAction ? Icons.gavel : Icons.warning_amber;
    actionColor = isBanAction ? Colors.red.shade700 : Colors.orange.shade700;
  }
  
  // ⭐ 2. อย่าลืม dispose controller
  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }


  // -----------------------------------------------------------------
  // ⭐ 3. ปรับปรุงฟังก์ชัน: ดำเนินการเตือน/แบน
  // -----------------------------------------------------------------
  Future<void> _processAction() async {
    if (!_formKey.currentState!.validate()) {
      return; // ไม่ผ่าน validation (remark ว่างเปล่า)
    }

    setState(() => isProcessing = true);
    final remark = _remarkController.text.trim(); // ดึงค่า remark

    try {
      if (isBanAction) {
        // ⭐ ส่งค่า remark ไปยัง DBHelper.updateNovelBanStatus
        await DBHelper.updateNovelBanStatus(
            widget.novelId, true, remark: remark);
        _showSuccessSnackbar('นิยาย "${widget.novelTitle}" ถูกแบนเรียบร้อยแล้ว');
      } else {
        // ⭐ ส่งค่า remark ไปยัง DBHelper.warnNovel
        await DBHelper.warnNovel(widget.novelId, remark: remark);
        _showSuccessSnackbar('ส่งคำเตือนไปยังผู้เขียนของนิยาย "${widget.novelTitle}" แล้ว');
      }
      
      // ส่งค่า true กลับไปหน้า NovelDetailPage เพื่อให้รีโหลดข้อมูล
      if (mounted) Navigator.pop(context, true); 
      
    } catch (e) {
      _showErrorSnackbar('เกิดข้อผิดพลาดในการดำเนินการ: $e');
      setState(() => isProcessing = false);
    }
  }
  
  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message ✅'), backgroundColor: Colors.green),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message ❌'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$actionText - ยืนยันการดำเนินการ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      // ⭐ 4. เพิ่ม Form เพื่อจัดการ Validation
      body: Form(
        key: _formKey,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(actionIcon, size: 80, color: actionColor),
                const SizedBox(height: 20),
                Text(
                  isBanAction ? '🚨 ยืนยันการแบนนิยาย 🚨' : '⚠️ ยืนยันการเตือนผู้เขียน ⚠️',
                  style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.bold, color: actionColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'คุณกำลังดำเนินการ $actionText กับนิยายเรื่อง:',
                  style: GoogleFonts.prompt(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.novelTitle} (ID: ${widget.novelId})',
                  style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // ⭐ 5. เพิ่ม TextFormField สำหรับ Remark
                TextFormField(
                  controller: _remarkController,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    labelText: 'เหตุผลในการดำเนินการ (ต้องระบุ)',
                    labelStyle: GoogleFonts.prompt(color: actionColor),
                    hintText: isBanAction 
                              ? 'เช่น: "เนื้อหาละเมิดลิขสิทธิ์จากนิยาย A"' 
                              : 'เช่น: "ภาพประกอบไม่เหมาะสมในบทที่ 10"',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: actionColor),
                    ),
                  ),
                  style: GoogleFonts.prompt(fontSize: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณาระบุเหตุผลในการดำเนินการนี้';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : _processAction,
                    icon: isProcessing 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                          ) 
                        : Icon(isBanAction ? Icons.block : Icons.send),
                    label: Text(
                      isProcessing ? 'กำลังดำเนินการ...' : actionText,
                      style: GoogleFonts.prompt(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isProcessing ? null : () => Navigator.pop(context, false), // ส่ง false กลับไป
                    child: Text('ยกเลิก', style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}