import 'package:flutter/material.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/services/novel_analysis_service.dart';
import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/app_logger.dart';

/// Compact analytics dashboard for a single novel. Pulls aggregates from
/// NovelAnalysisService + DBHelper and renders them as cards/bars so the
/// writer can see how their work is doing at a glance.
class WriterDashboard extends StatefulWidget {
  final int novelId;
  final String novelTitle;

  const WriterDashboard({
    super.key,
    required this.novelId,
    required this.novelTitle,
  });

  @override
  State<WriterDashboard> createState() => _WriterDashboardState();
}

class _WriterDashboardState extends State<WriterDashboard> {
  bool _loading = true;
  Map<String, dynamic>? _novel;
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>> _chapters = const [];
  int _totalViews = 0;
  int _totalLikes = 0;
  int _totalComments = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final novel = await DBHelper.getNovelDetail(widget.novelId);
      final analysis =
          await NovelAnalysisService.analyzeNovelContent(widget.novelId);
      final chapters = await DBHelper.getChapters(widget.novelId);

      int views = 0;
      int likes = 0;
      int comments = 0;
      for (final c in chapters) {
        views += (c['number_of_views'] as int? ?? 0);
        likes += (c['likes'] as int? ?? 0);
        comments += (c['comment_count'] as int? ?? 0);
      }

      if (!mounted) return;
      setState(() {
        _novel = novel;
        _analysis = analysis;
        _chapters = chapters;
        _totalViews = views;
        _totalLikes = likes;
        _totalComments = comments;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.error('WriterDashboard load failed', e, st);
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.novelTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _heroCard(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _statTile(
                          icon: Icons.remove_red_eye_outlined,
                          label: 'ผู้อ่าน',
                          value: _formatNumber(_totalViews),
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _statTile(
                          icon: Icons.favorite_border,
                          label: 'ถูกใจ',
                          value: _formatNumber(_totalLikes),
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _statTile(
                          icon: Icons.chat_bubble_outline,
                          label: 'คอมเมนต์',
                          value: _formatNumber(_totalComments),
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _analysisCard(),
                  const SizedBox(height: AppSpacing.md),
                  _chaptersCard(),
                ],
              ),
            ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _novel?['title'] as String? ?? widget.novelTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'สถานะ: ${(_novel?['is_published'] == 1) ? 'เผยแพร่แล้ว' : 'ฉบับร่าง'}'
            '${(_novel?['is_banned'] == 1) ? ' • ถูกระงับ' : ''}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (_analysis != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  'ตอนทั้งหมด ${(_analysis!['chapter_count'] as int?) ?? 0}',
                ),
                if ((_analysis!['update_interval'] as num?) != null)
                  _chip(
                    'อัปเดตทุก ${(_analysis!['update_interval'] as num).toStringAsFixed(1)} วัน',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisCard() {
    if (_analysis == null) return const SizedBox.shrink();
    final avgLength = (_analysis!['avg_chapter_length'] as num?)?.toDouble() ?? 0;
    final quality = (_analysis!['quality_consistency'] as num?)?.toDouble() ?? 0;
    final lengthVar = (_analysis!['length_variance'] as num?)?.toDouble() ?? 0;

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'การวิเคราะห์เนื้อหา',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metricRow(
            label: 'ความยาวเฉลี่ยต่อตอน',
            value: '${avgLength.toStringAsFixed(0)} ตัวอักษร',
          ),
          _metricRow(
            label: 'ความสม่ำเสมอของความยาว',
            value: lengthVar == 0
                ? 'ยังไม่มีข้อมูล'
                : '${(100 * (1 - lengthVar.clamp(0.0, 1.0))).toStringAsFixed(0)}%',
          ),
          _metricRow(
            label: 'การมีส่วนร่วม (engagement)',
            value: quality == 0
                ? 'ยังไม่มีข้อมูล'
                : 'ผันผวน ${(quality * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _metricRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _chaptersCard() {
    if (_chapters.isEmpty) {
      return Container(
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: const Text('ยังไม่มีตอน — เริ่มเขียนตอนแรกของคุณได้เลย!'),
      );
    }

    final maxViews = _chapters
        .map((c) => c['number_of_views'] as int? ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      decoration: AppDecorations.card(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'ยอดอ่านต่อตอน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._chapters.map((c) {
            final views = c['number_of_views'] as int? ?? 0;
            final ratio = maxViews == 0 ? 0.0 : views / maxViews;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ตอนที่ ${c['chapter_number']}: ${c['title'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        _formatNumber(views),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.divider.withValues(alpha: 0.4),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
