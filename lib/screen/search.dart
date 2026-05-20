import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mie_project/models/novel.dart';
import 'package:mie_project/screen/show_chapter.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/services/image_helper.dart';
import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/app_logger.dart';

enum SortBy { popular, latest, mostLiked, mostViewed }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;

  List<String> _categories = const [];
  String? _selectedCategory;
  SortBy _sortBy = SortBy.popular;

  bool _isLoading = true;
  List<Novel> _allNovels = const [];
  List<Novel> _filtered = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final novels = await DBHelper.fetchAllNovelsModel();
      final categories = await DBHelper.getAllCategoryNames();
      if (!mounted) return;
      setState(() {
        _allNovels = novels.where((n) => !n.isBanned && n.isPublished).toList();
        _categories = categories;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e, st) {
      AppLogger.error('Search load failed', e, st);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _applyFilters);
  }

  void _applyFilters() {
    final query = _queryController.text.trim().toLowerCase();
    List<Novel> result = _allNovels.where((n) {
      final matchesQuery = query.isEmpty ||
          n.title.toLowerCase().contains(query) ||
          n.writerName.toLowerCase().contains(query) ||
          (n.description.toLowerCase().contains(query));
      final matchesCategory = _selectedCategory == null ||
          n.mainCategoryName == _selectedCategory ||
          n.secondaryCategoryName == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case SortBy.popular:
        result.sort((a, b) {
          final scoreA = a.likes * 2 + a.numberOfViews;
          final scoreB = b.likes * 2 + b.numberOfViews;
          return scoreB.compareTo(scoreA);
        });
        break;
      case SortBy.latest:
        result.sort((a, b) {
          final ad = a.lastUpdated ?? '';
          final bd = b.lastUpdated ?? '';
          return bd.compareTo(ad);
        });
        break;
      case SortBy.mostLiked:
        result.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case SortBy.mostViewed:
        result.sort((a, b) => b.numberOfViews.compareTo(a.numberOfViews));
        break;
    }

    if (mounted) setState(() => _filtered = result);
  }

  String _sortLabel(SortBy s) {
    switch (s) {
      case SortBy.popular:
        return 'ยอดนิยม';
      case SortBy.latest:
        return 'อัปเดตล่าสุด';
      case SortBy.mostLiked:
        return 'ถูกใจมากสุด';
      case SortBy.mostViewed:
        return 'อ่านมากสุด';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหานิยาย'),
        elevation: 0,
        actions: [
          PopupMenuButton<SortBy>(
            tooltip: 'จัดเรียง',
            icon: const Icon(Icons.sort),
            initialValue: _sortBy,
            onSelected: (v) {
              setState(() => _sortBy = v);
              _applyFilters();
            },
            itemBuilder: (_) => SortBy.values
                .map((s) => PopupMenuItem(value: s, child: Text(_sortLabel(s))))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อเรื่อง / ผู้เขียน / คำอธิบาย',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _queryController.clear();
                          _applyFilters();
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final selected = _selectedCategory == null;
                  return ChoiceChip(
                    label: const Text('ทั้งหมด'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      _applyFilters();
                    },
                  );
                }
                final cat = _categories[index - 1];
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = selected ? null : cat);
                    _applyFilters();
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _EmptyState(query: _queryController.text)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            final novel = _filtered[i];
                            return _SearchResultTile(novel: novel);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Novel novel;
  const _SearchResultTile({required this.novel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChapterListScreen(
            novelId: novel.novelId,
            novelTitle: novel.title,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 70,
                height: 100,
                child: novel.coverImage != null && novel.coverImage!.isNotEmpty
                    ? buildCoverImage(novel.coverImage!)
                    : Container(
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.book,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    novel.writerName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (novel.mainCategoryName != null)
                        _CategoryBadge(label: novel.mainCategoryName!),
                      if (novel.secondaryCategoryName != null)
                        _CategoryBadge(
                          label: novel.secondaryCategoryName!,
                          isSecondary: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${novel.numberOfViews}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.favorite_border,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${novel.likes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final bool isSecondary;
  const _CategoryBadge({required this.label, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    final color = isSecondary ? AppColors.primaryLight : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              query.isEmpty
                  ? 'ลองค้นหาด้วยชื่อเรื่อง ผู้เขียน หรือเลือกหมวดหมู่ด้านบน'
                  : 'ไม่พบนิยายที่ตรงกับ "$query"',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
