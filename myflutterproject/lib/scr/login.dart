import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/auth_service/Authservice.dart';
import 'package:myflutterproject/scr/register.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> login() async {
    const String apiUrl = 'http://10.0.2.2:8000/Smartwityouapp/Login/';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _usernameController.text,
          'password': _passwordController.text,
        }),
      );
      print(response.body);
      if (response.statusCode == 200) {
        // เก็บข้อมูลผู้ใช้ใน SharedPreferences
        final responseBody = json.decode(response.body);
        final accessToken = responseBody['access_token'];
        final refreshToken = responseBody['token'];
        final userid = responseBody['id'];

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user_email', _usernameController.text);
        prefs.setString('access_token', accessToken);
        prefs.setString('refresh_token', refreshToken);
        prefs.setString('userid', userid);

        await AuthService.saveLoginStatus(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบเเล้ว')),
        );
        
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
        
          await sendFcmTokenToServer(fcmToken);
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('รหัสผ่านหรืออีเมลไม่ถูกต้อง')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> sendFcmTokenToServer(String token) async {
    const String apiUrl = 'http://10.0.2.2:8000/Smartwityouapp/saveFCMtoken/';

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');
      String? accessToken = prefs.getString('access_token');

      if (userId != null) {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: json.encode({
            'user_id': userId,
            'fcm_token': token,
          }),
        );

        if (response.statusCode == 200) {
          print('FCM Token updated successfully');
        } else {
          print('Failed to update FCM Token');
        }
      }
    } catch (e) {
      print('Error updating FCM Token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 39, 38, 38),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 100),
            Center(
                child: Image.asset(
              'assets/images/icon.png', // พาธของไฟล์รูปภาพ
              height: 200, // ปรับขนาดความสูง
              width: 200, // ปรับขนาดความกว้าง
              fit: BoxFit.cover, // จัดการการแสดงผลของรูป
            )),
           
            Center(
              child: Text(
                'Smartwithyou',
                style: TextStyle(color: Colors.orange, fontSize: 20),
              ),
            ),
            const SizedBox(height: 30),
            _buildTextField("อีเมล", Icons.person, _usernameController, false),
            const SizedBox(height: 12),
            _buildTextField("รหัสผ่าน", Icons.lock, _passwordController, true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Login",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "ไม่มีบัญชีใช่ไหม?",
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Registerpage()),
                    );
                  },
                  child: const Text(
                    "ลงทะเบียน",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon,
      TextEditingController controller, bool obscureText) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white24,
        labelStyle: const TextStyle(color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}
