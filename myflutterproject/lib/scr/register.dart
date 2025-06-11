import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/waitingverified.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key});

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _genderselected;
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> registerUser() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/Register/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': _emailController.text,
        'username': _usernameController.text,
        'age': _ageController.text,
        'gender': _genderselected,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 201) {
      final responsedata = jsonDecode(response.body);
      final String userId = responsedata['id'].toString();
      final refreshtoken = responsedata['token'];
      final accesstoken = responsedata['access_token'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('refresh_token', refreshtoken);
      await prefs.setString('access_token', accesstoken);

      if (userId.isNotEmpty) {
        // ❌ คงไว้เหมือนเดิม ไม่เปลี่ยนเส้นทาง
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailPage(userId: userId), // คงไว้เหมือนเดิม
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid User ID in response')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 39, 38, 38),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
               Center(
                child: Image.asset(
              'assets/images/icon.png', // พาธของไฟล์รูปภาพ
              height: 100, // ปรับขนาดความสูง
              width: 200, // ปรับขนาดความกว้าง
              fit: BoxFit.cover, // จัดการการแสดงผลของรูป
            )),
              Text('Smartywithyou',style: TextStyle(color: Colors.orange,fontSize: 16),),
              SizedBox(height: 60,),
              Text('ลงทะเบียน',style: TextStyle(color:Colors.orange,fontSize: 20),),
              const SizedBox(height:20), // เว้นระยะด้านบน
              textField("Gmail", Icons.email, _emailController),
              textField("Username", Icons.person, _usernameController),
              textField("Age", Icons.cake, _ageController),
              textField("Password", Icons.lock, _passwordController, isPassword: true),
              dropdownField(), // ✅ Dropdown Gender ปรับให้แสดงเต็มช่อง
              const SizedBox(height: 20), // ✅ เพิ่มระยะห่างระหว่างฟอร์มกับปุ่ม
              registerButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันสร้าง TextField แบบลดขนาดให้ฟอร์มชิดกัน
  Widget textField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), // ✅ เพิ่มระยะห่าง
      child: SizedBox(
        height: 55, // ✅ ปรับให้ช่องพอดี
        width: MediaQuery.of(context).size.width * 0.9,
        child: TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.white, size: 22), // ✅ ปรับขนาดไอคอน
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            labelStyle: const TextStyle(color: Colors.white, fontSize: 16),
            filled: true,
            fillColor: Colors.grey,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // ✅ ทำให้ฟิลด์เต็มช่อง
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันสร้าง Dropdown สำหรับเพศที่แสดงเต็มช่อง
 Widget dropdownField() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: SizedBox(
      height: 55,
      width: MediaQuery.of(context).size.width * 0.9,
      child: DropdownButtonFormField<String>(
        hint: const Text("Select Gender", style: TextStyle(color: Colors.white, fontSize: 16)),
        value: _genderselected,
        items: [
          DropdownMenuItem(value: "man", child: Text("Man", style: TextStyle(color: Colors.black, fontSize: 16))),
          DropdownMenuItem(value: "women", child: Text("Women", style: TextStyle(color: Colors.black, fontSize: 16))),
        ],
        onChanged: (String? newvalue) {
          setState(() {
            _genderselected = newvalue;
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    ),
  );
}

  // ✅ ปุ่มลงทะเบียน
  Widget registerButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: ElevatedButton(
        onPressed: () async {
          await registerUser();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18), // ✅ ทำให้ปุ่มใหญ่ขึ้น
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}