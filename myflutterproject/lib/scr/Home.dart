import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:myflutterproject/scr/Freind.dart';
import 'package:myflutterproject/scr/auth_service/Authservice.dart';
import 'package:myflutterproject/scr/googlemap.dart';
import 'package:myflutterproject/scr/joinparty.dart';
import 'package:myflutterproject/scr/notification.dart';
import 'package:myflutterproject/scr/refresh_token.dart';
import 'package:myflutterproject/scr/profile.dart';
//import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:myflutterproject/scr/createparty.dart';
import 'package:myflutterproject/scr/login.dart';
import 'package:myflutterproject/scr/partylist.dart';
import 'package:myflutterproject/scr/searchparty.dart';
import 'permission.dart';
import 'package:myflutterproject/scr/showjounreq.dart';
import 'historypage.dart';
//import 'invitation_provider.dart';
import 'package:myflutterproject/scr/Partyfeedpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentindex = 2; // ตัวแปรเก็บสถานะของ BottomNavigationBar
  Map<String, dynamic>? userprofile;
  List<Map<String, dynamic>> upcomingparty = [];
  List<Map<String, dynamic>> recomentparty = [];
  List<Map<String, dynamic>> updates = [];
  PageController _pageController = PageController(viewportFraction: 1.0);
  int joinRequestCount = 0;
  int invitationCount = 0;
  Timer? _timer;
  bool updateloading=true;
  bool upcomingpartyloading=true;
  bool recomendpartyloading=true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    requestNotificationPermissions();
    fecthuserprofile();
    fetchupcomingParty();
    fetchrecomentparty();
    _fetchUpdates();
    _fecthjoinrequestcount();
    _fecthinvitationcount();
    _startAutoUpdate();
  }

  void _startAutoUpdate() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      if (mounted) {
        // ✅ ตรวจสอบก่อนเรียก setState()
        _fecthjoinrequestcount();
        _fecthinvitationcount();
        fetchrecomentparty();
        fetchrecomentparty();
      }
    });
  }

  void _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null || accessToken.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

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
      await prefs.remove('userid');
      await prefs.remove('user_email');
      await AuthService.saveLoginStatus(false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
        (route) => false, // ลบ Stack ทั้งหมด
      );
      print('Logout successful');
      // นำทางไปยังหน้าล็อกอิน
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print('Logout failed: ${response.statusCode} - ${response.body}');
    }
  }

  // ฟังก์ชัน refresh token
  Future<void> fecthuserprofile() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/feactProfile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          userprofile = data;
        });
        print('ข้อมูลuserที่ส่งมาซ${userprofile}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  Future<void> fetchupcomingParty() async {
    // ✅ จำลองการดึงข้อมูลจาก API (สามารถเปลี่ยนเป็น API จริงได้)
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/upcomingparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
       
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        print('ปาร์ตี้ที่ส่งมา${data}');
        setState(() {
          upcomingpartyloading=false;
          upcomingparty =
              data.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      upcomingpartyloading=false;
      print("Error${e}");
    }
  }

  Future<void> fetchrecomentparty() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/recomendparty/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'userId': userId ?? ''
          });
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;

        setState(() {
          recomendpartyloading=false;
          recomentparty =
              data.map((item) => item as Map<String, dynamic>).toList();
        });
        print('ปาร์ตี้ที่กรอง:${recomentparty}');
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      recomendpartyloading=false;
      print('Error:${e}');
    }
  }

  Future<void> _fetchUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/gettallupdate/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          });
      if (response.statusCode == 200) {
        updateloading=false;
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;

        setState(() {
          updates = data.map((item) => item as Map<String, dynamic>).toList();
        });
        print('ปาร์ตี้ที่กรอง:${recomentparty}');
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  Future<void> _fecthjoinrequestcount() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/joinrequestcount/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'userId': userId ?? ''
          });
      if (response.statusCode == 200) {
        final data = response.body;

        setState(() {
          joinRequestCount = int.parse(data);
        });
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  Future<void> _fecthinvitationcount() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/invitationcoint/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'userId': userId ?? ''
          });
      if (response.statusCode == 200) {
        final data = response.body;

        setState(() {
          invitationCount = int.parse(data);
        });
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  // ฟังก์ชันเมื่อผู้ใช้เลือก BottomNavigationBar
  void _onBottomNavTap(int index) {
    setState(() {
      _currentindex = index;
    });

    if (_currentindex == 0) {
      // ถ้าผู้ใช้เลือกแท็บ "Create Party"
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MakePartyPage()),
      );
    } else if (_currentindex == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const Searchparty()));
    } else if (_currentindex == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Freindpage()));
    } else if (_currentindex == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => notification()));
    } else if (_currentindex == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomePage()));
      (route) => false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ ปิด Timer เมื่อออกจากหน้านี้
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Center(
          child: Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context)
                  .openDrawer(); // ✅ ใช้ Builder เพื่อให้ context อยู่ใน Scaffold
            },
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[800],
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Userprofile()));
              },
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  image: userprofile?['background_image'] != null
                      ? DecorationImage(
                          image: NetworkImage(
                              'http://10.0.2.2:8000${userprofile?['background_image']}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: userprofile?['profile_image'] != null
                          ? NetworkImage(
                              'http://10.0.2.2:8000${userprofile?['profile_image']}')
                          : null,
                      child: userprofile?['profile_image'] == null
                          ? Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                      backgroundColor: Colors.grey.shade400,
                      radius: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${userprofile?['username'] ?? "Username"}',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ เมนู Drawer
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.add, color: Colors.orange),
                    title: Text('สร้างปาร์ตี้',
                        style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontSize: 20, color: Colors.orange))),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MakePartyPage()));
                    },
                  ),
                  Divider(color: Colors.white, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.search, color: Colors.orange),
                    title: Text('ค้นหาปาร์ตี้',
                        style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontSize: 20, color: Colors.orange))),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Searchparty()));
                    },
                  ),
                  Divider(color: Colors.white, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.orange),
                    title: Text('เพื่อน',
                       style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontSize: 20, color: Colors.orange))),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Freindpage()));
                    },
                  ),
                  Divider(color: Colors.white, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.feed, color: Colors.orange),
                    title: Text('โพสต์กิจกรรม',
                       style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontSize: 20, color: Colors.orange))),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PartyFeedPage()));
                    },
                  ),
                  Divider(color: Colors.white, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: Colors.orange),
                    title: Text('อาลาบั้มปาร์ตี้ที่เข้าร่วม',
                       style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontSize: 20, color: Colors.orange))),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PartyHistoryPage()));
                    },
                  ),
                  Divider(color: Colors.white, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: Colors.orange),
                    title: Text('อาลาบั้มปาร์ตี้ทีสร้าง',
                        style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontSize: 20, color: Colors.orange))),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CreatedPartyMemoryPage()));
                    },
                  ),
                  Divider(color: Colors.white, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('ออกจากระบบ',
                        style: GoogleFonts.notoSansThai( textStyle: TextStyle(color: Colors.red, fontSize: 20))),
                    onTap: () {
                      logout(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[800],
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 10,
                ),
                Text(
                  'ยินดีตอนรับ ${userprofile?['username']} !!',
                  style: GoogleFonts.notoSansThai(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                // ปุ่มปาร์ตี้ของฉัน
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PartyListScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 86, 86, 86),
                    ),
                    icon:
                        const Icon(Icons.event, size: 18, color: Colors.white),
                    label: const Text(
                      'ปาร์ตี้ของฉัน',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(width: 8), // 🔸 ระยะห่างปุ่มที่ 1 และ 2

                // ปุ่มคำขอเข้าร่วม
                Expanded(
                  child: Stack(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      showjoinpartyrequest()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 86, 86, 86),
                        ),
                        icon: const Icon(Icons.person_add,
                            size: 18, color: Colors.white),
                        label: const Text(
                          'คำขอเข้าร่วม',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                      if (joinRequestCount > 0)
                        Positioned(
                          right: 5,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              joinRequestCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8), // 🔸 ระยะห่างปุ่มที่ 2 และ 3

                // ปุ่มคำเชิญเข้าร่วม
                Expanded(
                  child: Stack(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ShowAllinvitation()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 86, 86, 86),
                        ),
                        icon: const Icon(Icons.mail,
                            size: 18, color: Colors.white),
                        label: const Text(
                          'คำเชิญเข้าร่วม',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                      if (invitationCount > 0)
                        Positioned(
                          right: 5,
                          top: 5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              invitationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('📢 ประกาศและอัปเดตระบบ',
                  style: GoogleFonts.notoSansThai(
                    textStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
            ),
            SizedBox(height: 10,),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.grey),
          ),
            // ✅ ส่วนแสดงผลรายการปาร์ตี้
            SizedBox(height: 40),
            updateloading? Center(
                child: Center(
                  child: Center(child: CircularProgressIndicator(color: Colors.orange)) ,
                ),
            ):
            updates.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ สไลด์โชว์อัปเดตระบบ
                      SizedBox(
                        height: 250, // ✅ กำหนดความสูงของ PageView
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: updates.length,
                          itemBuilder: (context, index) {
                            final update = updates[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[800],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (update["image"] !=
                                        null) // ✅ เช็คว่ามีรูปไหม
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          'http://10.0.2.2:8000${update["image"]}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                                Icons.image_not_supported,
                                                size: 100,
                                                color: Colors.white30);
                                          },
                                        ),
                                      ),

                                    // ✅ ข้อความบนรูป
                                    Positioned(
                                      bottom: 20,
                                      left: 20,
                                      right: 20,
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              update['title'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              update['description'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  )
                : Center(
                    child: Text(
                      'ไม่มีประกาศ',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
            SizedBox(height: 10,),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.grey),
          ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('ปาร์ตี้ที่ใกล้ถึงเวลา',
                      style: GoogleFonts.notoSansThai(
                        textStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ),
                SizedBox(height: 15),
                SizedBox(
                  height: 150, // ✅ กำหนดความสูงให้ ListView
                  child: 
                  upcomingpartyloading? 
                  Center(
                    child: Center(child: Center(
                  child: Center(child: Center(child: CircularProgressIndicator(color: Colors.grey)) ,),
              ))
                  ):
                  upcomingparty.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons
                                      .fitness_center, 
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ไม่พบปาร์ตี้',
                              style: GoogleFonts.notoSansThai(textStyle: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),)
                            ),
                          ],
                        )
                      : ListView.builder(
                          scrollDirection:
                              Axis.horizontal, // ✅ ให้รายการแสดงแนวนอน
                          itemCount:
                              upcomingparty.length, // รายการปาร์ตี้ที่ดึงมา
                          itemBuilder: (context, index) {
                            final party = upcomingparty[
                                index]; // ดึงข้อมูลปาร์ตี้แต่ละอัน
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Container(
                                width: 200, // ✅ กำหนดขนาดของแต่ละรายการ
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[800],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        party['name'], // ชื่อปาร์ตี้
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'วัน: ${party['date']}',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "เวลา: ${party['start_time']} - ${party['finish_time']}", // เวลาปาร์ตี้
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      Spacer(),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // ✅ เมื่อกดให้ไปที่หน้ารายละเอียดปาร์ตี้
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            final userId =
                                                prefs.getString('userid');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PartyDetailScreen(
                                                        party: party,
                                                        isLeader:
                                                            party['leader'] ==
                                                                userId),
                                              ),
                                            );
                                          },
                                          child: Text("ดูรายละเอียด"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            Padding(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.orange),
          ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 16),
                Text(
                  'เเนะนำปาร์ตี้',
                  style: GoogleFonts.notoSansThai(
                      textStyle: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 230, // ✅ ลดความสูงให้พอดีกับข้อมูล
              child: 
              recomendpartyloading ? 
              Center(
                  child: Center(child: Center(child: CircularProgressIndicator(color: Colors.orange)) ,),
              ):
              recomentparty.isEmpty
                  ?  Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons
                                      .fitness_center, 
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ไม่พบปาร์ตี้',
                              style: GoogleFonts.notoSansThai(textStyle: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),)
                            ),
                          ],
                        )
                  : SingleChildScrollView(
                      // ✅ ห่อด้วย ScrollView เพื่อรองรับการเลื่อน
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: recomentparty.map((party) {
                          return Card(
                            color: Colors.blueGrey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: Container(
                              width: 280, // ✅ ปรับขนาดให้พอดี
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    party["name"],
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "🕒 ${party["start_time"]}",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    "📍 ${party["location"]["location_name"]}",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Expanded(
                                      child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        'http://10.0.2.2:8000/${party['location']['place_image']}',
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.image_not_supported,
                                              size: 100, color: Colors.white30);
                                        },
                                      ),
                                    ),
                                  )),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      Joinparty(
                                                          selectparty: party)),
                                            );
                                          },
                                          icon: Icon(Icons.info, size: 18),
                                          label: Text("รายละเอียด"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                          width:
                                              8), // ✅ เว้นระยะห่างระหว่างปุ่ม
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PartyMapScreen(
                                                        latitude: double.tryParse(
                                                                party['location']
                                                                        [
                                                                        'latitude']
                                                                    .toString()) ??
                                                            0.0,
                                                        longitude: double.tryParse(
                                                                party['location']
                                                                        [
                                                                        'longitude']
                                                                    .toString()) ??
                                                            0.0,
                                                      )),
                                            );
                                          },
                                          icon: Icon(Icons.map, size: 18),
                                          label: Text("แผนที่"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentindex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create Party'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Searchparty'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add), label: 'Friends'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
      ),
    );
  }
}
