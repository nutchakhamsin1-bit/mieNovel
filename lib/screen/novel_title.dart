import 'package:flutter/material.dart';
import 'package:mie_project/screen/manage_novel_writer.dart';
import 'package:mie_project/screen/show_chapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NovelTitleScreen extends StatefulWidget {
  const NovelTitleScreen({super.key});

  @override
  State<NovelTitleScreen> createState() => _NovelTitleScreenState();
}

class _NovelTitleScreenState extends State<NovelTitleScreen>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false; // Track the favorite state
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView( // Make the content scrollable
              child: Column(
                children: [
                  const SizedBox(height: 16), // Space below the AppBar
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Center content vertically
                        crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
                        children: [
                          const Text(
                            'mie novel', // Title of the novel
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('หมวดหมู่หลัก: Romance', style: TextStyle(fontSize: 16)),
                          const Text('หมวดหมู่รอง: Comedy', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text(
                            'สำหรับอายุ: 17+',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'วันที่เผยแพร่: 20 / 10 / 2023',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'คำแนะนำเรื่อง',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text( // Sample text for the story
                            'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n'
                            'หากคุณชอบนิยายที่มีการผสมผสานระหว่างแฟนตาซี\n'
                            'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n'
                             'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n'
                            'หากคุณชอบนิยายที่มีการผสมผสานระหว่างแฟนตาซี\n'
                            'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n'
                             'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n'
                            'หากคุณชอบนิยายที่มีการผสมผสานระหว่างแฟนตาซี\n'
                            'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n'
                             'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n'
                            'หากคุณชอบนิยายที่มีการผสมผสานระหว่างแฟนตาซี\n'
                            'นี่คือนิยายที่น่าสนใจมาก เรื่องราวเกี่ยวกับการผจญภัย\n'
                            'ตัวละครหลักต้องเผชิญกับอุปสรรคมากมาย ตัวละครหลัก\n'
                            'นิยายนี้เต็มไปด้วยการพัฒนาตัวละครที่ลึกซึ้งตัวละครที่ลึกซึ้ง\n',
                            style: TextStyle(fontSize: 14, color: Color.fromARGB(137, 49, 49, 49)),
                            textAlign: TextAlign.left,
                            softWrap: true, // Allow text to wrap automatically
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: () async{
                                Navigator.push(
                          context,
                          MaterialPageRoute(
                            // TODO: เปลี่ยนไปหน้า ManageNovelWriter
                            builder: (context) => const ManageNovelWriter(novelId: 1), // ส่ง novelId ที่ต้องการไป
                          ),
                        );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF26A69A),
                                foregroundColor: const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'อ่านเลย',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24), 
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Heart icon in the top-right corner
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isFavorite = !isFavorite; // Toggle favorite state
                  });
                  _animationController.forward(from: 0);

                  // Show a SnackBar when the icon is clicked
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'เพิ่มไปยังนิยายโปรดเรียบร้อยแล้ว' // Message when added to
                            : 'ลบออกจากนิยายโปรดเรียบร้อยแล้ว', // Message when removed from favorites
                      ),
                      duration: const Duration(seconds: 2), // Duration of the SnackBar
                    ),
                  );
                },
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border, // Change icon based on state
                      color: isFavorite
                          ? Colors.red
                          : Colors.black, // Change color based on state
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



                        //Text(
                        //yourStoryText, // แทนด้วยตัวแปรที่เก็บเนื้อหานิยายของผู้ใช้
                        // style: const TextStyle(
                        //  fontSize: 14,
                        // color: Colors.black54,
                        //),
                        //textAlign: TextAlign
                        //    .justify, // เพื่อให้