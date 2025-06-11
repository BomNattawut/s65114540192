import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/apifirebase.dart';
import 'package:myflutterproject/scr/checkinpage.dart';
import 'package:myflutterproject/scr/googlemap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myflutterproject/scr/check_in.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});

  @override
  _PartyListScreenState createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // สร้าง TabController
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: Colors.orange,
        title: Text('ปาร์ตี้ของฉัน',style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),),
        bottom:TabBar(
  controller: _tabController,
  indicatorColor: Colors.orange,
  tabs: [
    Tab(
      child: Text(
        'ปาร์ตี้ที่สร้าง',
        style: GoogleFonts.notoSansThai(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    ),
    Tab(
      child: Text(
        'ปาร์ตี้ที่เข้าร่วม',
        style: GoogleFonts.notoSansThai(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    ),
  ],
),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // แสดงปาร์ตี้ที่สร้างเอง
          CreatedPartiesTab(),

          // แสดงปาร์ตี้ที่เข้าร่วม
          const JoinedPartiesTab(),
        ],
      ),
      backgroundColor:const Color.fromARGB(255, 39, 38, 38) ,
    );
  }
}

class CreatedPartiesTab extends StatefulWidget {
  const CreatedPartiesTab({super.key});

  @override
  _CreatedPartiesTabState createState() => _CreatedPartiesTabState();
}

class _CreatedPartiesTabState extends State<CreatedPartiesTab> {
  List<Map<String, dynamic>> createdParties = [];
  bool isLoading = true;

