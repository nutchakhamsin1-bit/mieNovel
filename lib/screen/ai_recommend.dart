import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mie_project/services/db_helper.dart';
import 'home.dart';

class PersonalityQuizPage extends StatefulWidget {
  const PersonalityQuizPage({super.key});

  @override
  _PersonalityQuizPageState createState() => _PersonalityQuizPageState();
}

class _PersonalityQuizPageState extends State<PersonalityQuizPage> {
  final List<Map<String, dynamic>> questions = [
    {
      'id': 1,
      'prompt': 'เลือกรูปที่คุณรู้สึกว่า "ชอบที่สุด"',
      'options': [
        {
          'id': 'a',
          'label': 'ภูเขาสูงที่ปกคลุมด้วยหิมะ',
          'trait': 'openness',
          'image': 'assets/images/mountain1.png'
        },
        {
          'id': 'b',
          'label': 'โต๊ะทำงานเป็นระเบียบ',
          'trait': 'conscientiousness',
          'image': 'assets/images/desk.jpg'
        },
        {
          'id': 'c',
          'label': 'กลุ่มเพื่อนกำลังหัวเราะ',
          'trait': 'extraversion',
          'image': 'assets/images/friends.jpg'
        },
      ],
    },
    {
      'id': 2,
      'prompt': 'ถ้าให้เลือกสถานที่พักผ่อน คุณจะไปที่ไหน?',
      'options': [
        {'id': 'a', 'label': 'เมืองเก่าเงียบสงบ', 'trait': 'agreeableness', 'image': 'assets/images/oldtown.jpg'},
        {'id': 'b', 'label': 'ป่าเขาธรรมชาติ', 'trait': 'openness', 'image': 'assets/images/forest.jpg'},
        {'id': 'c', 'label': 'คาเฟ่ใจกลางเมือง', 'trait': 'extraversion', 'image': 'assets/images/cafe.jpg'},
      ],
    },
    {
      'id': 3,
      'prompt': 'ภาพไหนทำให้คุณรู้สึกสบายใจที่สุด?',
      'options': [
        {'id': 'a', 'label': 'ห้องสมุดเงียบๆ', 'trait': 'conscientiousness', 'image': 'assets/images/libary-.jpg'},
        {'id': 'b', 'label': 'ภาพวิวทะเลโล่งกว้าง', 'trait': 'emotional_stability', 'image': 'assets/images/sea.jpg'},
        {'id': 'c', 'label': 'บ้านสวนพร้อมเพื่อนฝูง', 'trait': 'agreeableness', 'image': 'assets/images/friendsgarden.jpg'},
      ],
    },
  ];

  final Map<String, String> traitToGenre = {
    'openness': 'แฟนตาซี / ไซไฟ / แนวทดลอง',
    'conscientiousness': 'ดราม่า / ชีวิตจริง / สืบสวน',
    'extraversion': 'รักโรแมนติก / วัยรุ่น / คอมเมดี้',
    'agreeableness': 'ครอบครัว / ดราม่าอบอุ่นหัวใจ',
    'emotional_stability': 'ระทึกขวัญ / ผจญภัย / ตื่นเต้น',
  };

  Map<int, String> answers = {};
  String? result;

  void _handleSelect(int questionId, String trait) {
    setState(() {
      answers[questionId] = trait;
    });
  }

  Future<void> _handleSubmit() async {
    final Map<String, int> traitCount = {};
    for (var trait in answers.values) {
      traitCount[trait] = (traitCount[trait] ?? 0) + 1;
    }

    String topTrait =
        traitCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    setState(() {
      result = traitToGenre[topTrait];
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      await DBHelper.updateUser(userId, {
        'ai_analysis_data': result!,
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI แนะนำแนวที่เหมาะกับคุณ: ${result!}'),
        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Widget _buildImageOptionButton(String label, String trait, int questionId, String imageUrl) {
    final isSelected = answers[questionId] == trait;
    return GestureDetector(
      onTap: () => _handleSelect(questionId, trait),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(imageUrl, fit: BoxFit.cover),
                    if (isSelected)
                      Container(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                        child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['prompt'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: question['options']
                .map<Widget>((opt) =>
                    _buildImageOptionButton(opt['label'], opt['trait'], question['id'], opt['image']))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 แนวนิยายที่คุณน่าจะชอบ:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            result!,
            style: TextStyle(fontSize: 16, color: Colors.green.shade800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ทายนิสัยจากภาพ & แนะนำนิยายที่เหมาะกับคุณ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...questions.map((q) => _buildQuestionCard(q)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: answers.length == questions.length ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF26A69A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ไปอ่านกันเลย',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            if (result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }
}
