import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myflutterproject/scr/createparty.dart';
import 'package:myflutterproject/scr/Home.dart';

import 'package:myflutterproject/scr/notification.dart';
import 'package:myflutterproject/scr/viewlocation.dart';
import 'package:myflutterproject/scr/Freind.dart';

class Selecatlocationpage extends StatefulWidget {
  final String currentPartyName;
  final String currentPartyDate;
  final String currentStartTime;
  final String currentFinishTime;
  final String currentDescription; //เพิ่มตรงนี้
  const Selecatlocationpage({
    super.key,
    required this.currentPartyName,
    required this.currentPartyDate,
    required this.currentStartTime,
    required this.currentFinishTime,
    required this.currentDescription,
  }); //เพิ่มตรงนี้

  @override
  State<Selecatlocationpage> createState() => _SelecatlocationpageState();
}

class _SelecatlocationpageState extends State<Selecatlocationpage> {
  int _currentindex = 0;
  List<dynamic> locations = [];
  List<dynamic> filteredLocations = [];
  List<String> placetype = ["All"]; // เพิ่ม "All" เป็นตัวเลือกเริ่มต้น
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    fetchLocation(); // ดึงข้อมูลสถานที่
    fecthexercisPlaceetype(); // ดึงประเภทสถานที่
  }

  Future<void> fetchLocation() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fechlocations/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        locations = json.decode(utf8.decode(response.bodyBytes));
        print('ข้อมูลสถานที่:$locations');
        filteredLocations = locations;
      });
    } else {
      print('Failed to load locations: ${response.statusCode}');
    }
  }

  Future<void> fecthexercisPlaceetype() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fechexercisepalcetype/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        placetype.addAll(
            data.map<String>((item) => item['name'].toString()).toList());
      });
    } else {
      print('Failed to load place types: ${response.statusCode}');
    }
  }

  Future<void> filterLocations(String filter) async {
    setState(() {
      selectedFilter = filter;
    });

    // หากเลือก All ให้ใช้ข้อมูลทั้งหมดโดยไม่เรียก API
    if (filter == "All") {
      setState(() {
        filteredLocations = locations;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    print('ค่าในfliter:$selectedFilter');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/filter/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'type': selectedFilter}),
      );

      if (response.statusCode == 200) {
        // รับข้อมูลที่กรองจาก backend
        final List<dynamic> filteredData =
            json.decode(utf8.decode(response.bodyBytes));
        print('filterlocation:$filteredData');
        setState(() {
          filteredLocations = filteredData; // อัปเดตข้อมูล
        });
      } else {
        print('Failed to filter locations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error filtering locations: $e');
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentindex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MakePartyPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const notification()),
      );
    } else if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Freindpage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
    backgroundColor: Colors.orange,
    title: Text(
      "เลือกสถานที่",
      style: GoogleFonts.notoSansThai(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  backgroundColor: Color(0xFF1F1F1F),
  body: Column(
    children: [
      // Dropdown กรอง
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "กรองประเภทสถานที่:",
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedFilter,
              dropdownColor: Colors.grey[900],
              iconEnabledColor: Colors.amber,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
              ),
              style: GoogleFonts.notoSansThai(
                textStyle: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              items: placetype
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type,
                            style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) filterLocations(value);
              },
            ),
          ],
        ),
      ),

      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Divider(color: Colors.grey),
      ),
      const SizedBox(height: 10),

      // รายการสถานที่
      Expanded(
        child: filteredLocations.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : ListView.builder(
                itemCount: filteredLocations.length,
                itemBuilder: (context, index) {
                  final location = filteredLocations[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExercisePlaceDetail(
                            placeData: location,
                            currentPartyName: widget.currentPartyName,
                            currentPartyDate: widget.currentPartyDate,
                            currentStartTime: widget.currentStartTime,
                            currentFinishTime: widget.currentFinishTime,
                            currentDescription: widget.currentDescription,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                      child: Card(
                        color: Colors.grey[850],
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                              child: Image.network(
                                'http://10.0.2.2:8000${location['place_image']}',
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      location['location_name'],
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      location['opening_hours'] != null &&
                                              location['opening_hours'].isNotEmpty &&
                                              location['opening_hours'][0]['open_time'] != null &&
                                              location['opening_hours'][0]['close_time'] != null
                                          ? "เวลาเปิด-ปิด: ${location['opening_hours'][0]['open_time']} - ${location['opening_hours'][0]['close_time']}"
                                          : "เวลาเปิด-ปิดไม่ระบุ",
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "📍 ${location['address']}",
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      location['opening_hours'] != null &&
                                              location['opening_hours'].isNotEmpty &&
                                              location['opening_hours'][0]['status'] != null
                                          ? location['opening_hours'][0]['status']
                                          : "ไม่มีสถานะ",
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 14,
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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

  // ✅ Bottom Navigation Bar (ไม่เปลี่ยน แต่ให้กลืนกับธีม)
   bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentindex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create Party'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Search Party'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notification'),
        ],
      ),
);

  }
}