  Future<void> fetchCreatedParties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? userId = prefs.getString('userid');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthcreateparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userid': userId ?? '', // ตรวจสอบว่ามี userId หรือไม่
        },
      );

      if (response.statusCode == 200) {
        // Decode JSON response
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        print('party:$data');
        setState(() {
          createdParties =
              data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        // จัดการกรณีที่ statusCode ไม่ใช่ 200
        throw Exception('Failed to fetch created parties');
      }
    } catch (e) {
      // จัดการข้อผิดพลาด
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCreatedParties();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange,));
    }

    if (createdParties.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(
            Icons.calendar_month, // 💡 ไอคอนที่เหมาะกับ "ไม่มีคำขอ"
            size: 80,
            color: Colors.grey[600],
          ),
          
         
            ],
          ),
          const SizedBox(height: 16),
           const Text(
            'ไม่มีปาร์ตี้ที่สร้าง',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return ListView.builder(

      itemCount: createdParties.length,
      itemBuilder: (context, index) {
        final party = createdParties[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
                'http://10.0.2.2:8000${party['location']['place_image']}'),
            radius: 25,
          ),
          title: Text(party['name'] ?? 'Unnamed Party',style: TextStyle(color: Colors.white),),
          subtitle: Text(
              'สถานที่:${party['location']['location_name'] ?? 'Unknown place'}\nวันนัดหมาย:${party['date']}',style: TextStyle(color: const Color.fromARGB(255, 125, 125, 125)),),
          trailing: const Icon(Icons.arrow_forward,color: const Color.fromARGB(255, 125, 125, 125),),
          onTap: () async {
            // Navigate to party detail page
            final prefs =
                await SharedPreferences.getInstance(); // ดึง SharedPreferences
            final userId = prefs.getString('userid');
            print(
                'Leader ID: "${party['leader']}" (${party['leader'].runtimeType})');
            print('User ID: "$userId" (${userId.runtimeType})');
            print(
                'Is Leader: ${party['leader']?.toString().trim() == userId?.toString().trim()}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PartyDetailScreen(
                  party: party,
                  isLeader: party['leader'] == userId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class JoinedPartiesTab extends StatefulWidget {
  const JoinedPartiesTab({super.key});

  @override
  State<JoinedPartiesTab> createState() => _JoinedPartiesTabState();
}

class _JoinedPartiesTabState extends State<JoinedPartiesTab> {
  List<Map<String, dynamic>> joinedParties = [];
  bool isLoading = true;
  Future<void> fecthjoinparty() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? userId = prefs.getString('userid');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthjoinparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userid': userId ?? '', // ตรวจสอบว่ามี userId หรือไม่
        },
      );
      if (response.statusCode == 200) {
        // Decode JSON response
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        print('party:$data');
        setState(() {
          joinedParties =
              data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        // จัดการกรณีที่ statusCode ไม่ใช่ 200
        throw Exception('Failed to fetch created parties');
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    fecthjoinparty();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (joinedParties.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(
            Icons.calendar_month, // 💡 ไอคอนที่เหมาะกับ "ไม่มีคำขอ"
            size: 80,
            color: Colors.grey[600],
          ),
          
         
            ],
          ),
          const SizedBox(height: 16),
           const Text(
            'ไม่มีปาร์ตี้ที่เข้าร่วม',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      itemCount: joinedParties.length,
      itemBuilder: (context, index) {
        final party = joinedParties[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
                'http://10.0.2.2:8000${party['location']['place_image']}'),
            radius: 25,
          ),
          title: Text(party['name'] ?? 'Unnamed Party',style: TextStyle(color: Colors.white),),
          subtitle: Text(
              'สถานที่:${party['location']['location_name'] ?? 'Unknown place'}\nวันนัดหมาย:${party['date']}',style: TextStyle(color: const Color.fromARGB(255, 125, 125, 125)),),
          trailing: const Icon(Icons.arrow_forward,color: const Color.fromARGB(255, 125, 125, 125),),
          onTap: () async {
            // Navigate to party detail page
            final prefs =
                await SharedPreferences.getInstance(); // ดึง SharedPreferences
            final userId = prefs.getString('userid');
            print(
                'Leader ID: "${party['leader']}" (${party['leader'].runtimeType})');
            print('User ID: "$userId" (${userId.runtimeType})');
            print(
                'Is Leader: ${party['leader']?.toString().trim() == userId?.toString().trim()}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PartyDetailScreen(
                  party: party,
                  isLeader: party['leader'] == userId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PartyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> party;
  final bool isLeader;

  const PartyDetailScreen(
      {super.key, required this.party, required this.isLeader});

  @override
  _PartyDetailScreenState createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  late Map<String, dynamic> party;
  List<Map<String, dynamic>> members = [];
  String? status;
  late bool isLeader;
  late Map<String, dynamic> memberevent;
  bool hasEvent = false;

  @override
  void initState() {
    super.initState();
    party = widget.party;
    isLeader = widget.isLeader;
    fetchMembers();
    if (isLeader != true) {
      getmemberevent();
    }
    get_partystatus();
  }

  Future<void> fetchMembers() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = party['id'];

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthmember/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'partyid': partyId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data =
          json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      print('สมาชิก:${data}');
      setState(() {
        members = data.map((item) => item as Map<String, dynamic>).toList();
      });
    } else {
      throw Exception('Failed to fetch members: ${response.statusCode}');
    }
  }

  void _inviteMember() {
    setState(() {
      members.add({'name': 'New Member'});
    });
  }

  void _removeMember(int index) {
    setState(() {
      members.removeAt(index);
    });
  }

  Future<void> getmemberevent() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8000/Smartwityouapp/getmemberevent/${party['id']}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? '',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          memberevent = data;
          hasEvent = memberevent.isNotEmpty; // ✅ อัปเดตสถานะว่ามีนัดหมายหรือไม่
        });

        print('memberevientที่ส่งมา:${memberevent}');
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  Future<void> _updateMemberEvent() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');

    try {
      final response = await http.put(
        Uri.parse(
            'http://10.0.2.2:8000/Smartwityouapp/updatememberevent/${party['id']}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? '',
        },
        body: json.encode({
          'title': party['name'],
          'location': party['location']['location_name'],
          'description': party['description'],
          'date': party['date'],
          'start_time': party['start_time'],
          'finish_time': party['finish_time'],
        }),
      );

      if (response.statusCode == 200) {
        print("✅ อัปเดตสำเร็จ: ${response.body}");
        getmemberevent(); // ✅ โหลดข้อมูลใหม่
      } else {
        print("❌ อัปเดตล้มเหลว: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ ERROR: $e");
    }
  }

  Future<void> add_to_calendar() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/addtocalendar/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'userId': userId ?? '',
            'partyId': party['id'].toString(),
          },
          body: jsonEncode({
            'title': party['name'],
            'location': party['location']['location_name'],
            'description': party['description'],
            'date': party['date'],
            'start_time': party['start_time'],
            'finish_time': party['finish_time'],
          }));
      final data = jsonDecode(response.body);
      print('ค่าที่ส่งมา:${data}');
      if (response.statusCode == 401 && data.containsKey("auth_url")) {
        String authUrl = data["auth_url"];
        print("🔹 Google Auth URL: $authUrl");
        await launchUrl(Uri.parse(authUrl));
      }
      if (response.statusCode == 200) {
        print('เพิ่มนัดหมายเเล้ว');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('เพิ่มนัดหมสยเเล้ว!')));
      } else {
        print('Error:${response.statusCode}');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ไม่สำเร็จ!')));
      }
    } catch (e) {
      print('${e}');
    }
  }

  Future<void> Delete_party() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/deleteparty/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'userId': userId ?? '',
        'party': widget.party['id'].toString()
      },
    );
    if (response.statusCode == 200) {
      print('ลบปาร์ตี้เเล้ว');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ลบปาร์ตี้เเล้ว!')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // ลบ Stack ทั้งหมด
      );
    } else {
      print('Error:${response.statusCode}');
      print('ลบปาร์ตี้ไม่สำเร็จ');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ลบปาร์ตี้ไม่สำเร็จ!')));
    }
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthfriends/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'userId': userId ?? ''
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      print('เพื่อน${data}');
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to fetch friends');
    }
  }

  void _showFriendListPopup() async {
    List<Map<String, dynamic>> friends =
        await fetchFriends(); // ดึงรายชื่อเพื่อน

   showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: const Text("เพิ่มสมาชิก", style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[850], // สีเทาเข้ม
      content: friends.isEmpty
          ? const Text(
              "คุณไม่มีเพื่อนที่สามารถเชิญได้",
              style: TextStyle(color: Colors.white),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return Card(
                    color: Colors.grey[700], // สีของ Card
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // ขอบมน
                    ),
                    elevation: 3, // แรเงา
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      leading: CircleAvatar(
                        backgroundImage: friend['frined_profile'] != null
                            ? NetworkImage(
                                'http://10.0.2.2:8000/${friend['frined_profile']}')
                            : null,
                        child: friend['frined_profile'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                        backgroundColor: Colors.grey,
                      ),
                      title: Text(
                        friend['friend_username'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () async {
                          print('${party['id']}');
                          Sendinvitation(friend['friend_user'], party['id']);
                          Navigator.pop(context); // ปิด Dialog หลังเชิญ
                          fetchMembers(); // รีเฟรชรายชื่อสมาชิก
                        },
                        icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                        label: const Text("เชิญ"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ปิด", style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  },
);

  }

  void _goexercise() async {
    if (isLeader) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CheckInLeaderPage(
                    latitude: double.tryParse(
                            party['location']['latitude'].toString()) ??
                        0.0,
                    longitude: double.tryParse(
                            party['location']['longitude'].toString()) ??
                        0.0,
                    party: party,
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (conext) => CheckInPage(
                    party: party,
                    latitude: double.tryParse(
                            party['location']['latitude'].toString()) ??
                        0.0,
                    longitude: double.tryParse(
                            party['location']['longitude'].toString()) ??
                        0.0,
                  )));
    }
    if (!isLeader) {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? userId = prefs.getString('userid');
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/notitomeber/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'userId': userId ?? '',
            'partyId': party['id'].toString()
          },
        );
        if (response.statusCode == 200) {
          print('สงการเเจ้งเตือนสำเร็จ');
        } else {
          print('Error:${response.statusCode}');
        }
      } catch (e) {
        print('Error:${e}');
      }
    }
  }

  Future<void> get_partystatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/check_status/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': party['id'].toString(),
          'leader': party['leader']
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('statusของparty${data}');
        setState(() {
          status = data;
        });
      } else {
        print('Error:${response.statusCode}');
      }
    } catch (e) {
      print('Error${e}');
    }
  }

  void _startWorkout() async {
    // 1️⃣ ส่งแจ้งเตือนไปยังสมาชิก
    await sendNotificationToMembers();

    // 2️⃣ อัปเดตสถานะของปาร์ตี้เป็น "กำลังดำเนินการ"
    await updatePartyStatus();

    // 3️⃣ นำไปสู่หน้าสำหรับ Check-in
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CheckInScreen(partyId: party['id'])));
  }

  Future<void> sendNotificationToMembers() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/send_notification/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "party_id": party['id'],
        "message": "ปาร์ตี้ออกกำลังกายของคุณกำลังจะเริ่มต้นแล้ว! กรุณาเช็คอิน",
      }),
    );

    if (response.statusCode == 200) {
      print("📢 การแจ้งเตือนถูกส่งเรียบร้อยแล้ว");
    } else {
      print("❌ ไม่สามารถส่งการแจ้งเตือนได้");
    }
  }

  Future<void> updatePartyStatus() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/update_party_status/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "party_id": party['id'],
        "status": "กำลังดำเนินการ",
      }),
    );

    if (response.statusCode == 200) {
      print("✅ ปาร์ตี้เริ่มต้นแล้ว!");
    } else {
      print("❌ อัปเดตปาร์ตี้ล้มเหลว");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(party['name'] ?? 'Unnamed Party',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      backgroundColor: const Color.fromARGB(255, 39, 38, 38),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปภาพของสถานที่
            if (isLeader) ...[
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Delete_party();
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('ลบปาร์ตี้'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            SizedBox(
              height: 16,
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  'http://10.0.2.2:8000${party['location']['place_image']}',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                _goexercise();
              },
              icon: Icon(Icons.play_arrow, color: Colors.white),
              label: Text(isLeader ? 'ตรวจสอบการเช็คอิน' : 'ไปหน้าเช็คอิน'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLeader ? Colors.orange : Colors.blue, // สีต่างกันตามบทบาท
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16.0),
            _buildPartyDetail(Icons.fitness_center,
                'ประเภท: ${party['exercise_type']['name'] ?? 'Unknown'}'),
            _buildPartyDetail(Icons.place,
                'สถานที่: ${party['location']['location_name'] ?? 'Unknown place'}'),
            _buildPartyDetail(Icons.date_range, 'วันนัดหมาย: ${party['date']}'),
            _buildPartyDetail(Icons.access_time,
                'เวลา: ${party['start_time']} - ${party['finish_time']}'),
            _buildPartyDetail(Icons.description,
                'คำอธิบาย: ${party['description'] ?? "ไม่มี"}'),
            const SizedBox(height: 16.0),

            // ปุ่มสำหรับ Leader เท่านั้น
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isLeader) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EditPartyScreen(party: party)));
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('เเก้ไขปาร์ตี้',
                          style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8), // ระยะห่างระหว่างปุ่ม

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!hasEvent) {
                        await add_to_calendar();
                      } else {
                        await _updateMemberEvent();
                      }
                      getmemberevent(); // ✅ โหลดข้อมูลใหม่เพื่ออัปเดต UI
                    },
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    label: Text(hasEvent ? 'อัปเดตนัดหมาย' : 'เพิ่มนัดหมาย',
                        style: const TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasEvent ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // ระยะห่างระหว่างปุ่ม

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print(
                          'ประเภทของลิติจูด:${party['location']['latitude'].runtimeType}');
                      print(
                          'ประเภทของลองทิจูด:${party['location']['longitude'].runtimeType}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PartyMapScreen(
                            latitude: double.tryParse(
                                    party['location']['latitude'].toString()) ??
                                0.0,
                            longitude: double.tryParse(party['location']
                                        ['longitude']
                                    .toString()) ??
                                0.0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: const Text(
                      'สถานที่ออก',
                      style: TextStyle(fontSize: 10),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // สีปุ่มให้เหมาะกับ UI
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // ส่วนแสดงจำนวนสมาชิก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('สมาชิก ',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white)),
                    const Icon(Icons.people, size: 18,color: Colors.white),
                    Text(' ${members.length}',
                        style: const TextStyle(fontSize: 18,color: Colors.white)),
                  ],
                ),
                if (isLeader)
                  IconButton(
                      icon: const Icon(Icons.person_add,
                          color: Colors.orange, size: 30),
                      onPressed: _showFriendListPopup),
              ],
            ),
            const SizedBox(height: 8.0),

            // รายชื่อสมาชิก
            members.isEmpty?
            Center(
               child: const Text('ไม่มีสมาชิก', style: TextStyle(color: Colors.white)),
            ):
            Column(
              children: members.map((member) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member['profile_image'] != null
                          ? NetworkImage(
                              'http://10.0.2.2:8000/${member['profile_image']}')
                          : null,
                      child: member['profile_image'] == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white,
                            )
                          : null,
                      backgroundColor: Colors.grey,
                    ),
                    title: Text(member['username'] ?? 'Unknown'),
                    trailing: isLeader
                        ? TextButton(
                            onPressed: () async {
                              print(member['memberId'].runtimeType);
                              _removeMember(members.indexOf(member));
                              await removemember(member['memberId']);
                            },
                            child: const Text('ลบ',
                                style: TextStyle(color: Colors.red)),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16.0),

            // ปุ่มออกจากปาร์ตี้
            ElevatedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                String? userId = prefs.getString('userid');
                bool success = await leaveparty(party['id'], userId ?? '');
                if (success) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            HomePage()), // เปลี่ยนเป็นหน้าที่ต้องการกลับไป
                    (route) => false, // ลบ stack ทั้งหมด
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to leave the party")),
                  );
                }
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Party'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class EditPartyScreen extends StatefulWidget {
  final Map<String, dynamic> party;

  const EditPartyScreen({super.key, required this.party});

  @override
  _EditPartyScreenState createState() => _EditPartyScreenState();
}

