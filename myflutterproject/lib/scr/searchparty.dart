import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myflutterproject/scr/createparty.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/joinparty.dart';

class Searchparty extends StatefulWidget {
  const Searchparty({super.key});

  @override
  State<Searchparty> createState() => _SearchpartyState();
}

class _SearchpartyState extends State<Searchparty> {
  int _currentindex = 0;
  List<Map<String, dynamic>> parties = [];
  List<Map<String, dynamic>> filteredParties = [];
  List<String> partyTypes = ["All"];
  String selectedType = "All";
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchAllParties();
    fetchPartyTypes();
  }

  Future<void> fetchAllParties() async {
    // ตัวอย่างข้อมูลจำลอง
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? userId = prefs.getString('userid');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthallparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userid': userId ?? ''
          // ตรวจสอบว่ามี userId หรือไม่
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        print('party:$data');
        setState(() {
          parties = data.map((item) => item as Map<String, dynamic>).toList();
        });
        filteredParties = parties;
      }
    } catch (e) {
      throw Exception('Failed to fetch  parties');
    }
  }

  Future<void> fetchPartyTypes() async {
    try {
      // ตัวอย่างประเภทการออกกำลังกาย
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fechworkout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        print('party:$data');
        setState(() {
          partyTypes.addAll(
              data.map<String>((item) => item['name'].toString()).toList());
        });
      }
    } catch (e) {
      throw Exception('Failed to partytypes');
    }
  }

  Future<void> filterparty(String filter) async {
    setState(() {
      selectedType = filter;
    });
    if (selectedType == 'All') {
      setState(() {
        filteredParties = parties;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/filterparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'type': selectedType}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)) as List;
        print('ข้อมูลที่ส่งมา:$data');
        setState(() {
          filteredParties =
              data.map((item) => item as Map<String, dynamic>).toList();
        });
      } else {
        print('Error:${response.statusCode}');
      }
    }
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
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Searchparty()));
    }
  }
  Future<void>fillterwithscore()async{
    try{
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthTopparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode==200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        print('party:$data');
        setState(() {
          parties = data.map((item) => item as Map<String, dynamic>).toList();
        });
        filteredParties = parties;
      }
      else {
         print('Error:${response.bodyBytes}');
      }
    }
    catch (e){
      print('Error:${e}');
    }
    
  }
  Future<void> searchParty(String query) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');

  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/searchparty/?query=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      print('🔹 ผลลัพธ์การค้นหา: $data');
      setState(() {
          parties = data.map((item) => item as Map<String, dynamic>).toList();
        });
        filteredParties = parties;
      // อัปเดตรายการปาร์ตี้ที่ค้นหาได้
      
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ไม่พบรายการที่ค้นหา')));
      print("❌ ค้นหาไม่สำเร็จ: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ เกิดข้อผิดพลาด: $e");
  }
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title:  Text("ค้นหาปาร์ตี้",style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),),
      backgroundColor: Colors.orange,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 🔹 TextField พร้อมปุ่มค้นหา
          TextField(
  onChanged: (value) {
    searchQuery = value;
  },
  onSubmitted: (value) {
    searchParty(searchQuery); // ทำให้กด Enter แล้วค้นหาได้
  },
  style: const TextStyle(color: Colors.white),
  decoration: InputDecoration(
    labelText: "ค้นหาปาร์ตี้",
    labelStyle: const TextStyle(color: Colors.white),
    prefixIcon: const Icon(Icons.search, color: Colors.orange), // ✅ เหลือไอคอนเดียว
    filled: true,
    fillColor: Colors.grey[800],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: Colors.grey.shade700, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.orange, width: 2.0),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  ),
),
          const SizedBox(height: 16),
          
          // 🔹 ปุ่มกดค้นหาแบบกดเอง
          ElevatedButton.icon(
            onPressed: () {
               searchParty(searchQuery);
            },
            icon: Icon(Icons.search),
            label: Text('ค้นหาปาร์ตี้',style: GoogleFonts.notoSansThai(textStyle: TextStyle(
              fontSize: 18,
              color: const Color.fromARGB(255, 255, 255, 255),
              fontWeight: FontWeight.w500,
            ),)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 ปุ่มกรองปาร์ตี้ที่มีคะแนนสูงสุด
          ElevatedButton.icon(
            onPressed: () {
              fillterwithscore();
            },
            label: Text('ปาร์ตี้ที่มีคะแนนสูงสุด'),
            icon: Icon(Icons.star,color: Colors.yellow,),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400]
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Dropdown สำหรับกรองตามประเภทปาร์ตี้
         DropdownButtonFormField<String>(
  value: selectedType,
  isExpanded: true,
  dropdownColor: Colors.grey[900], // เปลี่ยนสีพื้นหลังของตัวเลือก
  icon: const Icon(Icons.arrow_drop_down, color: Colors.orange, size: 30), // เปลี่ยนไอคอนลูกศร
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.grey[800], // เปลี่ยนสีพื้นหลังของ dropdown
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15), // ทำให้โค้งมน
      borderSide: BorderSide.none, // ไม่มีเส้นขอบปกติ
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade700, width: 1.5), // สีขอบปกติ
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.orange, width: 2.0), // สีขอบเมื่อเลือก
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // ขยายพื้นที่ให้ดูสวยขึ้น
  ),
  style: const TextStyle(color: Colors.white, fontSize: 16), // เปลี่ยนสีตัวอักษรใน Dropdown
  items: partyTypes.map((type) {
    return DropdownMenuItem(
      value: type,
      child: Text(type, style: const TextStyle(color: Colors.white)), // เปลี่ยนสีตัวอักษรของตัวเลือก
    );
  }).toList(),
  onChanged: (value) {
    if (value != null) {
      filterparty(value);
    }
  },
),
SizedBox(height: 10,),
Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          // 🔹 แสดงรายการปาร์ตี้ที่ค้นหาได้
          Expanded(
            child: 
            filteredParties.isEmpty?
            Column(
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
           Text(
            'ไม่มีผลลัพท์',
            style: GoogleFonts.notoSansThai(textStyle: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),)
          ),
        ],
      ):
            ListView.builder(
              itemCount: filteredParties.length,
              itemBuilder: (context, index) {
                final party = filteredParties[index];
                return Card(
                  child: Column(
                    children: [
                      // 🔹 เพิ่มรูปภาพของปาร์ตี้
                      party['location'] != null &&
                              party['location'] is Map &&
                              party['location']['place_image'] != null
                          ? Image.network(
                              'http://10.0.2.2:8000${party['location']['place_image']}',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/placeholder.png', // กรณีไม่มีรูป
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                      ListTile(
                        title: Text(party['name']),
                        subtitle: Text(
                            "workout: ${party['exercise_type'] != null && party['exercise_type'] is Map ? party['exercise_type']['name'] : 'ไม่ระบุ'}\n"
                            "สถานที่: ${party['location'] != null && party['location'] is Map ? party['location']['location_name'] : 'ไม่ระบุ'}\n"
                            "${party['date'] ?? 'ไม่ระบุ'}"),
                        onTap: () {
                          print('ค่าที่สงไปหน้าเข้าร่วม$party');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Joinparty(selectparty: party),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    backgroundColor:Colors.grey[800],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentindex,
      onTap: _onBottomNavTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.add), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
      ],
      backgroundColor: Colors.white,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.black,
    ),
  );
}
}
