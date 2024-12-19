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
      print('Response body: ${response.body}');
      
      // ตรวจสอบว่า 'id' เป็น String และเก็บไว้เป็น String
      final String userId = responsedata['id'].toString();
      final refreshtoken =responsedata['token'];
      final accesstoken=responsedata['access_token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('refresh_token', refreshtoken);
      await prefs.setString('access_token', accesstoken);
     

      if (userId.isNotEmpty) {
        print('User ID: $userId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyEmailPage(userId: userId), // ส่งเป็น String
          ),
        );
      } else {
        print('Error: User ID is null or invalid');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid User ID in response')),
        );
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration Failed')));
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 39, 38, 38),
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // จัดให้ TextField อยู่กึ่งกลาง
        children: [
          // Email
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.9, // 90% ของหน้าจอ
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Gmail",
                  prefixIcon: Icon(Icons.email),
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(), // เส้นขอบ
                ),
              ),
            ),
          ),
          // Username
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.9,
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person),
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // Age
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.9,
              child: TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: "Age",
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // Password
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.9,
              child: TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // ใช้สถานะจากคลาสหลัก
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible =
                            !_isPasswordVisible; // เปลี่ยนสถานะ
                      });
                    },
                  ),
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          // Gender Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: DropdownButtonFormField<String>(
                hint: Text("Select Gender"),
                value: _genderselected,
                items: ["man", "woman"].map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (String? newvalue) {
                  setState(() {
                    _genderselected = newvalue;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // Register Button
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // ปรับให้ปุ่มมีความกว้าง 90% ของหน้าจอ
              child: ElevatedButton(
                onPressed: () async {
                  // เรียกฟังก์ชัน registerUser
                  await registerUser();
                },
                child: Text("Register"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16)), // ปรับขนาดของปุ่มให้สูงขึ้น
              ),
            ),
          ),
          // OR Text
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text("OR",
                style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
          // Register with Google Button
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // ปรับให้ปุ่มมีความกว้าง 90% ของหน้าจอ
              child: ElevatedButton.icon(
                onPressed: () {},
                label: Text("Register with Google"),
                icon: Icon(
                  Icons.email,
                  color: Colors.red,
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16)), // ปรับขนาดของปุ่มให้สูงขึ้น
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}