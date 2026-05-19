import 'package:mie_project/data/data_scripts.dart';
import 'package:mie_project/models/novel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static Database? _db;

  // Method to get the database instance
  static Future<Database> database() async {
    return await initDb();
  }

  // ---------------------- INITIALIZE DATABASE ----------------------
  static Future<Database> initDb() async {
    if (_db != null) return _db!;
    String path;
    if (kIsWeb) {
      path = 'novel_app.db';
    } else {
      path = join(await getDatabasesPath(), 'novel_app.db');
    }

    _db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // ---------------------- USERS ----------------------
        await db.execute('''
          CREATE TABLE Users(
            user_id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            email TEXT,
            password TEXT,
            name TEXT,
            surname TEXT,
            avatar_image TEXT,
            birthdate TEXT,
            ai_analysis_data TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'active',
            is_writer BOOLEAN DEFAULT false
          )
        ''');

        // ---------------------- ADMINS ----------------------
        await db.execute('''
          CREATE TABLE Admins(
            admin_id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'active'
          )
        ''');

        // ---------------------- CATEGORIES ----------------------
        await db.execute('''
          CREATE TABLE Categories(
            category_id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_name TEXT,
            description TEXT
          )
        ''');

        // ---------------------- NOVELS ----------------------
        await db.execute('''
          CREATE TABLE Novels(
            novel_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            category_id INTEGER,
            secondary_category_id INTEGER,
            title TEXT,
            description TEXT,
            age_limit TEXT,
            writer_name TEXT,
            cover_image TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            number_of_views INTEGER DEFAULT 0,
            likes INTEGER DEFAULT 0,  
            last_updated TEXT,
            is_published BOOLEAN DEFAULT false,
            number_of_warnings INTEGER DEFAULT 0,
            is_banned BOOLEAN DEFAULT false,
            FOREIGN KEY(user_id) REFERENCES Users(user_id),
            FOREIGN KEY(category_id) REFERENCES Categories(category_id),
            FOREIGN KEY(secondary_category_id) REFERENCES Categories(category_id)
          )
        ''');

        // ---------------------- CHAPTERS ----------------------
        await db.execute('''
          CREATE TABLE Chapters(
            chapter_id INTEGER PRIMARY KEY AUTOINCREMENT,
            novel_id INTEGER,
            chapter_number INTEGER,
            title TEXT,
            content TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            last_updated TEXT,
            is_published BOOLEAN DEFAULT false,
            number_of_views INTEGER DEFAULT 0,
            likes INTEGER DEFAULT 0,
            comment_count INTEGER DEFAULT 0,
            FOREIGN KEY(novel_id) REFERENCES Novels(novel_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE ChapterLikes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            chapter_id INTEGER,
            UNIQUE(user_id, chapter_id)
          );
        ''');

        // ---------------------- COMMENTS ----------------------
        await db.execute('''
          CREATE TABLE Comments(
            comment_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            chapter_id INTEGER,
            parent_id INTEGER,
            content TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            is_deleted BOOLEAN DEFAULT false,
            FOREIGN KEY(user_id) REFERENCES Users(user_id),
            FOREIGN KEY(chapter_id) REFERENCES Chapters(chapter_id),
            FOREIGN KEY(parent_id) REFERENCES Comments(comment_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE CommentLikes(
            like_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            comment_id INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(user_id) REFERENCES Users(user_id),
            FOREIGN KEY(comment_id) REFERENCES Comments(comment_id)
          )
        ''');

        // ---------------------- REPORTS ----------------------
        await db.execute('''
          CREATE TABLE Reports(
            report_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            chapter_id INTEGER,
            remark TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'pending',
            punishment_detail TEXT,
            punishment_time TEXT,
            FOREIGN KEY(user_id) REFERENCES Users(user_id),
            FOREIGN KEY(chapter_id) REFERENCES Chapters(chapter_id)
          )
        ''');

        // ---------------------- NOTIFICATIONS ----------------------
        await db.execute('''
          CREATE TABLE Notifications (
              notification_id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              novel_id INTEGER,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              type TEXT,
              message TEXT,
              is_read BOOLEAN DEFAULT FALSE,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY(user_id) REFERENCES Users(user_id),
              FOREIGN KEY(novel_id) REFERENCES Novels(novel_id)
          )
        ''');

        // ---------------------- FAVORITES ----------------------
        await db.execute('''
          CREATE TABLE Favorites(
            favorite_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            novel_id INTEGER,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            is_active BOOLEAN DEFAULT true,
            FOREIGN KEY(user_id) REFERENCES Users(user_id),
            FOREIGN KEY(novel_id) REFERENCES Novels(novel_id)
          )
        ''');
        await _insertInitialDataIfEmpty(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Re-seed missing data when upgrading from an older DB version
        print('🔄 DB upgrade from v$oldVersion to v$newVersion — checking seed data...');
        await _insertInitialDataIfEmpty(db);
      },
      onOpen: (db) async {
        // Ensure data is seeded even if onCreate already ran with broken SQL
        await _insertInitialDataIfEmpty(db);
      },
    );

    return _db!;
  }

  // ฟังก์ชันคัดลอก Asset ไปเป็น File
  static Future<String> copyAssetToFile(
    String assetPath,
    String fileName,
  ) async {
    // On web, just return the asset path directly
    if (kIsWeb) {
      return assetPath;
    }
    try {
      // 1. อ่านข้อมูลไบนารี (ByteData) จาก Asset
      final ByteData data = await rootBundle.load(assetPath);

      // 2. แปลง ByteData เป็น List<int>
      final List<int> bytes = data.buffer.asUint8List();

      // 3. กำหนดพาธที่จะบันทึกไฟล์ (เช่น Document Directory)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String targetDirectory =
          '${appDocDir.path}/novel_covers'; // สร้างโฟลเดอร์ย่อยเพื่อให้เป็นระเบียบ

      // 4. ตรวจสอบและสร้างโฟลเดอร์ปลายทาง
      final Directory directory = Directory(targetDirectory);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 5. สร้าง File Object สำหรับไฟล์ปลายทาง
      final String targetPath = '$targetDirectory/$fileName';
      final File file = File(targetPath);

      // 6. เขียนข้อมูลไบนารีลงในไฟล์
      await file.writeAsBytes(bytes);

      // 7. คืนค่าพาธไฟล์จริงบนเครื่อง Android
      return targetPath;
    } catch (e) {
      print("Error copying asset to file: $e");
      // คืนค่าว่างหรือ throw error ตามความเหมาะสม
      return '';
    }
  }

  // สร้างฟังก์ชันช่วยใน DBHelper
  static Future<void> _insertNovelsWithFilePaths(
    Database db,
    List<String> filePaths,
  ) async {
    // ต้องมั่นใจว่า kInitialNovelsList ถูกกำหนดใน data_scripts.dart
    // โดย kInitialNovelsList คือ List<Map<String, dynamic>> ของข้อมูลนิยาย 20 เรื่อง

    for (int i = 0; i < kInitialNovelsList.length; i++) {
      Map<String, dynamic> novelData = Map.from(kInitialNovelsList[i]);

      // เพิ่ม/แก้ไข cover_image ด้วยพาธไฟล์จริง
      novelData['cover_image'] = filePaths[i];

      // ลบคอลัมน์ที่ไม่จำเป็นออก หรือตรวจสอบว่า Map ตรงกับคอลัมน์ใน DB

      await db.insert(
        'Novels',
        novelData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ---------------------- INITIAL SAMPLE DATA ----------------------
  // ในไฟล์ DBHelper.dart

  static Future<void> _insertInitialDataIfEmpty(Database db) async {
    var users = await db.query('Users', limit: 1);

    if (users.isEmpty) {
      print('✅ Inserting initial data for all tables...');
      try {
        // 1. INSERT ข้อมูลพื้นฐานที่ไม่พึ่งพาใครก่อน
        await db.execute(kInsertUsers);
        await db.execute(kInsertAdmins);
        await db.execute(kInsertCategories);

        // 2. คัดลอกรูปภาพ Asset ไปเป็น File และเก็บพาธจริง
        print('🔄 Copying novel cover assets to document directory...');
        List<String> realFilePaths = [];
        for (int i = 0; i < kNovelAssetPaths.length; i++) {
          final String assetPath = kNovelAssetPaths[i];
          final String fileName = assetPath.split('/').last;
          final String filePath = await copyAssetToFile(assetPath, fileName);
          realFilePaths.add(filePath);
        }
        print('✅ All novel covers copied successfully.');

        // 3. INSERT ข้อมูล Novels โดยใช้พาธไฟล์จริงที่เพิ่งคัดลอกมา
        await _insertNovelsWithFilePaths(db, realFilePaths);

        // 4. INSERT ข้อมูลที่พึ่งพา Novel ID (และ User ID)
        await db.execute(kInsertChapters);
        await db.execute(kInsertComments);
        await db.execute(kInsertFavorites);

        print('✅ Initial data inserted successfully.');
      } catch (e) {
        print('❌ Error inserting initial data: $e');
      }
    } else {
      // Users exist — check if Novels are also seeded (stale DB recovery)
      var novels = await db.query('Novels', limit: 1);
      if (novels.isEmpty) {
        print('⚠️ Users exist but Novels table is empty — re-seeding novels, chapters, comments, favorites...');
        try {
          // Categories may also be missing
          var categories = await db.query('Categories', limit: 1);
          if (categories.isEmpty) {
            await db.execute(kInsertCategories);
          }

          List<String> realFilePaths = [];
          for (int i = 0; i < kNovelAssetPaths.length; i++) {
            final String assetPath = kNovelAssetPaths[i];
            final String fileName = assetPath.split('/').last;
            final String filePath = await copyAssetToFile(assetPath, fileName);
            realFilePaths.add(filePath);
          }

          await _insertNovelsWithFilePaths(db, realFilePaths);
          await db.execute(kInsertChapters);
          await db.execute(kInsertComments);
          await db.execute(kInsertFavorites);
          print('✅ Novel data re-seeded successfully.');
        } catch (e) {
          print('❌ Error re-seeding novel data: $e');
        }
      } else {
        print('ℹ️ Users already exist — skipping data insertion.');
      }
    }
  }

  // ---------------------- CRUD: USERS ----------------------

  // Add a new user
  static Future<int> insertUser({
    required String username,
    required String password,
    required String birthdate,
    String? email,
    String? name,
    String? surname,
    String? avatarImage,
    String? aiAnalysisData,
    String status = 'active',
    bool isWriter = false,
  }) async {
    final db = await initDb();
    return await db.insert('Users', {
      'username': username,
      'password': password,
      'birthdate': birthdate,
      'email': email,
      'name': name ?? '',
      'surname': surname ?? '',
      'avatar_image': avatarImage ?? '',
      'ai_analysis_data': aiAnalysisData ?? '{}',
      'status': status,
      'is_writer': isWriter ? 1 : 0,
    });
  }

  // Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database();
    return await db.rawQuery('''
      SELECT user_id, name, surname, email, status, is_writer
      FROM Users
      ORDER BY created_at DESC;
    ''');
  }

  // Get all categories
  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await initDb();
    return await db.query('Categories', orderBy: 'category_id DESC');
  }

  // Insert initial categories
  static Future<void> insertInitialCategories(List<String> categories) async {
    final db = await initDb();
    final batch = db.batch();

    for (final categoryName in categories) {
      // 💡 คุณสามารถกำหนด description ที่สอดคล้องกับแต่ละหมวดหมู่ได้
      // แต่ในตัวอย่างนี้ใช้คำอธิบายทั่วไปเพื่อความรวดเร็ว
      String description = 'เรื่องราวในหมวดหมู่ $categoryName';

      batch.insert('Categories', {
        'category_name': categoryName,
        'description': description,
      });
    }

    await batch.commit(noResult: true);
    print('✅ Initial categories inserted successfully.');
  }

  // Get user by email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await initDb();
    final res = await db.query('Users', where: 'email = ?', whereArgs: [email]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // Update user
  static Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await initDb();
    return await db.update(
      'Users',
      data,
      where: 'user_id = ?',
      whereArgs: [id],
    );
  }

  // Delete user
  static Future<int> deleteUser(int id) async {
    final db = await initDb();
    return await db.delete('Users', where: 'user_id = ?', whereArgs: [id]);
  }

  // User login
  static Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    final db = await initDb();
    final result = await db.query(
      'Users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (result.isNotEmpty) {
      print('👤 Logged in user: ${result.first}');
      return result.first;
    } else {
      return null;
    }
  }

  // forget password
  static Future<int> resetPassword(String email, String newPassword) async {
    final db = await initDb();
    return await db.update(
      'Users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // sign in
  static Future<int> signIn(
    String email,
    String password,
    String userName,
    String firstName,
    String lastName,
    String dateTime,
    String _profileImage,
  ) async {
    final db = await initDb();
    return await db.insert('Users', {
      'email': email,
      'password': password,
      'username': userName,
      'name': firstName,
      'surname': lastName,
      'birthdate': dateTime,
      'avatar_image': _profileImage,
    });
  }

  // Get user by ID
  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await initDb();
    final List<Map<String, dynamic>> result = await db.query(
      'Users',
      where: 'user_id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> adminLogin(
    String username,
    String password,
  ) async {
    final db = await initDb();
    final res = await db.query(
      'Admins',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return res.isNotEmpty ? res.first : null;
  }

  // ---------------------- CRUD: CATEGORIES ----------------------
  // Get all category names
  static Future<List<String>> getAllCategoryNames() async {
    final db = await initDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'Categories',
      columns: ['category_name'], // ดึงมาเฉพาะชื่อหมวดหมู่
    );

    // แปลง List<Map> ให้เป็น List<String>
    return List.generate(maps.length, (i) {
      return maps[i]['category_name'] as String;
    });
  }

  // Get category ID by name
  static Future<int?> getCategoryIdByName(String categoryName) async {
    final db = await initDb();
    final List<Map<String, dynamic>> maps = await db.query(
      'Categories',
      columns: ['category_id'],
      where: 'category_name = ?',
      whereArgs: [categoryName],
    );

    if (maps.isNotEmpty) {
      return maps.first['category_id'] as int;
    }
    return null;
  }

  // ---------------------- CRUD: NOVELS & CHAPTERS ----------------------
  // Insert a new novel
  static Future<int> insertNovel({
    required int userId,
    required int mainCategoryId,
    int? secondaryCategoryId, // รับเป็น int? เพราะอาจไม่มีหมวดหมู่รอง
    required String title,
    required String description,
    required String ageLimit,
    required String writerName,
    required String coverImagePath,
    bool isPublished = true,
  }) async {
    final db = await initDb();
    final now = DateTime.now().toIso8601String();

    return await db.insert('Novels', {
      'user_id': userId,
      'category_id': mainCategoryId,
      'secondary_category_id': secondaryCategoryId,
      'title': title,
      'description': description,
      'age_limit': ageLimit,
      'writer_name': writerName,
      'cover_image': coverImagePath,
      'created_at': now,
      'last_updated': now,
      'is_published': isPublished ? 1 : 0, // 🔴
      'likes': 0, // เริ่มต้นที่ 0
    });
  }

  // ดึงข้อมูลนิยายตาม ID
  static Future<Map<String, dynamic>?> getNovelById(int novelId) async {
    final db = await initDb();
    final result = await db.query(
      'Novels',
      where: 'novel_id = ?',
      whereArgs: [novelId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<List<Novel>> getNovelsByCategory(String categoryName) async {
    final db = await database();

    final List<Map<String, dynamic>> novelMaps = await db.rawQuery(
      '''
    SELECT n.*, c1.category_name AS mainCategoryName, c2.category_name AS secondaryCategoryName
    FROM Novels n
    LEFT JOIN Categories c1 ON n.category_id = c1.category_id 
    LEFT JOIN Categories c2 ON n.secondary_category_id = c2.category_id 
    WHERE c1.category_name = ? OR c2.category_name = ?
    ORDER BY n.novel_id DESC 
    LIMIT 20
  ''',
      [categoryName, categoryName],
    );

    return novelMaps.map((map) => Novel.fromMap(map)).toList();
  }

  // ✅ ฟังก์ชันสำหรับดึงข้อมูลนิยาย 1 เรื่อง พร้อมชื่อหมวดหมู่
  static Future<Map<String, dynamic>?> getNovelDetail(int novelId) async {
    final db = await database();

    // 💡 ใช้ rawQuery พร้อม LEFT JOIN เพื่อดึงชื่อหมวดหมู่
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
    SELECT 
      N.*, 
      C1.category_name AS main_category_name,  -- 💡 ชื่อหมวดหมู่หลัก
      C2.category_name AS secondary_category_name -- 💡 ชื่อหมวดหมู่รอง
    FROM Novels AS N
    LEFT JOIN Categories AS C1 ON N.category_id = C1.category_id
    LEFT JOIN Categories AS C2 ON N.secondary_category_id = C2.category_id
    WHERE N.novel_id = ?
  ''',
      [novelId],
    );

    if (result.isNotEmpty) {
      // คืนค่า Map แถวแรกที่พบ ซึ่งมีชื่อหมวดหมู่รวมอยู่ด้วย
      return result.first;
    }
    return null; // ไม่พบข้อมูล
  }

  // 🔹 ฟังก์ชันบันทึกตอนใหม่
  static Future<int> insertChapter(Map<String, dynamic> chapterData) async {
    final db = await initDb();
    // ค่า content จะถูกตั้งเป็นค่าว่างหรือค่าเริ่มต้นเมื่อสร้างบทใหม่
    final id = await db.insert(
      'Chapters',
      chapterData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id; // คืนค่า chapter_id ที่ถูกสร้างขึ้นมา
  }

  // 🔹 ดึงตอนทั้งหมดของนิยายเรื่องหนึ่ง
  static Future<List<Map<String, dynamic>>> getChapters(int novelId) async {
    final db = await initDb();
    return await db.query(
      'Chapters',
      where: 'novel_id = ?',
      whereArgs: [novelId],
      orderBy: 'chapter_id ASC',
    );
  }

  // ดึงข้อมูลบทตาม ID
  static Future<Map<String, dynamic>?> getChapterById({
    required int novelId,
    required int chapterId,
  }) async {
    final db = await initDb();
    final List<Map<String, dynamic>> result = await db.query(
      'Chapters',
      where: 'novel_id = ? AND chapter_id = ?',
      whereArgs: [novelId, chapterId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // อัปเดตบท
  static Future<int> updateChapter({
    required int chapterId,
    required String content,
    required bool isPublished,
    String? newTitle,
  }) async {
    final db = await initDb();
    final now = DateTime.now().toIso8601String();

    final Map<String, dynamic> data = {
      'content': content,
      'last_updated': now,
      'is_published': isPublished ? 1 : 0,
    };

    if (newTitle != null && newTitle.isNotEmpty) {
      data['title'] = newTitle;
    }

    return await db.update(
      'Chapters',
      data,
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  // 🛑 ฟังก์ชันใหม่: ลบบท (Delete Chapter)
  static Future<int> deleteChapter({required int chapterId}) async {
    final db = await initDb();

    final int rowsAffected = await db.delete(
      'Chapters',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );

    print('🗑️ Deleted Chapter ID: $chapterId, Rows affected: $rowsAffected');
    return rowsAffected; // คืนค่าจำนวนแถวที่ถูกลบไป
  }

  // 🛑 ฟังก์ชันใหม่: ลบนิยาย (Delete Novel) พร้อมลบข้อมูลที่เกี่ยวข้องทั้งหมด
  static Future<int> deleteNovel(int novelId) async {
    final db = await initDb();

    // 1. ลบข้อมูลที่ขึ้นกับ novel_id ในตารางอื่นๆ ก่อน
    // เนื่องจากเราตั้งค่า PRAGMA foreign_keys = ON ไว้ การลบแบบ CASCADE จะช่วยได้
    // แต่ใน SQLite มักจะใช้การลบที่สัมพันธ์กันเอง (manual) ก่อน

    // ลบ Favorites ที่ผูกกับ novel_id นี้
    await db.delete('Favorites', where: 'novel_id = ?', whereArgs: [novelId]);

    // ลบ Reports ที่ผูกกับบทของ novel_id นี้ (ต้องลบ Comment ก่อน)
    // เนื่องจาก Comments และ Reports ผูกกับ Chapter เราต้องหา Chapter ID ก่อน
    final chapterResults = await db.query(
      'Chapters',
      columns: ['chapter_id'],
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
    final chapterIds = chapterResults.map((c) => c['chapter_id']).toList();

    if (chapterIds.isNotEmpty) {
      final inClause = chapterIds.map((_) => '?').join(',');
      // ลบ Comments ที่ผูกกับ Chapters เหล่านี้
      await db.delete(
        'Comments',
        where: 'chapter_id IN ($inClause)',
        whereArgs: chapterIds,
      );
      // ลบ Reports ที่ผูกกับ Chapters เหล่านี้
      await db.delete(
        'Reports',
        where: 'chapter_id IN ($inClause)',
        whereArgs: chapterIds,
      );
    }

    // 2. ลบ Chapters ที่ผูกกับ novel_id นี้
    await db.delete('Chapters', where: 'novel_id = ?', whereArgs: [novelId]);

    // 3. ลบนิยาย (Novels)
    final int rowsAffected = await db.delete(
      'Novels',
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );

    print('🗑️ Deleted Novel ID: $novelId, Rows affected: $rowsAffected');
    return rowsAffected; // คืนค่าจำนวนแถวที่ถูกลบไป (ของตาราง Novels)
  }

  // ✅ อัปเดตข้อมูลนิยาย (title, description, categories, age_limit, cover)
  static Future<int> updateNovel({
    required int novelId,
    required String title,
    required String description,
    required String writerName,
    required String ageLimit,
    required int mainCategoryId,
    int? secondaryCategoryId,
    String? coverImagePath,
  }) async {
    final db = await initDb();
    final now = DateTime.now().toIso8601String();

    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'writer_name': writerName,
      'age_limit': ageLimit,
      'category_id': mainCategoryId,
      'secondary_category_id': secondaryCategoryId,
      'last_updated': now,
    };

    if (coverImagePath != null && coverImagePath.isNotEmpty) {
      data['cover_image'] = coverImagePath;
    }

    return await db.update(
      'Novels',
      data,
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
  }

  // ดึงนิยายทั้งหมดของผู้ใช้คนหนึ่ง
  static Future<List<Map<String, dynamic>>> getNovelsByUser(int userId) async {
    final db = await initDb();
    return await db.query(
      'Novels',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_updated DESC',
    );
  }

  // ดึงนิยายทั้งหมด (เช่นสำหรับหน้า Explore)
  static Future<List<Map<String, dynamic>>> getAllNovels() async {
    final db = await initDb();
    return await db.query('Novels', orderBy: 'number_of_views DESC');
  }

  static Future<List<Novel>> fetchAllNovelsModel() async {
    final db = await initDb();
    final result = await db.query('Novels', orderBy: 'number_of_views DESC');
    return result.map((row) => Novel.fromMap(row)).toList();
  }

  // ดึงข้อมูลบทตามหมายเลขบท
  static Future<Map<String, dynamic>?> getChapterByNumber({
    required int novelId,
    required int chapterNumber,
  }) async {
    final db = await initDb();
    final List<Map<String, dynamic>> result = await db.query(
      'Chapters',
      where: 'novel_id = ? AND chapter_number = ?',
      whereArgs: [novelId, chapterNumber],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // lib/services/db_helper.dart

  static Future<List<Map<String, dynamic>>> getFavoriteNovels(
    int userId,
  ) async {
    final db = await initDb();

    // ⭐ ระบุคอลัมน์ที่ต้องการอย่างชัดเจน (สมมติว่า Novels มี: novel_id, title, cover_image, is_banned)
    return await db.rawQuery(
      '''
      SELECT 
        n.novel_id, 
        n.title, 
        n.cover_image, 
        n.is_banned,  -- ⭐ เพิ่มคอลัมน์สถานะการแบน
        f.user_id     -- คอลัมน์จาก Favorites ที่อาจมีประโยชน์
      FROM Novels n
      JOIN Favorites f ON n.novel_id = f.novel_id
      WHERE f.user_id = ? AND f.is_active = 1
      ORDER BY f.created_at DESC
    ''',
      [userId],
    );
  }

  // 🛑 ต้องเพิ่ม return statement
  static Future<Map<String, dynamic>?> getChaptersByNovelId({
    required int novelId,
  }) async {
    final db = await initDb();
    final List<Map<String, dynamic>> result = await db.query(
      'Chapters',
      where: 'novel_id = ?',
      whereArgs: [novelId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // เพิ่มจำนวนวิวของบท (เรียกทุกครั้งที่เปิดอ่าน)
  static Future<void> incrementChapterViews(int chapterId) async {
    final db = await initDb();
    await db.rawUpdate(
      '''
    UPDATE Chapters
    SET number_of_views = number_of_views + 1
    WHERE chapter_id = ?
  ''',
      [chapterId],
    );
  }

  // เพิ่มจำนวนไลค์ของบท (เมื่อผู้ใช้กดถูกใจ)
  static Future<void> incrementChapterLikes(int chapterId) async {
    final db = await initDb();
    await db.rawUpdate(
      '''
    UPDATE Chapters
    SET likes = likes + 1
    WHERE chapter_id = ?
  ''',
      [chapterId],
    );
  }

  // ในไฟล์ db_helper.dart (ตัวอย่างฟังก์ชันที่ควรมี)

  static Future<List<Map<String, dynamic>>> getEpisodesByNovelId(
    int novelId,
  ) async {
    final db = await database();
    // 💡 ดึงคอลัมน์ที่สำคัญทั้งหมด รวมถึง is_published
    return await db.query(
      'Chapters', // หรือชื่อตารางที่เก็บตอนของคุณ
      columns: ['chapter_id', 'chapter_number', 'title', 'is_published'],
      where: 'novel_id = ?',
      whereArgs: [novelId],
      orderBy: 'chapter_number ASC',
    );
  }

  // ลบไลค์ (ถ้าผู้ใช้กดยกเลิก)
  static Future<void> decrementChapterLikes(int chapterId) async {
    final db = await initDb();
    await db.rawUpdate(
      '''
    UPDATE Chapters
    SET likes = CASE WHEN likes > 0 THEN likes - 1 ELSE 0 END
    WHERE chapter_id = ?
  ''',
      [chapterId],
    );
  }

  // ดึงสถิติของบท (จำนวนวิวและไลค์)
  static Future<Map<String, dynamic>?> getChapterStats(int chapterId) async {
    final db = await initDb();
    final result = await db.query(
      'Chapters',
      columns: ['number_of_views', 'likes'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> incrementNovelViews(int novelId) async {
    final db = await initDb();
    await db.rawUpdate(
      '''
    UPDATE Novels
    SET number_of_views = number_of_views + 1
    WHERE novel_id = ?
  ''',
      [novelId],
    );
  }

  // ✅ ตรวจว่า user เคยกดไลค์บทนี้แล้วไหม
  static Future<bool> hasUserLikedChapter(int userId, int chapterId) async {
    final db = await initDb();
    final res = await db.query(
      'ChapterLikes',
      where: 'user_id = ? AND chapter_id = ?',
      whereArgs: [userId, chapterId],
    );
    return res.isNotEmpty;
  }

  // ✅ ให้ user กดไลค์ได้ครั้งเดียว
  static Future<void> likeChapterOnce(int userId, int chapterId) async {
    final db = await initDb();
    final alreadyLiked = await hasUserLikedChapter(userId, chapterId);
    if (!alreadyLiked) {
      await db.insert('ChapterLikes', {
        'user_id': userId,
        'chapter_id': chapterId,
      });
      await db.rawUpdate(
        '''
      UPDATE Chapters
      SET likes = likes + 1
      WHERE chapter_id = ?
    ''',
        [chapterId],
      );
    }
  }

  // ---------------------- LIKE / VIEW SYSTEM ----------------------

  /// ✅ ตั้งสถานะการกดไลค์ของผู้ใช้ (like = true / unlike = false)
  static Future<void> setUserLikeStatus(
    int userId,
    int chapterId,
    bool isLiked,
  ) async {
    final db = await initDb();

    // ตรวจว่ามีอยู่ใน ChapterLikes แล้วไหม
    final exists = await db.query(
      'ChapterLikes',
      where: 'user_id = ? AND chapter_id = ?',
      whereArgs: [userId, chapterId],
    );

    if (isLiked) {
      // ถ้ายังไม่เคยไลค์ → เพิ่ม record + เพิ่มจำนวน like
      if (exists.isEmpty) {
        await db.insert('ChapterLikes', {
          'user_id': userId,
          'chapter_id': chapterId,
        });
        await db.rawUpdate(
          '''
          UPDATE Chapters
          SET likes = likes + 1
          WHERE chapter_id = ?
          ''',
          [chapterId],
        );
      }
    } else {
      // ถ้าเคยไลค์ → ลบ record และลดจำนวน like ลง
      if (exists.isNotEmpty) {
        await db.delete(
          'ChapterLikes',
          where: 'user_id = ? AND chapter_id = ?',
          whereArgs: [userId, chapterId],
        );
        await db.rawUpdate(
          '''
          UPDATE Chapters
          SET likes = CASE WHEN likes > 0 THEN likes - 1 ELSE 0 END
          WHERE chapter_id = ?
          ''',
          [chapterId],
        );
      }
    }
  }

  /// ✅ ลบสถานะ Like ของผู้ใช้ (ใช้ตอน user กดยกเลิก)
  static Future<void> removeUserLike(int userId, int chapterId) async {
    final db = await initDb();
    await db.delete(
      'ChapterLikes',
      where: 'user_id = ? AND chapter_id = ?',
      whereArgs: [userId, chapterId],
    );

    // ลดจำนวน like ใน chapter ด้วย
    await db.rawUpdate(
      '''
      UPDATE Chapters
      SET likes = CASE WHEN likes > 0 THEN likes - 1 ELSE 0 END
      WHERE chapter_id = ?
      ''',
      [chapterId],
    );
  }

  /// ✅ ตรวจว่า user คนนี้เคยกดไลค์ chapter นี้หรือยัง
  static Future<bool> getUserLikeStatus(int? userId, int chapterId) async {
    final db = await initDb();
    final res = await db.query(
      'ChapterLikes',
      where: 'user_id = ? AND chapter_id = ?',
      whereArgs: [userId, chapterId],
    );
    return res.isNotEmpty;
  }

  /// ✅ ดึงจำนวนวิวของบท
  static Future<int> getChapterViews(int? chapterId) async {
    final db = await initDb();
    final result = await db.query(
      'Chapters',
      columns: ['number_of_views'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
    if (result.isNotEmpty) {
      return result.first['number_of_views'] as int;
    }
    return 0;
  }

  /// ✅ ดึงจำนวนไลค์ของบท
  static Future<int> getChapterLikes(int? chapterId) async {
    final db = await initDb();
    final result = await db.query(
      'Chapters',
      columns: ['likes'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
    if (result.isNotEmpty) {
      return result.first['likes'] as int;
    }
    return 0;
  }
  // =============================================================
  // 💬 COMMENTS SECTION
  // =============================================================

  // ✅ เพิ่มคอมเมนต์ใหม่
  static Future<int> insertComment(
    int userId,
    int chapterId,
    String content,
  ) async {
    final db = await initDb();
    return await db.insert('Comments', {
      'user_id': userId,
      'chapter_id': chapterId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ✅ ดึงคอมเมนต์ทั้งหมดของบท (เฉพาะคอมเมนต์หลัก)
  static Future<List<Map<String, dynamic>>> getCommentsByChapter(
    int chapterId,
  ) async {
    final db = await DBHelper.database();

    return await db.rawQuery(
      '''
    SELECT c.comment_id, c.user_id, c.chapter_id, c.parent_id, c.content, 
           c.created_at, u.username, c.is_deleted
    FROM Comments c
    LEFT JOIN Users u ON c.user_id = u.user_id
    WHERE c.chapter_id = ? 
      AND c.is_deleted = 0
    ORDER BY c.created_at ASC
  ''',
      [chapterId],
    );
  }

  // ✅ ลบคอมเมนต์ (soft delete)
  static Future<int> deleteComment(int commentId) async {
    final db = await initDb();
    return await db.update(
      'Comments',
      {'is_deleted': 1},
      where: 'comment_id = ?',
      whereArgs: [commentId],
    );
  }

  // ✅ แก้ไขคอมเมนต์
  static Future<int> updateComment(int commentId, String newContent) async {
    final db = await initDb();
    return await db.update(
      'Comments',
      {'content': newContent, 'created_at': DateTime.now().toIso8601String()},
      where: 'comment_id = ?',
      whereArgs: [commentId],
    );
  }

  // =============================================================
  // 👍 LIKE SYSTEM (ผู้ใช้ like/dislike ได้ครั้งเดียว)
  // =============================================================

  static Future<void> createLikesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS CommentLikes (
      like_id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      comment_id INTEGER,
      is_liked INTEGER,
      FOREIGN KEY(user_id) REFERENCES Users(user_id),
      FOREIGN KEY(comment_id) REFERENCES Comments(comment_id)
    )
  ''');
  }

  // ✅ getCommentLikesCount
  static Future<int> getCommentLikesCount(int commentId) async {
    final db = await initDb();
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM CommentLikes WHERE comment_id = ? AND is_liked = 1',
      [commentId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // 🩵 กดไลก์คอมเมนต์
  static Future<void> addCommentLike(int userId, int commentId) async {
    final db = await initDb();
    await db.insert(
      'CommentLikes',
      {
        'user_id': userId,
        'comment_id': commentId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // ป้องกันไลก์ซ้ำ
    );
  }

  // 💔 ยกเลิกไลก์คอมเมนต์
  static Future<void> removeCommentLike(int userId, int commentId) async {
    final db = await initDb();
    await db.delete(
      'CommentLikes',
      where: 'user_id = ? AND comment_id = ?',
      whereArgs: [userId, commentId],
    );
  }

  // 🔢 นับจำนวนไลก์ของคอมเมนต์
  static Future<int> getCommentLikeCount(int commentId) async {
    final db = await initDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM CommentLikes WHERE comment_id = ?',
      [commentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 🧠 ตรวจสอบว่า user คนนี้เคยไลก์คอมเมนต์นี้หรือไม่
  static Future<bool> getUserLikedCommentStatus(
    int userId,
    int commentId,
  ) async {
    final db = await initDb();
    final result = await db.query(
      'CommentLikes',
      where: 'user_id = ? AND comment_id = ?',
      whereArgs: [userId, commentId],
    );
    return result.isNotEmpty;
  }

  // ✅ ตรวจสอบว่า user นี้เคยไลก์คอมเมนต์นี้หรือยัง
  static Future<bool> isCommentLikedByUser(int userId, int commentId) async {
    final db = await initDb();
    final result = await db.query(
      'CommentLikes',
      where: 'user_id = ? AND comment_id = ?',
      whereArgs: [userId, commentId],
    );
    return result.isNotEmpty;
  }

  // ✅ เพิ่มการตอบกลับคอมเมนต์
  static Future<int> insertCommentReply(
    int userId,
    int chapterId,
    int parentId,
    String content,
  ) async {
    final db = await DBHelper.database();
    return await db.insert('Comments', {
      'user_id': userId,
      'chapter_id': chapterId,
      'parent_id': parentId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ดึงนิยายมาแรง: เรียงตาม Likes (หรือ Views)
  static Future<List<Novel>> getHotNovels() async {
    final db = await database();
    final List<Map<String, dynamic>> maps = await db.query(
      'Novels',
      where: 'is_published = ? AND is_banned = ?',
      whereArgs: [1, 0],
      limit: 7,
      orderBy: 'likes DESC, number_of_views DESC', // เน้น Like ก่อน View
    );

    // แปลง List<Map> เป็น List<Novel>
    return List.generate(maps.length, (i) {
      return Novel.fromMap(maps[i]);
    });
  }

  // ดึงนิยายอัพเดตล่าสุด: เรียงตามเวลาที่ถูกอัพเดต
  static Future<List<Novel>> getLatestNovels() async {
    final db = await database();
    final List<Map<String, dynamic>> maps = await db.query(
      'Novels',
      where: 'is_published = ? AND is_banned = ?',
      whereArgs: [1, 0],
      limit: 7,
      // ใช้ last_updated สำหรับการอัพเดตบทใหม่
      orderBy: 'last_updated DESC',
    );

    return List.generate(maps.length, (i) {
      return Novel.fromMap(maps[i]);
    });
  }

  // ดึงนิยายแนะนำ: เรียงตาม Created_at หรือสุ่ม
  // TODO : ใส้ AI แนะนำเพิ่มเติม
  static Future<List<Novel>> getRecommendedNovels() async {
    final db = await database();
    final List<Map<String, dynamic>> maps = await db.query(
      'Novels',
      where: 'is_published = ? AND is_banned = ?',
      whereArgs: [1, 0],
      limit: 7,
      // ใช้ created_at เป็นตัวเลือกในการแนะนำ
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Novel.fromMap(maps[i]);
    });
  }

  // -----------------------------------------------------------------
  // 1. ✅ ฟังก์ชันสำหรับตรวจสอบสถานะ Bookmark
  //    (ตรวจสอบว่ามีรายการที่ user_id, novel_id ตรงกัน และ is_active = true)
  // -----------------------------------------------------------------
  static Future<bool> isNovelBookmarked(int novelId, int userId) async {
    final db = await database();

    // ค้นหาแถวที่ถูก 'Active' โดย user_id และ novel_id
    final List<Map<String, dynamic>> maps = await db.query(
      'Favorites',
      where: 'novel_id = ? AND user_id = ? AND is_active = 1',
      whereArgs: [novelId, userId],
      limit: 1,
    );

    // ถ้าพบอย่างน้อย 1 แถวที่ active แสดงว่ามีการบันทึกไว้แล้ว
    return maps.isNotEmpty;
  }

  // -----------------------------------------------------------------
  // 2. ✅ ฟังก์ชันสำหรับเพิ่ม/เปิดใช้งานรายการ Bookmark
  // -----------------------------------------------------------------
  static Future<void> addBookmark(int novelId, int userId) async {
    final db = await database();

    // 💡 ขั้นตอนที่ 1: ตรวจสอบว่าเคยมีรายการนี้อยู่แล้วหรือไม่ (ไม่ว่าจะ active หรือไม่)
    final existingFavorites = await db.query(
      'Favorites',
      where: 'novel_id = ? AND user_id = ?',
      whereArgs: [novelId, userId],
      limit: 1,
    );

    if (existingFavorites.isNotEmpty) {
      // 💡 ขั้นตอนที่ 2: ถ้าเคยมีอยู่แล้ว ให้อัปเดต is_active เป็น true
      await db.update(
        'Favorites',
        {
          'is_active': 1, // 1 คือ true
          'created_at': DateTime.now()
              .toIso8601String(), // อัปเดต timestamp ใหม่
        },
        where: 'novel_id = ? AND user_id = ?',
        whereArgs: [novelId, userId],
      );
    } else {
      // 💡 ขั้นตอนที่ 3: ถ้าไม่เคยมีเลย ให้เพิ่มแถวใหม่
      await db.insert('Favorites', {
        'novel_id': novelId,
        'user_id': userId,
        'is_active': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // -----------------------------------------------------------------
  // 3. ✅ ฟังก์ชันสำหรับลบ/ปิดใช้งานรายการ Bookmark (Soft Delete)
  // -----------------------------------------------------------------
  static Future<void> removeBookmark(int novelId, int userId) async {
    final db = await database();

    // อัปเดต is_active ให้เป็น false (0) แทนการลบแถว
    await db.update(
      'Favorites',
      {'is_active': 0}, // 0 คือ false
      where: 'novel_id = ? AND user_id = ?',
      whereArgs: [novelId, userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getReports() async {
    final db = await initDb();
    return await db.rawQuery('''
    SELECT r.report_id, r.remark, r.created_at, r.status,
           u.username,
           c.chapter_title
    FROM Reports r
    LEFT JOIN Users u ON r.user_id = u.user_id
    LEFT JOIN Chapters c ON r.chapter_id = c.chapter_id
    ORDER BY r.created_at DESC
  ''');
  }

  static Future<void> insertReport(Map<String, dynamic> data) async {
    final db = await initDb();
    await db.insert('Reports', data);
  }

  static Future<List<Map<String, dynamic>>> getPendingReports() async {
    final db = await initDb();
    return await db.query(
      'Reports',
      where: "status = 'pending'",
      orderBy: "created_at DESC",
    );
  }

  static Future<int> getPendingReportCount() async {
    final db = await initDb();

    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM Reports WHERE status = 'pending'",
    );

    if (result.isNotEmpty && result.first['count'] != null) {
      return result.first['count'] as int;
    }

    return 0;
  }

  static Future<void> updateReportStatus(int reportId, String status) async {
    final db = await initDb();
    await db.update(
      'Reports',
      {'status': status},
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
  }

  static Future<void> banNovel(int novelId) async {
    final db = await initDb();
    await db.update(
      "Novels",
      {"is_banned": 1},
      where: "novel_id=?",
      whereArgs: [novelId],
    );
  }

  // ⭐ เมธอดสำหรับบันทึกการรายงานบท (Chapter)
  static Future<bool> reportChapter({
    required int reportingUserId, // ID ของผู้ใช้ที่รายงาน
    required int chapterId, // ID ของบท (Chapter) ที่ถูกรายงาน
    required String reason, // เหตุผล/รายละเอียดที่ผู้ใช้กรอก
  }) async {
    try {
      final db = await database();

      final reportData = {
        'user_id': reportingUserId,
        'chapter_id': chapterId,
        'remark': reason, // ใช้ 'remark' สำหรับบันทึกเหตุผล
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending', // สถานะเริ่มต้น
      };

      // ⭐ Insert ข้อมูลลงในตาราง Reports
      await db.insert('Reports', reportData);

      print(
        'DBHelper: รายงาน Chapter ID $chapterId สำเร็จโดย User ID $reportingUserId',
      );

      return true; // บันทึกสำเร็จ
    } catch (e) {
      print('DBHelper Error: ไม่สามารถบันทึกรายงาน Chapter ได้: $e');
      return false; // บันทึกล้มเหลว
    }
  }

  // ⭐ เมธอดเพื่อดึง novel_id จาก chapter_id
  static Future<int?> getNovelIdByChapterId(int chapterId) async {
    final db =
        await database(); // สมมติว่า 'database' คือ Getter ของ SQLiteDatabase

    // โค้ด SQL: SELECT novel_id FROM Chapters WHERE chapter_id = ?
    final result = await db.query(
      'Chapters',
      columns: ['novel_id'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );

    if (result.isNotEmpty) {
      // คืนค่า novel_id
      return result.first['novel_id'] as int;
    }
    return null; // ไม่พบบท
  }

  // ⭐ เมธอดสำหรับ Admin: ดำเนินการเตือนผู้เขียนจาก Chapter ID
  static Future<bool> reportWarnChapter(int chapterId) async {
    final novelId = await getNovelIdByChapterId(chapterId);

    if (novelId != null) {
      await warnNovel(novelId);
      print('DBHelper: เตือนผู้เขียนนิยาย ID $novelId สำเร็จ');
      return true;
    }
    return false;
  }

  // ⭐ เมธอดสำหรับ Admin: ดำเนินการแบนนิยายจาก Chapter ID
  static Future<bool> reportBanChapter(int chapterId) async {
    final novelId = await getNovelIdByChapterId(chapterId);

    if (novelId != null) {
      // 1. ดำเนินการแบนนิยายทั้งเรื่อง (isBanned = true)
      // *เมธอดนี้ต้องมี logic การ UPDATE Novels SET isBanned = 1*
      await updateNovelBanStatus(novelId, true);

      // 2. (ทางเลือก) คุณอาจอัปเดตสถานะบทที่ถูกรายงาน
      // await updateChapterStatus(chapterId, 'banned');

      print('DBHelper: แบนนิยาย ID $novelId สำเร็จ');
      return true;
    }
    return false;
  }

  // ⭐ เมธอดสำหรับดึงจำนวนคำเตือนของนิยายจากคอลัมน์ number_of_warnings
  static Future<int> getNovelWarningCount(int novelId) async {
    final db = await database();

    // ดึงค่า number_of_warnings จากตาราง Novels
    final result = await db.query(
      'Novels',
      columns: ['number_of_warnings'],
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );

    if (result.isNotEmpty) {
      // คืนค่าจำนวนคำเตือน
      return result.first['number_of_warnings'] as int;
    }
    return 0; // คืนค่า 0 หากไม่พบนิยาย
  }

  // ⭐ เมธอดสำหรับดึงการแจ้งเตือนของผู้ใช้
  static Future<List<Map<String, dynamic>>> getNotificationsForUser(
    int userId,
  ) async {
    final db = await database();
    // ⭐ ใช้ rawQuery เพื่อ JOIN ตาราง Notifications กับ Novels
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT 
        N.*, 
        COALESCE(NV.title, 'นิยายถูกลบแล้ว') AS novel_title
    FROM Notifications AS N
    LEFT JOIN Novels AS NV ON N.novel_id = NV.novel_id
    WHERE N.user_id = ? 
    ORDER BY N.created_at DESC
  ''',
      [userId],
    );
    return maps;
  }

  // ⭐ เมธอดใหม่: ดึงจำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
  static Future<int> getUnreadNotificationCount(int userId) async {
    final db = await database();

    final List<Map<String, dynamic>> result = await db.query(
      'Notifications',
      columns: ['COUNT(*) AS unread_count'],
      where:
          'user_id = ? AND is_read = 0', // is_read = 0 คือยังไม่ได้อ่าน (False)
      whereArgs: [userId],
    );

    return result.isNotEmpty ? (result.first['unread_count'] as int) : 0;
  }

  static Future<void> markAllNotificationsAsRead(int userId) async {
    final db = await database();
    await db.update(
      'Notifications',
      {'is_read': 1}, // 1 คือ true (อ่านแล้ว)
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
  }

  static Future<List<Map<String, dynamic>>>
  getPendingReportsWithDetails() async {
    final db = await database();

    // SQL Query ที่ใช้ JOIN ตาราง Reports, Users, Chapters, และ Novels
    // เพื่อดึงชื่อผู้ใช้ (username), ชื่อบท (chapter_title), และชื่อนิยาย (novel_title)
    const sql = '''
      SELECT
          R.report_id, 
          R.chapter_id, 
          R.user_id, 
          R.remark, 
          R.created_at,
          U.name AS username,
          C.novel_id,
          C.title AS chapter_title,
          N.title AS novel_title,
          N.writer_name
      FROM
          Reports R
      INNER JOIN 
          Users U ON R.user_id = U.user_id
      INNER JOIN 
          Chapters C ON R.chapter_id = C.chapter_id
      INNER JOIN 
          Novels N ON C.novel_id = N.novel_id
      WHERE
          R.status = 'pending'
      ORDER BY 
          R.created_at DESC;
    ''';

    try {
      final List<Map<String, dynamic>> result = await db.rawQuery(sql);
      print('✅ Fetched ${result.length} pending reports with details.');
      return result;
    } catch (e) {
      print('❌ Error fetching reports with details: $e');
      return []; // คืนค่ารายการว่างถ้าเกิดข้อผิดพลาด
    }
  }

  // เมธอดใหม่: สำหรับเปลี่ยนสถานะการเผยแพร่ของ Chapter
  static Future<void> updateChapterPublishStatus(
    int chapterId,
    bool isPublished,
  ) async {
    final db = await database();
    await db.update(
      'Chapters',
      {'is_published': isPublished ? 1 : 0},
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  static Future<void> createNotification(
    int userId, // ID ผู้เขียน (User ID)
    int novelId, // ID นิยาย
    String title,
    String body,
  ) async {
    final db = await database();
    await db.insert('Notifications', {
      'user_id': userId, // บันทึก User ID ของผู้เขียนที่ต้องรับแจ้งเตือน
      'novel_id': novelId,
      'title': title,
      'body': body,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': 0,
    });
  }

  // **************** เมธอดที่แก้ไข: updateNovelBanStatus ****************
  static Future<void> updateNovelBanStatus(
    int novelId,
    bool isBanned, {
    String? remark,
  }) async {
    final db = await database();

    // 1. อัปเดตสถานะการแบนในตาราง Novels
    await db.update(
      'Novels',
      {'is_banned': isBanned ? 1 : 0},
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );

    if (isBanned && remark != null) {
      // 2. อัปเดตสถานะรายงาน (โค้ดเดิมของคุณ)
      await db.update(
        'Reports',
        {
          'status': 'banned',
          'punishment_detail': remark,
          'punishment_time': DateTime.now().toIso8601String(),
        },
        where:
            'chapter_id IN (SELECT chapter_id FROM Chapters WHERE novel_id = ?) AND status = ?',
        whereArgs: [novelId, 'pending'],
      );

      // **************** 3. สร้าง Notification สำหรับการแบน ****************
      // ดึงข้อมูลนิยายเพื่อหา user_id (ผู้เขียน) และ title
      final novelResult = await db.query(
        'Novels',
        // *** แก้ไข: เปลี่ยน 'writer_id' เป็น 'user_id' ***
        columns: ['user_id', 'title'],
        where: 'novel_id = ?',
        whereArgs: [novelId],
      );

      if (novelResult.isNotEmpty) {
        final writerUserId =
            novelResult.first['user_id'] as int; // ใช้ user_id แทน writer_id
        final novelTitle = novelResult.first['title'] as String;

        final notificationTitle = '🚨 นิยายของคุณถูกแบน: $novelTitle';
        final notificationBody =
            'เหตุผล: $remark. (นิยายถูกซ่อนจากสาธารณะแล้ว)';

        await createNotification(
          writerUserId,
          novelId,
          notificationTitle,
          notificationBody,
        );
      }
      // *******************************************************************
    }
  }

  // **************** เมธอดที่แก้ไข: warnNovel ****************
  static Future<void> warnNovel(int novelId, {String? remark}) async {
    final db = await database();

    // 1. ดึงข้อมูลนิยายเพื่อหา user_id, title, และ number_of_warnings ปัจจุบัน
    final novelResult = await db.query(
      'Novels',
      // *** แก้ไข: เปลี่ยน 'writer_id' เป็น 'user_id' ***
      columns: ['user_id', 'title', 'number_of_warnings'],
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );

    if (novelResult.isNotEmpty) {
      final novel = novelResult.first;
      final writerUserId = novel['user_id'] as int; // ใช้ user_id แทน writer_id
      final novelTitle = novel['title'] as String;
      final currentWarnings = (novel['number_of_warnings'] as int?) ?? 0;

      // 2. อัปเดตจำนวนคำเตือน
      await db.update(
        'Novels',
        {'number_of_warnings': currentWarnings + 1},
        where: 'novel_id = ?',
        whereArgs: [novelId],
      );

      // 3. สร้าง Notification
      final notificationTitle = '⚠️ คำเตือนเกี่ยวกับนิยาย: $novelTitle';
      final notificationBody =
          'รายละเอียด: ${remark ?? "ไม่มีเหตุผลระบุ"}. โปรดแก้ไขเพื่อให้เป็นไปตามกฎ';

      await createNotification(
        writerUserId,
        novelId,
        notificationTitle,
        notificationBody,
      );
    }
  }

  // ดึงข้อมูลผู้ใช้ + จำนวนผลงาน
  static Future<Map<String, dynamic>?> getUserDetail(int userId) async {
    final db = await initDb();
    final result = await db.query(
      'Users',
      where: "user_id = ?",
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> updateUserStatus(
    int userId,
    String newStatus, {
    // ⭐ เพิ่มพารามิเตอร์ remark (เป็นทางเลือก)
    String? remark,
  }) async {
    final db = await database();

    await db.update(
      'Users',
      {'status': newStatus},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // ⭐ ส่วนเสริม: หากต้องการบันทึกการกระทำของ Admin ลงใน log/Notification
    if (remark != null && newStatus == 'banned') {
      // อาจจะต้องสร้างฟังก์ชัน createAdminLog หรือ createNotification เพื่อบันทึกว่า
      // ผู้ใช้ถูกแบนด้วยเหตุผลอะไร
      // เช่น: await createNotification(userId, 0, 'บัญชีถูกระงับ', 'เหตุผล: $remark');
    }
  }

  static Future<void> updateWriterStatus(int userId, bool isWriter) async {
    final db = await database();
    await db.update(
      "Users",
      {"is_writer": isWriter ? 1 : 0},
      where: "user_id = ?",
      whereArgs: [userId],
    );
  }

  static Future<void> resetUserPassword(int userId, String newPass) async {
    final db = await database();
    await db.update(
      "Users",
      {"password": newPass},
      where: "user_id = ?",
      whereArgs: [userId],
    );
  }

  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) return null;

    // ดึงข้อมูลผู้ใช้จากฐานข้อมูลภายในเครื่อง
    final db = await database();
    final List<Map<String, dynamic>> results = await db.query(
      'Users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      return results.first; // ข้อมูลผู้ใช้คนนี้
    }
    return null;
  }

  static Future<List<Novel>> getRecommendedNovelsByAI(String aiGenres) async {
    final db = await database();

    // แยก string เช่น "ดราม่า / ชีวิตจริง / สืบสวน"
    final genres = aiGenres
        .split(RegExp(r'[,/|]')) // แยกด้วย , / หรือ |
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (genres.isEmpty) return [];

    // สร้าง placeholder (?, ?, ?)
    final placeholders = List.filled(genres.length, '?').join(', ');

    final List<Map<String, dynamic>> novelMaps = await db.rawQuery(
      '''
    SELECT n.*, c1.category_name AS mainCategoryName, c2.category_name AS secondaryCategoryName
    FROM Novels n
    LEFT JOIN Categories c1 ON n.category_id = c1.category_id
    LEFT JOIN Categories c2 ON n.secondary_category_id = c2.category_id
    WHERE (c1.category_name IN ($placeholders) OR c2.category_name IN ($placeholders))
      AND n.is_published = 1
      AND n.is_banned = 0
    ORDER BY n.number_of_views DESC
    LIMIT 20
  ''',
      [...genres, ...genres],
    );

    print("✅ AI Recommended Novels found: ${novelMaps.length}");
    return novelMaps.map((map) => Novel.fromMap(map)).toList();
  }
}
