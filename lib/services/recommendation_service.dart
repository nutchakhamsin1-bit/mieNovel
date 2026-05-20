import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/utils/app_logger.dart';

/// Hybrid content-based + popularity recommender.
///
/// Combines:
///   • read history (ChapterViews)
///   • favorites (Favorites)
///   • novel popularity (likes/views ratio)
/// to recommend novels the user has not yet engaged with.
class RecommendationService {
  static Future<List<Map<String, dynamic>>> getRecommendedNovels(
    int userId,
  ) async {
    try {
      final readHistory = await _getUserReadHistory(userId);
      final favorites = await DBHelper.getFavoriteNovels(userId);

      final preferredCategories =
          _analyzePreferredCategories(readHistory, favorites);
      return await _findSimilarNovels(preferredCategories, userId);
    } catch (e, st) {
      AppLogger.error('getRecommendedNovels failed', e, st);
      return [];
    }
  }

  /// Distinct novels the given user has actually opened (with read-count).
  static Future<List<Map<String, dynamic>>> _getUserReadHistory(
    int userId,
  ) async {
    final db = await DBHelper.database();
    return await db.rawQuery(
      '''
      SELECT n.novel_id, n.category_id, n.secondary_category_id,
             COUNT(DISTINCT cv.chapter_id) AS read_chapters
      FROM ChapterViews cv
      JOIN Novels n ON n.novel_id = cv.novel_id
      WHERE cv.user_id = ?
      GROUP BY n.novel_id
      ORDER BY read_chapters DESC
      ''',
      [userId],
    );
  }

  static Map<int, double> _analyzePreferredCategories(
    List<Map<String, dynamic>> readHistory,
    List<Map<String, dynamic>> favorites,
  ) {
    final scores = <int, double>{};

    for (final novel in readHistory) {
      final mainId = novel['category_id'] as int?;
      final secondaryId = novel['secondary_category_id'] as int?;
      final reads = (novel['read_chapters'] as int? ?? 1).toDouble();

      if (mainId != null) {
        scores[mainId] = (scores[mainId] ?? 0) + reads * 0.5;
      }
      if (secondaryId != null) {
        scores[secondaryId] = (scores[secondaryId] ?? 0) + reads * 0.3;
      }
    }

    for (final fav in favorites) {
      // getFavoriteNovels doesn't return category_id directly; skip if missing.
      final mainId = fav['category_id'] as int?;
      final secondaryId = fav['secondary_category_id'] as int?;
      if (mainId != null) {
        scores[mainId] = (scores[mainId] ?? 0) + 2.0;
      }
      if (secondaryId != null) {
        scores[secondaryId] = (scores[secondaryId] ?? 0) + 1.0;
      }
    }

    return scores;
  }

  static Future<List<Map<String, dynamic>>> _findSimilarNovels(
    Map<int, double> preferredCategories,
    int userId,
  ) async {
    final db = await DBHelper.database();

    // Cold start: no history → trending novels.
    if (preferredCategories.isEmpty) {
      return await db.rawQuery(
        '''
        SELECT n.*,
               c1.category_name AS main_category,
               c2.category_name AS secondary_category
        FROM Novels n
        LEFT JOIN Categories c1 ON c1.category_id = n.category_id
        LEFT JOIN Categories c2 ON c2.category_id = n.secondary_category_id
        WHERE n.is_published = 1 AND n.is_banned = 0
          AND n.novel_id NOT IN (
            SELECT novel_id FROM Favorites WHERE user_id = ? AND is_active = 1
          )
        ORDER BY n.likes DESC, n.number_of_views DESC
        LIMIT 10
        ''',
        [userId],
      );
    }

    final sorted = preferredCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIds = sorted.take(3).map((e) => e.key).toList();
    final placeholders = List.filled(topIds.length, '?').join(',');

    return await db.rawQuery(
      '''
      SELECT n.*,
             c1.category_name AS main_category,
             c2.category_name AS secondary_category,
             (
               CASE
                 WHEN n.category_id IN ($placeholders) THEN 2.0
                 WHEN n.secondary_category_id IN ($placeholders) THEN 1.0
                 ELSE 0.0
               END
               + (n.likes * 0.1)
               + (n.number_of_views * 0.005)
             ) AS relevance_score
      FROM Novels n
      LEFT JOIN Categories c1 ON c1.category_id = n.category_id
      LEFT JOIN Categories c2 ON c2.category_id = n.secondary_category_id
      WHERE n.is_published = 1
        AND n.is_banned = 0
        AND n.novel_id NOT IN (
          SELECT novel_id FROM Favorites WHERE user_id = ? AND is_active = 1
        )
        AND (
          n.category_id IN ($placeholders)
          OR n.secondary_category_id IN ($placeholders)
        )
      ORDER BY relevance_score DESC
      LIMIT 10
      ''',
      [...topIds, ...topIds, userId, ...topIds, ...topIds],
    );
  }
}
