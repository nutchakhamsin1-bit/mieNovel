import 'package:mie_project/services/db_helper.dart';

class RecommendationService {
  // ฟังก์ชันหลักสำหรับการแนะนำนิยาย
  static Future<List<Map<String, dynamic>>> getRecommendedNovels(int userId) async {
    try {
      // 1. ดึงข้อมูลประวัติการอ่านและรายการโปรดของผู้ใช้
      final readHistory = await _getUserReadHistory(userId);
      final favorites = await DBHelper.getFavoriteNovels(userId);
      
      // 2. วิเคราะห์หมวดหมู่ที่ผู้ใช้ชอบ
      final preferredCategories = await _analyzePreferredCategories(readHistory, favorites);
      
      // 3. ดึงนิยายที่มีหมวดหมู่ตรงกับความชอบของผู้ใช้
      final recommendations = await _findSimilarNovels(preferredCategories, userId);
      
      return recommendations;
    } catch (e) {
      print('Error in getRecommendedNovels: $e');
      return [];
    }
  }

  // ดึงประวัติการอ่านของผู้ใช้
  static Future<List<Map<String, dynamic>>> _getUserReadHistory(int userId) async {
    final db = await DBHelper.database();
    return await db.rawQuery('''
      SELECT DISTINCT n.*, COUNT(c.chapter_id) as read_chapters
      FROM Novels n
      INNER JOIN Chapters c ON n.novel_id = c.novel_id
      WHERE c.number_of_views > 0
      AND EXISTS (
        SELECT 1 
        FROM Users u 
        WHERE u.user_id = ?
      )
      GROUP BY n.novel_id
      ORDER BY read_chapters DESC
    ''', [userId]);
  }

  // วิเคราะห์หมวดหมู่ที่ผู้ใช้ชอบ
  static Future<Map<int, double>> _analyzePreferredCategories(
    List<Map<String, dynamic>> readHistory,
    List<Map<String, dynamic>> favorites,
  ) async {
    Map<int, double> categoryScores = {};

    // ให้คะแนนจากประวัติการอ่าน
    for (var novel in readHistory) {
      final categoryId = novel['category_id'] as int;
      final readChapters = novel['read_chapters'] as int;
      categoryScores[categoryId] = (categoryScores[categoryId] ?? 0) + (readChapters * 0.5);
      
      // หากมีหมวดหมู่รอง
      final secondaryCategoryId = novel['secondary_category_id'] as int?;
      if (secondaryCategoryId != null) {
        categoryScores[secondaryCategoryId] = 
            (categoryScores[secondaryCategoryId] ?? 0) + (readChapters * 0.3);
      }
    }

    // ให้คะแนนเพิ่มจากรายการโปรด
    for (var favorite in favorites) {
      final categoryId = favorite['category_id'] as int;
      categoryScores[categoryId] = (categoryScores[categoryId] ?? 0) + 2.0;
      
      final secondaryCategoryId = favorite['secondary_category_id'] as int?;
      if (secondaryCategoryId != null) {
        categoryScores[secondaryCategoryId] = 
            (categoryScores[secondaryCategoryId] ?? 0) + 1.0;
      }
    }

    return categoryScores;
  }

  // ค้นหานิยายที่มีหมวดหมู่คล้ายกับที่ผู้ใช้ชอบ
  static Future<List<Map<String, dynamic>>> _findSimilarNovels(
    Map<int, double> preferredCategories,
    int userId,
  ) async {
    if (preferredCategories.isEmpty) return [];

    final db = await DBHelper.database();
    
    // เรียงลำดับหมวดหมู่ตามคะแนนความชอบ
    final sortedCategories = preferredCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // สร้าง query parameters
    final topCategories = sortedCategories.take(3).map((e) => e.key).toList();
    final placeholders = List.filled(topCategories.length, '?').join(',');

    // ค้นหานิยายที่อยู่ในหมวดหมู่ที่ผู้ใช้ชอบ
    final recommendations = await db.rawQuery('''
      SELECT n.*, 
             c1.category_name as main_category,
             c2.category_name as secondary_category,
             (
               CASE 
                 WHEN n.category_id IN ($placeholders) THEN 2
                 WHEN n.secondary_category_id IN ($placeholders) THEN 1
                 ELSE 0
               END +
               (n.likes * 0.1) +
               (n.number_of_views * 0.01)
             ) as relevance_score
      FROM Novels n
      LEFT JOIN Categories c1 ON n.category_id = c1.category_id
      LEFT JOIN Categories c2 ON n.secondary_category_id = c2.category_id
      WHERE n.is_published = 1 
      AND n.is_banned = 0
      AND n.novel_id NOT IN (
        SELECT novel_id 
        FROM Favorites 
        WHERE user_id = ?
      )
      HAVING relevance_score > 0
      ORDER BY relevance_score DESC
      LIMIT 10
    ''', [...topCategories, ...topCategories, userId]);

    return recommendations;
  }
}
