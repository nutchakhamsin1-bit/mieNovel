
class Novel {
  final int novelId;
  final int userId;
  final String title;
  final String description;
  final String writerName;
  final String? coverImage;
  final int numberOfViews;
  final int likes;
  final String? lastUpdated;
  final String? mainCategoryName;
  final String? secondaryCategoryName;
  final bool isBanned;
  final bool isPublished;

  Novel({
    required this.novelId,
    required this.userId,
    required this.title,
    required this.description,
    required this.writerName,
    this.coverImage,
    this.numberOfViews = 0,
    this.likes = 0,
    this.lastUpdated,
    this.mainCategoryName,
    this.secondaryCategoryName,
    this.isBanned = false,
    this.isPublished = true,
  });

  factory Novel.fromMap(Map<String, dynamic> map) {
    return Novel(
      novelId: map['novel_id'] as int,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      writerName: map['writer_name'] as String,
      coverImage: map['cover_image'] as String?,
      numberOfViews: map['number_of_views'] as int,
      likes: map['likes'] as int,
      lastUpdated: map['last_updated'] as String?,
      isPublished: map['is_published'] == 1,
      isBanned: (map['is_banned'] == 1),
      mainCategoryName: map['main_category_name'] as String?,
      secondaryCategoryName: map['secondary_category_name'] as String?,
    );
  }

  // 👇 เพิ่มตรงนี้เพื่อ debug ให้เห็นค่าเวลาพิมพ์ใน console
  @override
  String toString() {
    return 'Novel('
        'id: $novelId, '
        'userId: $userId, '
        'title: "$title", '
        'writer: "$writerName", '
        'views: $numberOfViews, '
        'likes: $likes, '
        'mainCat: "$mainCategoryName", '
        'secondCat: "$secondaryCategoryName", '
        'isBanned: $isBanned, '
        'isPublished: $isPublished'
        ')';
  }
}