class _EditPartyScreenState extends State<EditPartyScreen> {
  late TextEditingController nameController;
  late TextEditingController startTimeController;
  late TextEditingController finishTimeController;
  late TextEditingController dateController;
  String? selectedExercise;
  int? selectedExerciseId;
  Map<String, dynamic>? selectedLocation;
  List<Map<String, dynamic>> exerciseOptions = [];
  List<Map<String, dynamic>> locationOptions = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.party['name']);
    startTimeController =
        TextEditingController(text: widget.party['start_time']);
    finishTimeController =
        TextEditingController(text: widget.party['finish_time']);
    dateController = TextEditingController(text: widget.party['date']);

    selectedExercise = widget.party['exercise_type']['id'].toString();

    if (widget.party['location'] is Map<String, dynamic>) {
      selectedLocation = widget.party['location'];
    } else {
      selectedLocation = null;
    }
    print('ปาร์ตี้Id:${widget.party['id']}');
    fetchExerciseOptions();
    fetchLocationOptions();
    print('ข้อมูลปาร์ตี้:${widget.party}');
  }

  Future<void> fetchExerciseOptions() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fechworkout/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      print('ประเภท:${data}');
      setState(() {
        exerciseOptions = data
            .map((item) => {'id': item['id'], 'name': item['name']})
            .toList();
      });
      print('exerciseOptions${exerciseOptions}');
    }
  }

  /// ✅ ดึงข้อมูลสถานที่
  Future<void> fetchLocationOptions() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fechlocations/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        locationOptions =
            data.map((item) => item as Map<String, dynamic>).toList();
      });
    }
  }

  Future<void> _selectDay(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd')
            .format(picked); // แปลงวันที่เป็น YYYY-MM-DD
      });
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final formattedTime = DateFormat('HH:mm:ss').format(
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
        );
        controller.text = formattedTime; // แสดงเวลาในช่องกรอก
      });
    }
  }

  void _showLocationPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("เลือกสถานที่"),
          content: locationOptions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: locationOptions.length,
                    itemBuilder: (context, index) {
                      final location = locationOptions[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: location['place_image'] != null
                                ? NetworkImage(
                                    'http://10.0.2.2:8000${location['place_image']}')
                                : null,
                            child: location['place_image'] == null
                                ? const Icon(Icons.place, color: Colors.white)
                                : null,
                            backgroundColor: Colors.grey,
                          ),
                          title: Text(location['location_name']),
                          onTap: () {
                            setState(() {
                              selectedLocation = location;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ปิด")),
          ],
        );
      },
    );
  }

  /// ✅ อัปเดตปาร์ตี้
  Future<void> updateParty() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final int partyId = widget.party['id']; // ดึง party_id จาก widget

    final url = Uri.parse(
        'http://10.0.2.2:8000/Smartwityouapp/updateparty/$partyId/'); // ✅ เพิ่ม party_id ใน URL

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'name': nameController.text,
        'exercise_type': selectedExercise,
        'location': selectedLocation != null ? selectedLocation!['id'] : null,
        'date': dateController.text,
        'start_time': startTimeController.text,
        'finish_time': finishTimeController.text,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomePage()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัพเดตปาร์ตี้เเล้ว')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update party')),
      );
      print("Error updating party: ${response.body}"); // ✅ แสดง error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('แก้ไขปาร์ตี้'),backgroundColor: Colors.orange,),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              style: TextStyle(color: Colors.white),
              controller: nameController,
              decoration: InputDecoration(labelText: 'ชื่อปาร์ตี้',labelStyle: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              dropdownColor:const Color.fromARGB(255, 39, 38, 38),
              value: selectedExercise,
              items: exerciseOptions.map((exercise) {
                return DropdownMenuItem(
                    
                    value: exercise['id'].toString(),
                    child: Text(exercise['name'],style: TextStyle(color: Colors.white)));
              }).toList(),
              onChanged: (value) => setState(() => selectedExercise = value),
              decoration: InputDecoration(labelText: 'ประเภทการออกกำลังกาย',labelStyle: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 10),

            // ปุ่มกดเลือกสถานที่
            Text('สถานที่:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
            GestureDetector(
              onTap: _showLocationPopup,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: Colors.orange,),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(selectedLocation?['location_name'] ??
                            'เลือกสถานที่'),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 10),

            // ปุ่มเลือกเวลา
            ListTile(
                title: Text('วันนัดหมาย:${dateController.text}',style: TextStyle(color: Colors.white),),
                trailing: Icon(Icons.calendar_month,color: Colors.orange,),
                onTap: () => _selectDay(context, dateController)),

            ListTile(
              title: Text('เวลาเริ่มต้น: ${startTimeController.text}',style: TextStyle(color: Colors.white),),
              trailing: Icon(Icons.access_time,color: Colors.orange,),
              onTap: () => _selectTime(context, startTimeController),
            ),
            ListTile(
              title: Text('เวลาสิ้นสุด: ${finishTimeController.text}',style: TextStyle(color: Colors.white),),
              trailing: Icon(Icons.access_time,color: Colors.orange,),
              onTap: () => _selectTime(context, finishTimeController),
            ),

            SizedBox(height: 50),
           Center(
            child:  ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange
                ),
                onPressed: updateParty, label: Text('บันทึกการเปลี่ยนแปลง',style: TextStyle(color: Colors.white,fontSize: 16),),icon: Icon(Icons.save,color: Colors.grey,),),
           )
          ],
        ),
      ),
      backgroundColor:  const Color.fromARGB(255, 39, 38, 38),
    );
  }
}
