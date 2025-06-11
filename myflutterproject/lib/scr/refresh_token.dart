import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getValidAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');
  final refreshToken = prefs.getString('refresh_token');

  if (accessToken == null || refreshToken == null) {
    return null; // ❌ ไม่มี Token ต้องล็อกอินใหม่
  }

  final tokenParts = accessToken.split('.');
  if (tokenParts.length != 3) {
    return null; // ❌ Token ผิดรูปแบบ
  }

  // ✅ Decode Payload (Base64)
  final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))));

  final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
  final now = DateTime.now();

  if (now.isAfter(expiry)) {
    print('🔴 access_token หมดอายุ, กำลังขอใหม่...');
    return await refreshAccessToken(refreshToken);
  }

  return accessToken; // ✅ Token ยังใช้ได้
}

Future<String?> refreshAccessToken(String? refreshToken) async {
  final response = await http.post(
    Uri.parse('http://10.0.2.2:8000/http://10.0.2.2:8000/Smartwityouapp/refresh_token/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refresh': refreshToken}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token']);
    await prefs.setString('refresh_token', data['refresh_token']);
    return data['access_token']; // ✅ รีเฟรชสำเร็จ
  } else {
    return null; // ❌ รีเฟรชไม่สำเร็จ
  }
}
