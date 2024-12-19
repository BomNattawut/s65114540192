import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/register.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> login() async {
    final String apiUrl = 'http://10.0.2.2:8000/Smartwityouapp/Login/';

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

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('user_email', _usernameController.text);
        prefs.setString('access_token', accessToken); 
        prefs.setString('refresh_token', refreshToken); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        // ไปหน้า Home หลังจาก Login สำเร็จ
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
            _buildTextField("Email", Icons.person, _usernameController, false),
            const SizedBox(height: 12),
            _buildTextField("Password", Icons.lock, _passwordController, true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Login",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            _socialLoginSection(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Registerpage()),
                    );
                  },
                  child: const Text(
                    "Register",
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
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white24,
        labelStyle: TextStyle(color: Colors.white),
      ),
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _socialLoginSection() {
    return Column(
      children: [
        const Text(
          "Or",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 20),
        _socialLoginButton("Login with Google", Icons.email, Colors.red),
      ],
    );
  }

  Widget _socialLoginButton(String text, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
