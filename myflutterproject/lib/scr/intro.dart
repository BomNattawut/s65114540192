import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myflutterproject/scr/login.dart';
import 'package:myflutterproject/scr/Home.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true; // Flag สำหรับการโหลดสถานะการล็อกอิน

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // ถ้าล็อกอินแล้ว ไปหน้า HomePage ทันที
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // ถ้ายังไม่ล็อกอิน ให้แสดงหน้า IntroPage
      setState(() {
        _isLoading = false; // โหลดเสร็จสิ้น
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // แสดง loading จนกว่าจะตรวจสอบสถานะการล็อกอินเสร็จ
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                buildPage(
                  title: "Welcome to the App",
                  description: "Find parties and workout together easily.",
                  imagePath: "assets/intro1.png",
                ),
                buildPage(
                  title: "Create Events",
                  description: "You can create and join events anytime.",
                  imagePath: "assets/intro2.png",
                ),
                buildPage(
                  title: "Stay Connected",
                  description: "Connect with friends and stay updated.",
                  imagePath: "assets/intro3.png",
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                buildIndicator(isActive: i == _currentPage),
            ],
          ),
          const SizedBox(height: 20),
          _currentPage == 2
              ? ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Loginpage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : TextButton(
                  onPressed: () {
                    _pageController.animateToPage(2,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut);
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildPage({required String title, required String description, required String imagePath}) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 250),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildIndicator({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isActive ? 20 : 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.orange : Colors.white70,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
