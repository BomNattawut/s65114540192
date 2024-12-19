import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:myflutterproject/scr/createparty.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:myflutterproject/scr/createparty.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentindex = 0; // ตัวแปรเก็บสถานะของ BottomNavigationBar

  // ฟังก์ชัน logout
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    String? accessToken = prefs.getString('access_token');
  
    // รีเฟรช access token หากหมดอายุ
    if (accessToken == null || accessToken.isEmpty) {
      accessToken = await refreshAccessToken(refreshToken!);
      if (accessToken != null) {
        await prefs.setString('access_token', accessToken);
      } else {
        print('Unable to refresh token');
        return;
      }
    }
  
    // ส่งคำขอ Logout ไปยังเซิร์ฟเวอร์
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/logout/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'refresh_token': refreshToken}),
    );
  
    if (response.statusCode == 200) {
      // ลบ Token ออกจาก SharedPreferences
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      print('Logout successful');
      // นำทางไปยังหน้าล็อกอิน
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print('Logout failed: ${response.statusCode} - ${response.body}');
    }
  }

  // ฟังก์ชัน refresh token
  Future<String?> refreshAccessToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );
  
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['access']; // ส่งคืน access token ใหม่
    } else {
      print('Failed to refresh token: ${response.body}');
      return null;
    }
  }

  // ฟังก์ชันเมื่อผู้ใช้เลือก BottomNavigationBar
  void _onBottomNavTap(int index) {
    setState(() {
      _currentindex = index;
    });

    if (_currentindex == 1) {
      // ถ้าผู้ใช้เลือกแท็บ "Create Party"
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MakePartyPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Center(
          child: Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: Icon(Icons.menu, color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await logout(context); // เรียกใช้ฟังก์ชัน logout
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[800],
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentindex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create Party'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Join Party'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
    );
  }
}
