
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/login.dart'; // นำเข้า Login Page

class VerifyEmailPage extends StatefulWidget {
  final String userId;

  const VerifyEmailPage({required this.userId, super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isLoading = false;
  bool isVerified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoUpdate(); // เริ่มอัปเดตอัตโนมัติ
  }

  void _startAutoUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      verify();
    });
  }

  Future<void> verify() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/check_verify/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': widget.userId}),
    );

    if (response.statusCode == 201) {
      setState(() {
        isVerified = true;
        isLoading = false;
      });

      // แสดงข้อความสำเร็จสักครู่ก่อนเปลี่ยนหน้า
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Loginpage()),
      );
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('การยืนยันล้มเหลว กรุณาลองอีกครั้ง')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "ยืนยันอีเมลของคุณ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "กรุณาตรวจสอบลิงก์ในอีเมลของคุณเพื่อยืนยันบัญชี",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 30),

              if (isLoading) const CircularProgressIndicator(color: Colors.orange),

              if (isVerified) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                const Text(
                  "✅ ยืนยันอีเมลสำเร็จ!",
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ],

              const SizedBox(height: 20),
              
            ],
          ),
        ),
      ),
    );
  }
}

