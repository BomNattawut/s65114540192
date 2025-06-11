import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendPasswordResetRequest() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = "❌ กรุณากรอกอีเมล";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/Smartwityouapp/request-password-reset/"), // 🔥 แก้เป็น URL จริงในโปรดักชัน
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = "✅ ลิงก์รีเซ็ตรหัสผ่านถูกส่งไปที่อีเมลของคุณแล้ว!";
        });
      } else {
        setState(() {
          _message = "❌ อีเมลนี้ไม่มีในระบบ หรือเกิดข้อผิดพลาด!";
        });
      }
    } catch (e) {
      setState(() {
        _message = "⚠️ ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🔑 ลืมรหัสผ่าน")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "กรุณากรอกอีเมลของคุณเพื่อรับลิงก์รีเซ็ตรหัสผ่าน",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "📧 อีเมล",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendPasswordResetRequest,
                    child: Text("📩 ส่งคำขอรีเซ็ตรหัสผ่าน"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
            SizedBox(height: 10),
            if (_message != null)
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _message!.contains("✅") ? Colors.green : Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}