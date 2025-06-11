import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/createparty.dart';
import 'package:myflutterproject/scr/notification.dart';
import 'package:myflutterproject/scr/searchparty.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:myflutterproject/scr/profile.dart';
import 'apifirebase.dart';

class Freindpage extends StatefulWidget {
  const Freindpage({super.key});

  @override
  State<Freindpage> createState() => _FreindpageState();
}

class _FreindpageState extends State<Freindpage> {
  List<Map<String, dynamic>> friends = [];
  String? searchQuery;
  List<Map<String, dynamic>> fillterfriends = [];
  int _currentindex = 3;
  Future<void> fecthallfrieds() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthfriends/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;

        // 🔹 เรียก setState() เพื่ออัปเดต UI
        setState(() {
          friends = data.map((item) => item as Map<String, dynamic>).toList();
        });

        print('รายเชื่อเพื่อนที่ส่งมา${friends}');
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {}
  }

  Future<void> searchfriends() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    try {
      final response = await http.get(
          Uri.parse(
              'http://10.0.2.2:8000/Smartwityouapp/serachfriend/?q=${searchQuery}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          });
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        fillterfriends =
            data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('Error ${response.statusCode}');
      }
    } catch (e) {}
  }

  void initState() {
    super.initState();
    fecthallfrieds();
  }

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
    } else if (_currentindex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เพื่อน',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[800],
      body: Column(
        children: [
          // 🔹 ช่องค้นหา
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: 0.5,
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                      },
                      decoration: InputDecoration(
                        fillColor: Colors.grey[200],
                        filled: true,
                        labelText: 'ค้นหาเพื่อน',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10), // 🔹 เว้นระยะห่าง
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    onPressed: () {
                      serachfriend();
                    },
                    icon: Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => serachfriend()));
                  },
                  label: Text(
                    'เพิ่มเพื่อน',
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: Icon(Icons.person_add),
                  style: ElevatedButton.styleFrom(
                      iconColor: Colors.white, backgroundColor: Colors.orange),
                ),
              ),
              SizedBox(width: 10),
              Container(
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => showfriendrequest()));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: Text(
                      'คำขอเป้นเพื่อน',
                      style: TextStyle(color: Colors.white),
                    )),
              )
            ],
          ),
          SizedBox(height: 5),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
          // 🔹 รายการเพื่อน (แก้ไขปัญหาการขยาย ListView)
          Expanded(
            // ✅ ใช้ Expanded เพื่อแก้ปัญหา "Vertical viewport was given unbounded height."
            child: friends.isEmpty
                ? Center(
                    child: Text(
                      'ไม่มีเพื่อน',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[
                          index]; // ✅ แก้ชื่อ key จาก "frined" เป็น "friend"
                      return SizedBox(
                        height: 80,
                        child: Card(
                          color: Colors.grey,
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                              leading: CircleAvatar(
                                radius: 40, // ✅ ลดขนาดให้เหมาะสม
                                backgroundImage: friend['frined_profile'] !=
                                        null
                                    ? NetworkImage(
                                        'http://10.0.2.2:8000${friend['frined_profile']}')
                                    : null,
                                child: friend['frined_profile'] == null
                                    ? Icon(Icons.person,
                                        size: 40, color: Colors.white)
                                    : null,
                                backgroundColor: Colors.grey.shade400,
                              ),
                              title: Text(
                                '${friend['friend_username']}',
                                style: GoogleFonts.notoSansThai(
                                    textStyle: TextStyle(fontSize: 16),
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProfilePage(
                                              user: friend['friend_user'],
                                            )));
                              }),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
            icon: Icon(Icons.search),
            label: 'Searchparty',
          ),
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

class serachfriend extends StatefulWidget {
  const serachfriend({super.key});

  @override
  State<serachfriend> createState() => _serachfriendState();
}

class _serachfriendState extends State<serachfriend> {
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> fillterfriends = [];
  String? searchQuery;

  Future<void> searchfriends() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8000/Smartwityouapp/serachfriend/?q=${searchQuery}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        print('ข้อมูลที่ส่งมา: ${data}');
        setState(() {
          fillterfriends =
              data.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: Text(
          'ค้นหาเพื่อน',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // TextField Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                searchQuery = value;
              },
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                labelText: 'ค้นหาเพื่อน',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          // Search Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: searchfriends,
              icon: Icon(Icons.search),
              label: Text('ค้นหา',
                  style: GoogleFonts.notoSansThai(
                      textStyle: TextStyle(fontSize: 16),
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.grey),
          ),
          // Results Section
          Expanded(
            child: fillterfriends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery == null || searchQuery!.isEmpty
                              ? Icons.search
                              : Icons.search_off,
                          size: 80,
                          color: Colors.grey[400]?.withOpacity(0.5),
                        ),
                        SizedBox(height: 10),
                        Text(
                          searchQuery == null || searchQuery!.isEmpty
                              ? 'กรุณาใส่คำค้นหา'
                              : 'ไม่พบผลลัพธ์',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: fillterfriends.length,
                    itemBuilder: (context, index) {
                      final results = fillterfriends[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                'http://10.0.2.2:8000${results['profile_image']}'),
                            radius: 20,
                          ),
                          title: Text('${results['username']}'),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        FreindProfile(user: results)));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FreindProfile extends StatefulWidget {
  final Map<String, dynamic> user;
  const FreindProfile({super.key, required this.user});
  @override
  _FreindProfileState createState() => _FreindProfileState();
}

class _FreindProfileState extends State<FreindProfile> {
  Map<String, dynamic>? userprofile;
  bool isLoading = true;
  int _currentindex = 3;
  Future<void> fecthProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    print('userid: ${widget.user['id']}');

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8000/Smartwityouapp/feactProfile/'), // แก้ไข URL ให้ถูกต้อง
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId':
              widget.user['id'], // ตรวจสอบว่า widget.user['id'] มีค่าหรือไม่
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        setState(() {
          userprofile = data;
          isLoading = false;
        });

        print('Profile data: $userprofile');
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendfriendrequest() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    print('คนส่ง:${userId}');
    print('คนรับ${userprofile?['id']}');
    try {
      final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/friendrequest/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: json.encode({'user': userId, 'friend': userprofile?['id']}));
      if (response.statusCode == 200) {
        print('ส่งคำขอเป้นเพื่อเเล้ว');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ส่งคำขอเป็นเพื่อนเเล้ว')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), //เเก้ตรงนี้
          (route) => false, // ลบ Stack ทั้งหมด
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ส่งคำขอเป็นเพื่อนไม่สำเร็จ')));
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  @override
  void initState() {
    super.initState();
    fecthProfile();
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userprofile == null
              ? Center(child: Text('Failed to load profile'))
              : Stack(
                  children: [
                    // Background Image
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: userprofile?['background'] == null
                            ? Colors.orange.withOpacity(0.5)
                            : null, // ✅ แสดงสีส้มถ้าไม่มีรูป
                        image: userprofile?['background'] != null
                            ? DecorationImage(
                                image: NetworkImage(
                                  'http://10.0.2.2:8000/${userprofile?['background']}',
                                ),
                                fit: BoxFit.cover,
                              )
                            : null, // ✅ ถ้ามีรูปถึงจะแสดงภาพ
                      ),
                    ),
                    // Content
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 120),
                          // Profile Image
                          CircleAvatar(
                            radius: 80,
                            backgroundImage: userprofile!['profile_image'] !=
                                    null
                                ? NetworkImage(
                                    'http://10.0.2.2:8000${userprofile!['profile_image']}')
                                : null,
                            child: userprofile!['profile_image'] == null
                                ? Icon(Icons.person,
                                    size: 50, color: Colors.white)
                                : null,
                            backgroundColor: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          // Name
                          Text(
                            userprofile!['username'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // About Me Section
                          Container(
                            width: MediaQuery.of(context).size.width *
                                2.0, // กำหนดความกว้างให้สัมพันธ์กับหน้าจอ
                            padding: const EdgeInsets.all(16.0),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(221, 50, 49, 49),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('เกี่ยวกับฉัน',
                                    style: GoogleFonts.notoSansThai(
                                      textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    )),
                                const SizedBox(height: 8),
                                Text('ประเภทการออกำลังกายที่ชอบ:',
                                    style: GoogleFonts.notoSansThai(
                                      textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )),
                                ...userprofile!['exercise_types']
                                    .map<Widget>((type) {
                                  return Text(
                                    type['name'] ?? 'Unknown Type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  child: Divider(color: Colors.grey),
                                ),
                                Text('วันเวลาออกำลังกาย:',
                                    style: GoogleFonts.notoSansThai(
                                      textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )),
                                ...userprofile!['exercise_times']
                                    .map<Widget>((time) {
                                  return Text(
                                    '${time['day']}: ${time['start_time']} - ${time['end_time']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  child: Divider(color: Colors.grey),
                                ),
                                Text('คำอธิบาย:',
                                    style: GoogleFonts.notoSansThai(
                                      textStyle: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )),
                                const SizedBox(height: 8),
                                Text(
                                  userprofile!['description'] ??
                                      'No description available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Back Button and Add Friend Icon
                    Positioned(
                      top: 40,
                      left: 16,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 16,
                      child: IconButton(
                        icon: Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
                          // Add friend action
                          sendfriendrequest();
                        },
                      ),
                    ),
                  ],
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
            icon: Icon(Icons.search),
            label: 'Searchparty',
          ),
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

class showfriendrequest extends StatefulWidget {
  const showfriendrequest({super.key});

  @override
  State<showfriendrequest> createState() => _showfriendrequestState();
}

class _showfriendrequestState extends State<showfriendrequest> {
  List<Map<String, dynamic>> friendrequest = [];

  Future<void> fecthfriendrequests() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/feachallfriend/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'userId': userId ?? ''
          });
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          friendrequest =
              data.map((item) => item as Map<String, dynamic>).toList();
        });
        print('ข้อมูลที่ส่งมา${friendrequest}');
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  void initState() {
    super.initState();
    fecthfriendrequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('รายการคำขอเพื่อน'),
      ),
      backgroundColor: Colors.grey[800],
      body: friendrequest.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group, // 💡 ไอคอนที่เหมาะกับ "ไม่มีคำขอ"
                      size: 80,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ไม่มีคำขอเป็นเพื่อน',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : ListView.builder(
              itemCount: friendrequest.length,
              itemBuilder: (context, index) {
                final request = friendrequest[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: request['sender_profile_image'] != null
                          ? NetworkImage(
                              'http://10.0.2.2:8000/${request['sender_profile_image']}')
                          : null,
                      child: request['sender_profile_image'] == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white,
                            )
                          : null,
                      backgroundColor: Colors.grey,
                    ),
                    title: Text('คำขอจาก: ${request['sender_username']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ถึง: ${request['receiver_username']}'),
                        Text(
                            'วันที่: ${request['send_date']} เวลา: ${request['send_time']}'),
                        Text('สถานะ: ${request['status']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            bool success = await acceptfriend(request['id']);
                            if (success) {
                              setState(() {
                                friendrequest.removeWhere(
                                    (item) => item['id'] == request['id']);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('ยอมรับคำขอเพื่อนสำเร็จ!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('เกิดข้อผิดพลาด กรุณาลองใหม่')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check, color: Colors.green),
                        ),
                        IconButton(
                          onPressed: () async {
                            bool success = await rejectedfriend(request['id']);
                            if (success) {
                              setState(() {
                                friendrequest.removeWhere(
                                    (item) => item['id'] == request['id']);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ปฏิเสธเเล้ว!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('เกิดข้อผิดพลาด กรุณาลองใหม่')),
                              );
                            }
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
