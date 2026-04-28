import 'package:flutter/material.dart';
import 'package:mie_project/models/novel.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/admin/noveldetailpage.dart';

class Managenovel extends StatefulWidget {
  const Managenovel({super.key});

  @override
  State<Managenovel> createState() => _ManagenovelState();
}

class _ManagenovelState extends State<Managenovel> {
  late Future<List<Novel>> _novelFuture;
  List<Novel> _allNovels = [];
  List<Novel> _filteredNovels = [];

  @override
  void initState() {
    super.initState();
    _loadNovels();
  }

  Future<void> _loadNovels() async {
    _novelFuture = DBHelper.fetchAllNovelsModel();
    final novels = await _novelFuture;

    setState(() {
      _allNovels = novels;
      _filteredNovels = novels;
    });
  }

  void _filterNovels(String query) {
    setState(() {
      _filteredNovels = _allNovels.where((novel) {
        final titleMatch = novel.title.toLowerCase().contains(query.toLowerCase());
        final writerMatch = novel.writerName.toLowerCase().contains(query.toLowerCase());
        return titleMatch || writerMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการนิยาย'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: _filterNovels,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ค้นหานิยาย...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('รายการนิยาย',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: FutureBuilder(
                future: _novelFuture,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("โหลดข้อมูลผิดพลาด"));
                  }
                  if (_filteredNovels.isEmpty) {
                    return const Center(child: Text("ไม่พบนิยาย"));
                  }

                  return ListView.separated(
                    itemCount: _filteredNovels.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final novel = _filteredNovels[index];

                      return ListTile(
                        title: Text(novel.title),
                        subtitle: Text(
                            "${novel.writerName} | ${novel.numberOfViews} views"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NovelDetailPage(
                                novelId: novel.novelId,
                                title: novel.title,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
