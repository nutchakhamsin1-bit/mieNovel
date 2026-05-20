import 'dart:math' as math;

import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/utils/app_logger.dart';

/// Provides reading-behavior insights for a user and content analytics for a
/// novel. All queries target tables that actually exist (ChapterViews,
/// Chapters, Novels, Categories, Favorites) and avoid SQLite-incompatible
/// functions like STDDEV.
class NovelAnalysisService {
  static const double categoryWeight = 0.30;
  static const double readTimeWeight = 0.20;
  static const double completionRateWeight = 0.15;
  static const double likeRatioWeight = 0.15;
  static const double trendWeight = 0.10;
  static const double ageGroupWeight = 0.10;

  /// Build a behavior profile for a user from their ChapterView events.
  /// Returns sensible defaults if no history exists.
  static Future<Map<String, dynamic>> analyzeUserReadingBehavior(
    int userId,
  ) async {
    final db = await DBHelper.database();

    // 1. Average chapter length the user actually reads (proxy for read-time).
    final lengthResult = await db.rawQuery(
      '''
      SELECT AVG(LENGTH(COALESCE(c.content, ''))) AS avg_length,
             COUNT(DISTINCT cv.chapter_id) AS chapters_read
      FROM ChapterViews cv
      JOIN Chapters c ON c.chapter_id = cv.chapter_id
      WHERE cv.user_id = ?
      ''',
      [userId],
    );

    // 2. Completion rate per novel — novels with ≥80% of chapters read.
    final completionResult = await db.rawQuery(
      '''
      WITH novel_progress AS (
        SELECT n.novel_id,
               COUNT(DISTINCT c.chapter_id) AS total_chapters,
               COUNT(DISTINCT cv.chapter_id) AS read_chapters
        FROM Novels n
        JOIN Chapters c ON c.novel_id = n.novel_id
        LEFT JOIN ChapterViews cv
          ON cv.chapter_id = c.chapter_id AND cv.user_id = ?
        GROUP BY n.novel_id
        HAVING read_chapters > 0
      )
      SELECT
        SUM(CASE WHEN read_chapters * 1.0 / total_chapters >= 0.8 THEN 1 ELSE 0 END) AS completed,
        COUNT(*) AS started
      FROM novel_progress
      ''',
      [userId],
    );

    // 3. Preferred time of day.
    final timeResult = await db.rawQuery(
      '''
      SELECT
        CASE
          WHEN CAST(strftime('%H', created_at) AS INTEGER) BETWEEN 6 AND 11 THEN 'morning'
          WHEN CAST(strftime('%H', created_at) AS INTEGER) BETWEEN 12 AND 17 THEN 'afternoon'
          WHEN CAST(strftime('%H', created_at) AS INTEGER) BETWEEN 18 AND 22 THEN 'evening'
          ELSE 'night'
        END AS time_period,
        COUNT(*) AS read_count
      FROM ChapterViews
      WHERE user_id = ?
      GROUP BY time_period
      ORDER BY read_count DESC
      LIMIT 1
      ''',
      [userId],
    );

    // 4. Favorite categories aggregated from reads + favorites.
    final categoryResult = await db.rawQuery(
      '''
      SELECT cat.category_id, cat.category_name, SUM(weight) AS score
      FROM (
        SELECT n.category_id, 1.0 AS weight
        FROM ChapterViews cv
        JOIN Novels n ON n.novel_id = cv.novel_id
        WHERE cv.user_id = ?
        UNION ALL
        SELECT n.category_id, 2.5 AS weight
        FROM Favorites f
        JOIN Novels n ON n.novel_id = f.novel_id
        WHERE f.user_id = ? AND f.is_active = 1
      ) src
      JOIN Categories cat ON cat.category_id = src.category_id
      GROUP BY cat.category_id
      ORDER BY score DESC
      LIMIT 5
      ''',
      [userId, userId],
    );

    final avgLength =
        (lengthResult.first['avg_length'] as num?)?.toDouble() ?? 0.0;
    final chaptersRead =
        (lengthResult.first['chapters_read'] as num?)?.toInt() ?? 0;
    final completed = (completionResult.first['completed'] as num?)?.toInt() ?? 0;
    final started = (completionResult.first['started'] as num?)?.toInt() ?? 0;
    final completionRate = started > 0 ? completed / started : 0.0;
    final preferred = timeResult.isNotEmpty
        ? timeResult.first['time_period'] as String
        : 'any';

    return {
      'avg_chapter_length': avgLength,
      'chapters_read': chaptersRead,
      'completion_rate': completionRate,
      'preferred_time': preferred,
      'top_categories': categoryResult,
    };
  }

