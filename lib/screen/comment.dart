import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:intl/intl.dart';

class CommentPage extends StatefulWidget {
  final int chapterId;
  final String chapterNumber;

  const CommentPage({
    super.key,
    required this.chapterId,
    required this.chapterNumber,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _controller = TextEditingController();
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndComments();
  }

  Future<void> _loadUserAndComments() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    await _fetchComments();
  }

  Future<void> _fetchComments() async {
    final data = await DBHelper.getCommentsByChapter(widget.chapterId);
    print("📼 data : $data");
    _processComments(data);
    setState(() {
      comments = data;
    });
  }

  List<Map<String, dynamic>> parentComments = [];
  Map<int, List<Map<String, dynamic>>> replies = {};

  void _processComments(List<Map<String, dynamic>> data) {
    parentComments.clear();
    replies.clear();

    for (var c in data) {
      if (c['parent_id'] == null) {
        parentComments.add(c);
      } else {
        replies.putIfAbsent(c['parent_id'], () => []).add(c);
      }
    }
  }

  Future<void> _addComment() async {
    if (_controller.text.trim().isEmpty || userId == null) return;

    await DBHelper.insertComment(userId!, widget.chapterId, _controller.text);
    _controller.clear();
    await _fetchComments();
  }

  Future<void> _editComment(int commentId, String oldContent) async {
    final controller = TextEditingController(text: oldContent);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขคอมเมนต์'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'พิมพ์คอมเมนต์ใหม่...'),
        ),
        actions: [
          TextButton(
            child: const Text('ยกเลิก'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('บันทึก'),
            onPressed: () async {
              await DBHelper.updateComment(commentId, controller.text);
              Navigator.pop(context);
              await _fetchComments();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบคอมเมนต์'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบคอมเมนต์นี้?'),
        actions: [
          TextButton(
            child: const Text('ยกเลิก'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('ลบ'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.deleteComment(commentId);
      await _fetchComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ความคิดเห็น')),
      body: Column(
        children: [
          Expanded(
            child: parentComments.isEmpty
                ? const Center(child: Text('ยังไม่มีความคิดเห็น'))
                : ListView.builder(
                    itemCount: parentComments.length,
                    itemBuilder: (context, index) {
                      // final comment = comments[index];
                      final comment = parentComments[index];
                      final isMine = comment['user_id'] == userId;

                      // *** START: โค้ดที่ถูกแก้ไข ***
                      return Column(
                        // 👈 เปลี่ยนเป็น Column
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. CARD ของคอมเมนต์หลัก
                          Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(comment['content']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${comment['username'] ?? 'ไม่ทราบชื่อ'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatThaiDate(comment['created_at']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton(
                                    onPressed: () =>
                                        _showReplyDialog(comment['comment_id']),
                                    child: const Text('ตอบกลับ'),
                                  ),
                                  FutureBuilder<int>(
                                    future: DBHelper.getCommentLikeCount(
                                      comment['comment_id'],
                                    ),
                                    builder: (context, snapshot) {
                                      final likeCount = snapshot.data ?? 0;
                                      return Row(
                                        children: [
                                          FutureBuilder<bool>(
                                            future: userId == null
                                                ? Future.value(false)
                                                : DBHelper.isCommentLikedByUser(
                                                    userId!,
                                                    comment['comment_id'],
                                                  ),
                                            builder: (context, likedSnap) {
                                              final liked =
                                                  likedSnap.data ?? false;
                                              return IconButton(
                                                icon: Icon(
                                                  liked
                                                      ? Icons.thumb_up
                                                      : Icons
                                                            .thumb_up_alt_outlined,
                                                  color: liked
                                                      ? Colors.blue
                                                      : Colors.grey,
                                                ),
                                                onPressed: () async {
                                                  if (userId == null) return;
                                                  if (liked) {
                                                    await DBHelper.removeCommentLike(
                                                      userId!,
                                                      comment['comment_id'],
                                                    );
                                                  } else {
                                                    await DBHelper.addCommentLike(
                                                      userId!,
                                                      comment['comment_id'],
                                                    );
                                                  }
                                                  setState(() {});
                                                },
                                              );
                                            },
                                          ),
                                          Text('$likeCount'),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),

                              trailing: isMine
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editComment(
                                            comment['comment_id'],
                                            comment['content'],
                                          );
                                        } else if (value == 'delete') {
                                          _deleteComment(comment['comment_id']);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('แก้ไข'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('ลบ'),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),

                          // 2. ส่วนของคอมเมนต์ตอบกลับ (Replies)
                          if (replies.containsKey(comment['comment_id']))
                            ...replies[comment['comment_id']]!.map((reply) {
                              final isReplyMine = reply['user_id'] == userId;

                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 40,
                                  top: 4,
                                  bottom: 4,
                                ),
                                child: Card(
                                  color: Colors.grey[100],
                                  child: ListTile(
                                    title: Text(reply['content']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${reply['username'] ?? "ไม่ทราบชื่อ"} - ${_formatThaiDate(reply['created_at'])}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),

                                        // ✅ เพิ่มส่วน Like/Like Count สำหรับ Reply ที่นี่
                                        FutureBuilder<int>(
                                          future: DBHelper.getCommentLikeCount(
                                            reply['comment_id'], // 👈 ใช้ ID ของ Reply
                                          ),
                                          builder: (context, snapshot) {
                                            final likeCount =
                                                snapshot.data ?? 0;
                                            return Row(
                                              children: [
                                                FutureBuilder<bool>(
                                                  future: userId == null
                                                      ? Future.value(false)
                                                      : DBHelper.isCommentLikedByUser(
                                                          userId!,
                                                          reply['comment_id'], // 👈 ใช้ ID ของ Reply
                                                        ),
                                                  builder: (context, likedSnap) {
                                                    final liked =
                                                        likedSnap.data ?? false;
                                                    return IconButton(
                                                      icon: Icon(
                                                        liked
                                                            ? Icons.thumb_up
                                                            : Icons
                                                                  .thumb_up_alt_outlined,
                                                        color: liked
                                                            ? Colors.blue
                                                            : Colors.grey,
                                                      ),
                                                      onPressed: () async {
                                                        if (userId == null) {
                                                          return;
                                                        }
                                                        if (liked) {
                                                          await DBHelper.removeCommentLike(
                                                            userId!,
                                                            reply['comment_id'],
                                                          );
                                                        } else {
                                                          await DBHelper.addCommentLike(
                                                            userId!,
                                                            reply['comment_id'],
                                                          );
                                                        }
                                                        setState(
                                                          () {},
                                                        ); // รีเฟรชเพื่อแสดง Like Count ใหม่
                                                      },
                                                    );
                                                  },
                                                ),
                                                Text('$likeCount'),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    trailing: isReplyMine
                                        ? PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editComment(
                                                  reply['comment_id'],
                                                  reply['content'],
                                                );
                                              } else if (value == 'delete') {
                                                _deleteComment(
                                                  reply['comment_id'],
                                                );
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('แก้ไข'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('ลบ'),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }),
                        ],
                      );
                      // *** END: โค้ดที่ถูกแก้ไข ***
                    },
                  ),
          ),
          // ... (ส่วนของ TextField สำหรับพิมพ์ความคิดเห็น)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'พิมพ์ความคิดเห็น...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatThaiDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(
        dateStr,
      ).toLocal().add(const Duration(hours: 7));
      final formatter = DateFormat('d MMM yyyy HH:mm', 'th_TH');
      return formatter.format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _showReplyDialog(int parentId) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตอบกลับความคิดเห็น'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'พิมพ์ข้อความ...'),
        ),
        actions: [
          TextButton(
            child: const Text('ยกเลิก'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('ส่ง'),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty && userId != null) {
                final _chapterId = widget.chapterId;
                print("🔔 Replying to comment ID: $parentId");
                print("🔔 Reply chapterId: $_chapterId");
                await DBHelper.insertCommentReply(
                  userId!,
                  widget.chapterId,
                  parentId,
                  controller.text.trim(),
                );
                print("data ");
                Navigator.pop(context);
                await _fetchComments();
              }
            },
          ),
        ],
      ),
    );
  }
}
