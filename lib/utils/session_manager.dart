import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _userIdKey = 'user_id';
  static const String _adminIdKey = 'admin_id';
  static const String _themeModeKey = 'theme_mode';
  static const String _onboardingDoneKey = 'onboarding_done';

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.remove(_adminIdKey);
  }

  static Future<void> saveAdminId(int adminId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_adminIdKey, adminId);
    await prefs.remove(_userIdKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<int?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_adminIdKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_adminIdKey);
  }

  static Future<bool> isUserLoggedIn() async {
    return (await getUserId()) != null;
  }

  static Future<bool> isAdminLoggedIn() async {
    return (await getAdminId()) != null;
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'light';
  }

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }
}