  /// Personalised novel recommendations based on the behavior profile.
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations(
    int userId,
    Map<String, dynamic> userBehavior,
  ) async {
    try {
      final db = await DBHelper.database();
      final topCategories =
          (userBehavior['top_categories'] as List<Map<String, dynamic>>?) ?? [];

      if (topCategories.isEmpty) {
        // Cold start — fall back to popular novels.
        return await db.rawQuery('''
          SELECT n.*,
                 c1.category_name AS main_category,
                 c2.category_name AS secondary_category,
                 (n.likes * 1.0 / (n.number_of_views + 1)) AS popularity_score
          FROM Novels n
          LEFT JOIN Categories c1 ON c1.category_id = n.category_id
          LEFT JOIN Categories c2 ON c2.category_id = n.secondary_category_id
          WHERE n.is_published = 1 AND n.is_banned = 0
          ORDER BY popularity_score DESC, n.number_of_views DESC
          LIMIT 15
        ''');
      }

      final ids = topCategories.map((c) => c['category_id']).toList();
      final placeholders = List.filled(ids.length, '?').join(',');

      final result = await db.rawQuery(
        '''
        WITH NovelScores AS (
          SELECT
            n.*,
            c1.category_name AS main_category,
            c2.category_name AS secondary_category,
            (n.likes * 1.0 / (n.number_of_views + 1)) AS popularity_score,
            CASE
              WHEN n.category_id IN ($placeholders) THEN 1.0
              WHEN n.secondary_category_id IN ($placeholders) THEN 0.6
              ELSE 0.0
            END AS category_score
          FROM Novels n
          LEFT JOIN Categories c1 ON c1.category_id = n.category_id
          LEFT JOIN Categories c2 ON c2.category_id = n.secondary_category_id
          WHERE n.is_published = 1 AND n.is_banned = 0
        )
        SELECT *,
          (category_score * ? + popularity_score * ?) AS relevance_score
        FROM NovelScores
        WHERE novel_id NOT IN (
          SELECT novel_id FROM Favorites WHERE user_id = ? AND is_active = 1
        )
        ORDER BY relevance_score DESC, number_of_views DESC
        LIMIT 15
        ''',
        [...ids, ...ids, categoryWeight, likeRatioWeight, userId],
      );

      return result;
    } catch (e, st) {
      AppLogger.error('getPersonalizedRecommendations failed', e, st);
      return [];
    }
  }

  /// Analyse a single novel's content/update cadence.
  static Future<Map<String, dynamic>> analyzeNovelContent(int novelId) async {
    final db = await DBHelper.database();

    // 1. Chapter length stats.
    final lengthResult = await db.rawQuery(
      '''
      SELECT AVG(LENGTH(content)) AS avg_length,
             MIN(LENGTH(content)) AS min_length,
             MAX(LENGTH(content)) AS max_length,
             COUNT(*) AS chapter_count
      FROM Chapters
      WHERE novel_id = ?
      ''',
      [novelId],
    );

    // 2. Update cadence (uses LAG, supported in SQLite ≥ 3.25).
    final cadenceResult = await db.rawQuery(
      '''
      WITH ordered AS (
        SELECT created_at,
               JULIANDAY(created_at) -
               JULIANDAY(LAG(created_at) OVER (ORDER BY created_at)) AS gap_days
        FROM Chapters
        WHERE novel_id = ?
      )
      SELECT AVG(gap_days) AS avg_update_interval
      FROM ordered
      WHERE gap_days IS NOT NULL
      ''',
      [novelId],
    );

    // 3. Engagement consistency — sample-stddev computed manually (SQLite
    //    has no STDDEV).
    final engagementRows = await db.rawQuery(
      '''
      SELECT likes * 1.0 / NULLIF(number_of_views, 0) AS rate
      FROM Chapters
      WHERE novel_id = ? AND number_of_views > 0
      ''',
      [novelId],
    );

    double? engagementAvg;
    double? engagementStd;
    if (engagementRows.isNotEmpty) {
      final rates = engagementRows
          .map((r) => (r['rate'] as num?)?.toDouble() ?? 0.0)
          .toList();
      final mean = rates.reduce((a, b) => a + b) / rates.length;
      final variance =
          rates.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
              rates.length;
      engagementAvg = mean;
      engagementStd = variance > 0 ? math.sqrt(variance) : 0.0;
    }

    final row = lengthResult.first;
    final avgLength = (row['avg_length'] as num?)?.toDouble() ?? 0.0;
    final minLength = (row['min_length'] as num?)?.toDouble();
    final maxLength = (row['max_length'] as num?)?.toDouble();
    final chapterCount = (row['chapter_count'] as num?)?.toInt() ?? 0;

    final lengthVariance = (avgLength == 0 || minLength == null || maxLength == null)
        ? 0.0
        : (maxLength - minLength) / avgLength;

    final updateInterval =
        (cadenceResult.first['avg_update_interval'] as num?)?.toDouble();

    final qualityConsistency =
        (engagementAvg == null || engagementAvg == 0 || engagementStd == null)
            ? 0.0
            : engagementStd / engagementAvg;

    return {
      'avg_chapter_length': avgLength,
      'length_variance': lengthVariance,
      'update_interval': updateInterval,
      'quality_consistency': qualityConsistency,
      'chapter_count': chapterCount,
    };
  }

  /// Combine user behavior with a novel's analysis to score compatibility.
  static double calculateUserNovelCompatibility(
    Map<String, dynamic> userBehavior,
    Map<String, dynamic> novelAnalysis,
  ) {
    final userAvg = (userBehavior['avg_chapter_length'] as num?)?.toDouble() ?? 0.0;
    final novelAvg =
        (novelAnalysis['avg_chapter_length'] as num?)?.toDouble() ?? 0.0;
    final updateInterval =
        (novelAnalysis['update_interval'] as num?)?.toDouble() ?? 30.0;
    final quality =
        (novelAnalysis['quality_consistency'] as num?)?.toDouble() ?? 0.5;

    final lengthCompat = userAvg == 0
        ? 0.5
        : (1 - ((userAvg - novelAvg).abs() / userAvg)).clamp(0.0, 1.0);

    final cadenceCompat = updateInterval <= 7
        ? 1.0
        : updateInterval <= 14
            ? 0.8
            : updateInterval <= 30
                ? 0.5
                : 0.3;

    final qualityScore = quality <= 0.2
        ? 1.0
        : quality <= 0.4
            ? 0.8
            : quality <= 0.6
                ? 0.6
                : 0.4;

    return (lengthCompat * readTimeWeight) +
        (cadenceCompat * completionRateWeight) +
        (qualityScore * likeRatioWeight);
  }
}

