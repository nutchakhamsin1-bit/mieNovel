import 'package:flutter/material.dart';
import 'package:mie_project/services/db_helper.dart';

class ReportedChapterDetailPage extends StatelessWidget {
  final int chapterId;
  final int novelId;
  final String novelTitle;
  final String chapterTitle;
  final String reportReason;

  const ReportedChapterDetailPage({
    super.key,
    required this.chapterId,
    required this.novelId,
    required this.novelTitle,
    required this.chapterTitle,
    required this.reportReason,
  });

  Future<String> loadChapterContent() async {
    final chapter = await DBHelper.getChapterById(chapterId: chapterId, novelId: novelId);
    return chapter?['content'] ?? 'ไม่มีเนื้อหา';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapterTitle)),
      body: FutureBuilder<String>(
        future: loadChapterContent(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(novelTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(snapshot.data!,
                      style: const TextStyle(fontSize: 16, height: 1.4)),
                  const Divider(height: 32),
                  Text("เหตุผลที่ถูกรายงาน: $reportReason",
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
