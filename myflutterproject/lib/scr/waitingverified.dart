
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/Home.dart';  // นำเข้า Home Page

class VerifyEmailPage extends StatefulWidget {
  final String userId;

  VerifyEmailPage({required this.userId, super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isloading = false;
  bool isverified = false;

  @override
  void initState() {
    super.initState();
    verify(); // เรียก verify เมื่อหน้าถูกโหลด
  }

  Future<void> verify() async {
    setState(() {
      isloading = true;
    });
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/check_verify/'),
      headers: {
        'Content-Type': 'application/json',  
      },
      body: {
          'userId':widget.userId
      }
    );
    setState(() {
      isloading = false;
    });
    if (response.statusCode == 201) {
      setState(() {
        isverified = true;
      });
      // เปลี่ยนหน้าไปยังหน้า Home เมื่อการยืนยันสำเร็จ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // ใช้หน้า Home แทน MyWidget()
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 80, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Please check the verification link in your inbox.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 30),
              isloading
                  ? CircularProgressIndicator(color: Colors.orange)
                  : Container(), // แสดง progress indicator เมื่อกำลังโหลด
              SizedBox(height: 20),
              TextButton(
                onPressed: verify, // เรียกฟังก์ชัน verify เมื่อกดปุ่ม
                child: Text(
                  "Resend Email",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
