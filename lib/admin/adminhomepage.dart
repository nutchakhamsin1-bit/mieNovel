import 'package:flutter/material.dart';
import 'package:mie_project/admin/managemember.dart';
import 'package:mie_project/admin/managenovel.dart';
import 'package:mie_project/admin/reportpage.dart';
import 'package:mie_project/screen/splash_screen.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:mie_project/theme/app_theme.dart';
import 'package:mie_project/utils/app_logger.dart';
import 'package:mie_project/utils/session_manager.dart';

class Adminhomepage extends StatefulWidget {
  const Adminhomepage({super.key});

  @override
  // ⭐ 1. เพิ่ม with WidgetsBindingObserver
  State<Adminhomepage> createState() => _AdminhomepageState();
}

class _AdminhomepageState extends State<Adminhomepage>
    with WidgetsBindingObserver {
  int _pendingReportCount = 0;

  @override
  void initState() {
    super.initState();
    // เพิ่ม Observer ใน initState
    WidgetsBinding.instance.addObserver(this);
    _checkPendingReports();
  }

  @override
  void dispose() {
    // ลบ Observer ออกใน dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 2. ดักจับเมื่อแอปกลับมาทำงานจากพื้นหลัง
    if (state == AppLifecycleState.resumed) {
      _checkPendingReports();
    }
  }

  Future<void> _checkPendingReports() async {
    try {
      final int count = await DBHelper.getPendingReportCount();
      if (mounted) {
        setState(() {
          _pendingReportCount = count;
        });
      }
    } catch (e, st) {
      AppLogger.error('checkPendingReports failed', e, st);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await SessionManager.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ผู้ดูแลระบบ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkPendingReports,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ยินดีต้อนรับ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Text(
                          'แผงควบคุมผู้ดูแล',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_pendingReportCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'คำร้องค้าง $_pendingReportCount รายการ',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AdminMenuCard(
              icon: Icons.menu_book,
              title: 'จัดการนิยาย',
              subtitle: 'รายการนิยายทั้งหมด, แบน, แก้ไข',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Managenovel()),
              ).then((_) => _checkPendingReports()),
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminMenuCard(
              icon: Icons.people_alt,
              title: 'จัดการสมาชิก',
              subtitle: 'ผู้ใช้, สิทธิ์การเป็นนักเขียน',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Managemember()),
              ).then((_) => _checkPendingReports()),
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminMenuCard(
              icon: Icons.report_problem_outlined,
              title: 'จัดการคำร้อง',
              subtitle: 'รายงานเนื้อหาที่รอตรวจสอบ',
              badge: _pendingReportCount,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminReportManagePage()),
              ).then((_) => _checkPendingReports()),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
