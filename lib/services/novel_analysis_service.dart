import 'package:mie_project/services/db_helper.dart';

class NovelAnalysisService {
  // คะแนนการวิเคราะห์นิยาย
  static const double CATEGORY_WEIGHT = 0.3;
  static const double READ_TIME_WEIGHT = 0.2;
  static const double COMPLETION_RATE_WEIGHT = 0.15;
  static const double LIKE_RATIO_WEIGHT = 0.15;
  static const double TREND_WEIGHT = 0.1;
  static const double AGE_GROUP_WEIGHT = 0.1;

  // วิเคราะห์พฤติกรรมการอ่านของผู้ใช้
  static Future<Map<String, dynamic>> analyzeUserReadingBehavior(int userId) async {
    final db = await DBHelper.database();
    
    // 1. ระยะเวลาการอ่านเฉลี่ยต่อบท
    final readTimeResult = await db.rawQuery('''
      SELECT AVG(reading_duration) as avg_read_time
      FROM (
        SELECT chapter_id, 
               MAX(created_at) - MIN(created_at) as reading_duration
        FROM ChapterViews
        WHERE user_id = ?
        GROUP BY chapter_id
      )
    ''', [userId]);

    // 2. อัตราการอ่านจบ
    final completionResult = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT CASE WHEN completion_rate >= 0.8 THEN novel_id END) as completed_novels,
        COUNT(DISTINCT novel_id) as total_started_novels
      FROM (
        SELECT n.novel_id,
               COUNT(DISTINCT cv.chapter_id) * 1.0 / COUNT(DISTINCT c.chapter_id) as completion_rate
        FROM Novels n
        JOIN Chapters c ON n.novel_id = c.novel_id
        LEFT JOIN ChapterViews cv ON c.chapter_id = cv.chapter_id AND cv.user_id = ?
        GROUP BY n.novel_id
      )
    ''', [userId]);

    // 3. ช่วงเวลาที่ชอบอ่าน
    final readingTimeResult = await db.rawQuery('''
      SELECT 
        CASE 
          WHEN strftime('%H', created_at) BETWEEN '06' AND '11' THEN 'morning'
          WHEN strftime('%H', created_at) BETWEEN '12' AND '17' THEN 'afternoon'
          WHEN strftime('%H', created_at) BETWEEN '18' AND '23' THEN 'evening'
          ELSE 'night'
        END as time_period,
        COUNT(*) as read_count
      FROM ChapterViews
      WHERE user_id = ?
      GROUP BY time_period
      ORDER BY read_count DESC
    ''', [userId]);

    final _avgReadTime = (readTimeResult.first['avg_read_time'] as num?)?.toDouble() ?? 0.0;
    final _completed = (completionResult.first['completed_novels'] as num?)?.toDouble() ?? 0.0;
    final _totalStarted = (completionResult.first['total_started_novels'] as num?)?.toDouble() ?? 0.0;
    final _completionRate = _totalStarted > 0.0 ? _completed / _totalStarted : 0.0;
    final _preferredTime = readingTimeResult.isNotEmpty
        ? (readingTimeResult.first['time_period'] as String)
        : 'any';

    return {
      'avg_read_time': _avgReadTime,
      'completion_rate': _completionRate,
      'preferred_time': _preferredTime
    };
  }

  // วิเคราะห์นิยายที่เหมาะสมกับผู้ใช้
  static Future<List<Map<String, dynamic>>> getPersonalizedRecommendations(
    int userId,
    Map<String, dynamic> userBehavior
  ) async {
    final db = await DBHelper.database();
    
    final readingTime = userBehavior['avg_read_time'] as double;
    final completionRate = userBehavior['completion_rate'] as double;
    final preferredTime = userBehavior['preferred_time'] as String;

    // คำนวณคะแนนความเหมาะสมของแต่ละเรื่อง
    final recommendations = await db.rawQuery('''
      WITH NovelScores AS (
        SELECT 
          n.*,
          c1.category_name as main_category,
          c2.category_name as secondary_category,
          -- คะแนนความนิยม
          (n.likes * 1.0 / (n.number_of_views + 1)) as popularity_score,
          -- คะแนนความยาวเหมาะสม
          (1 - ABS(
            (SELECT AVG(LENGTH(content)) FROM Chapters WHERE novel_id = n.novel_id) - ?
          ) / (SELECT MAX(LENGTH(content)) FROM Chapters)) as length_score,
          -- คะแนนแนวโน้ม
          (n.likes - n.previous_likes) / (n.number_of_views - n.previous_views + 1) as trend_score
        FROM Novels n
        LEFT JOIN Categories c1 ON n.category_id = c1.category_id
        LEFT JOIN Categories c2 ON n.secondary_category_id = c2.category_id
        WHERE n.is_published = 1 AND n.is_banned = 0
      )
      SELECT 
        *,
        (
          popularity_score * ? +
          length_score * ? +
          trend_score * ?
        ) as relevance_score
      FROM NovelScores
      WHERE novel_id NOT IN (
        SELECT novel_id FROM Favorites WHERE user_id = ?
      )
      ORDER BY relevance_score DESC
      LIMIT 15
    ''', [
      readingTime,
      LIKE_RATIO_WEIGHT,
      READ_TIME_WEIGHT,
      TREND_WEIGHT,
      userId
    ]);

    return recommendations;
  }

  // วิเคราะห์เนื้อหาและสไตล์การเขียน
  static Future<Map<String, dynamic>> analyzeNovelContent(int novelId) async {
    final db = await DBHelper.database();
    
    // 1. ความยาวเฉลี่ยต่อบท
    final chapterLengthResult = await db.rawQuery('''
      SELECT 
        AVG(LENGTH(content)) as avg_length,
        MIN(LENGTH(content)) as min_length,
        MAX(LENGTH(content)) as max_length
      FROM Chapters
      WHERE novel_id = ?
    ''', [novelId]);

    // 2. อัตราการอัพเดต
    final updatePatternResult = await db.rawQuery('''
      WITH ChapterDates AS (
        SELECT 
          created_at,
          JULIANDAY(created_at) - JULIANDAY(LAG(created_at) OVER (ORDER BY created_at)) as days_between
        FROM Chapters
        WHERE novel_id = ?
        ORDER BY created_at
      )
      SELECT AVG(days_between) as avg_update_interval
      FROM ChapterDates
      WHERE days_between IS NOT NULL
    ''', [novelId]);

    // 3. ความสม่ำเสมอของคุณภาพ (วัดจาก likes/views ต่อบท)
    final qualityConsistencyResult = await db.rawQuery('''
      SELECT 
        AVG(likes * 1.0 / NULLIF(number_of_views, 0)) as avg_engagement,
        STDDEV(likes * 1.0 / NULLIF(number_of_views, 0)) as engagement_stddev
      FROM Chapters
      WHERE novel_id = ? AND number_of_views > 0
    ''', [novelId]);

    final avgLength = (chapterLengthResult.first['avg_length'] as num?)?.toDouble() ?? 0.0;
    final minLength = (chapterLengthResult.first['min_length'] as num?)?.toDouble();
    final maxLength = (chapterLengthResult.first['max_length'] as num?)?.toDouble();

    double lengthVariance;
    if (avgLength == 0.0 || minLength == null || maxLength == null) {
      lengthVariance = 0.0;
    } else {
      lengthVariance = (maxLength - minLength) / avgLength;
    }

    final updateInterval = (updatePatternResult.first['avg_update_interval'] as num?)?.toDouble();

    final engagementAvg = (qualityConsistencyResult.first['avg_engagement'] as num?)?.toDouble();
    final engagementStd = (qualityConsistencyResult.first['engagement_stddev'] as num?)?.toDouble();
    final qualityConsistency = (engagementAvg == null || engagementAvg == 0.0 || engagementStd == null)
        ? 0.0
        : engagementStd / engagementAvg;

    return {
      'avg_chapter_length': avgLength,
      'length_variance': lengthVariance,
      'update_interval': updateInterval,
      'quality_consistency': qualityConsistency
    };
  }

  // คำนวณความเหมาะสมกับผู้ใช้
  static double calculateUserNovelCompatibility(
    Map<String, dynamic> userBehavior,
    Map<String, dynamic> novelAnalysis
  ) {
    double score = 0.0;
    
    // 1. ความเหมาะสมด้านความยาว
    final lengthCompatibility = 1.0 - (
      (userBehavior['avg_read_time'] - novelAnalysis['avg_chapter_length']).abs() /
      userBehavior['avg_read_time']
    ).clamp(0.0, 1.0);
    
    // 2. ความเหมาะสมด้านการอัพเดต
    final updateCompatibility = novelAnalysis['update_interval'] <= 7 ? 1.0 :
                              novelAnalysis['update_interval'] <= 14 ? 0.8 :
                              novelAnalysis['update_interval'] <= 30 ? 0.5 : 0.3;
    
    // 3. ความเหมาะสมด้านคุณภาพ
    final qualityScore = novelAnalysis['quality_consistency'] <= 0.2 ? 1.0 :
                        novelAnalysis['quality_consistency'] <= 0.4 ? 0.8 :
                        novelAnalysis['quality_consistency'] <= 0.6 ? 0.6 : 0.4;

    // คำนวณคะแนนรวมแบบถ่วงน้ำหนัก
    score = (lengthCompatibility * READ_TIME_WEIGHT) +
            (updateCompatibility * COMPLETION_RATE_WEIGHT) +
            (qualityScore * LIKE_RATIO_WEIGHT);

    return score;
  }
}
