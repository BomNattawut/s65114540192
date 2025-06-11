import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> saveLoginStatus(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_logged_in", isLoggedIn);
  }

  static Future<bool> getLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("is_logged_in") ?? false; // ค่าเริ่มต้นเป็น false
  }
}