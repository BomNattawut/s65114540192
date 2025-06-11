import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myflutterproject/scr/workoutpage.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CheckInPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Map<String, dynamic> party;

  const CheckInPage(
      {Key? key,
      required this.latitude,
      required this.longitude,
      required this.party})
      : super(key: key);

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late GoogleMapController mapController;
  LocationData? currentLocation;
  bool isNear = false;
  List<Map<String, dynamic>> checkedInMembers = [];
  Timer? _timer;
  late bool checkin_status = false;
  late bool partystart;
  @override
  void initState() {
    super.initState();
    requestLocationPermission();
    fetchcheckinMembers();
    fecthstatuscheckin();
    _startAutoUpdate();
  }

  void _startAutoUpdate() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      fetchcheckinMembers();
      getCurrentLocation();
      fecthstatuscheckin();
      _checkpartystatus();
      _GotoWorkout();
    });
  }

  Future<void> fetchcheckinMembers() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthchrckinmember/'),
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
        checkedInMembers =
            data.map((item) => item as Map<String, dynamic>).toList();
      });
    } else {
      throw Exception('Failed to fetch members: ${response.statusCode}');
    }
  }

  Future<bool> requestLocationPermission() async {
    perm.PermissionStatus status = await perm.Permission.location.request();
    if (status == perm.PermissionStatus.granted) {
      getCurrentLocation();
      return true;
    } else {
      return false;
    }
  }

  void _GotoWorkout() async {
    if (partystart == true) {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userid');
      print('เริ่มออกำลังกายเเล้ว');
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => WorkoutCountdownPage(
                    party: widget.party,
                    isLeader: widget.party['leader'] == userId,
                  )));
    } else {
      print('ยังไม่เริ่มออกำลังกาย');
    }
  }

  Future<void> getCurrentLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();
    print("📌 ตำแหน่งเป้าหมาย: ${widget.latitude}, ${widget.longitude}");
    print(
        "📍 ตำแหน่งปัจจุบัน: ${locationData.latitude}, ${locationData.longitude}");
    setState(() {
      currentLocation = locationData;
    });
    checkProximity();
  }

  void checkProximity() {
    if (currentLocation == null) return;

    double distance = calculateDistance(
      widget.latitude,
      widget.longitude,
      currentLocation!.latitude!,
      currentLocation!.longitude!,
    );

    setState(() {
      isNear = distance <= 0.25;
    });
    print('คำนวณระยะอยู่');
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = (0.5 - (cos(dLat) / 2)) +
        (cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * (1 - cos(dLon)) / 2);
    return R * 2 * asin(sqrt(a));
  }

  void _checkpartystatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      int? partyId = widget.party['id'];

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/getpartystatus/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          if (data == 'ongoing') {
            partystart = true;
            print("สถานะของปาร์ตี้${partystart}");
          } else {
            partystart = false;
            print("สถานะของปาร์ตี้${partystart}");
          }
        });
      } else {
        print('Error${response.statusCode}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  void _checkIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      int? partyId = widget.party['id'];
      String? userId = prefs.getString('userid');
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/checkinparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        print('${response.body}');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("✅ เช็คอินสำเร็จ!")));
      } else {
        print('${response.statusCode}');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("เช็คอินไม่สำเร็จ!")));
      }
    } catch (e) {}
  }

  Future<void> fecthstatuscheckin() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/checkinstatus/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print({'สถานนะcheckin:${data}'});
        setState(() {
          checkin_status = data;
        });
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  Future<void> cancelCehckin() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    String? userId = prefs.getString('userid');
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/cencelcheckin/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        print('ยกเลิกเช็คอินสถานที่เเล้ว');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("✅ ยกเลิกเช็คอินเเล้ว!")));
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🔥 ยกเลิก Timer ก่อนออกจากหน้า
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LatLng partyLocation = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text("เช็คอินเข้าปาร์ตี้"),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[800],
      body: Column(
        children: [
          // ✅ ส่วนที่ 1: Google Maps ด้านบนสุด
          Container(
            height: 250,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: partyLocation,
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: {
                Marker(
                  markerId: MarkerId("partyLocation"),
                  position: partyLocation,
                  infoWindow: InfoWindow(title: "จุดนัดหมาย"),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                getCurrentLocation();
              },
            ),
          ),

          // ✅ ส่วนที่ 2: ข้อมูลปาร์ตี้
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📍 สถานที่: ${widget.party['location']['location_name']}",
                    style: GoogleFonts.notoSansThai(
                        textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))),
                Text("🏋️‍♂️ ปาร์ตี้: ${widget.party['name']}",
                    style: GoogleFonts.notoSansThai(
                        textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))),
                SizedBox(height: 10),
                isNear
                    ? Text("✅ คุณสามารถเช็คอินได้!",
                        style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.green, fontSize: 16)))
                    : Text("📌 คุณต้องเช็คอินภายใน 10 เมตร!",
                        style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.red, fontSize: 16))),
                SizedBox(height: 10),
              ],
            ),
          ),
 Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
          // ✅ ส่วนที่ 3: รายการสมาชิกที่เช็คอินแล้ว
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              color: Colors.grey[800],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👥 สมาชิกที่เช็คอินแล้ว:",
                      style: GoogleFonts.notoSansThai(
                          textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white))),
                  checkedInMembers.isEmpty
                      ? Center(
                          child: Text('ไม่มีสมาชิกเช็คอินตอนี้'),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: checkedInMembers.length,
                            itemBuilder: (context, index) {
                              var member = checkedInMembers[index];
                              return ListTile(
                                  leading: member["checkin_status"]
                                      ? Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : Icon(Icons.hourglass_empty,
                                          color: Colors.orange),
                                  title: Text(member["username"],
                                      style: GoogleFonts.notoSansThai(
                                          textStyle: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white))),
                                  subtitle: member["checkin_status"]
                                      ? Text("✅ เช็คอินแล้ว",
                                          style: GoogleFonts.notoSansThai(
                                              textStyle: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green)))
                                      : Text(
                                          "⏳ ยังไม่เช็คอิน",
                                          style: GoogleFonts.notoSansThai(
                                            textStyle: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                        ));
                            },
                          ),
                        )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.grey),
          ),
          // ✅ ปุ่ม Check-in แสดงเมื่อผู้ใช้ถึงสถานที่
          if (isNear && checkin_status == false)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _checkIn,
                icon: Icon(Icons.check, color: Colors.white),
                label: Text("เช็คอินที่จุดหมาย"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          if (checkin_status == true)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: cancelCehckin,
                icon: Icon(Icons.check, color: Colors.white),
                label: Text("ยกเลิกเช็คอิน"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          // ✅ แจ้งเตือนถ้ายังไม่ถึงสถานที่
          if (!isNear && currentLocation != null)
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.redAccent.withOpacity(0.8),
              child: Text(
                "❌ คุณยังไม่ถึงสถานที่ เช็คอินไม่ได้",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class CheckInLeaderPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Map<String, dynamic> party;

  const CheckInLeaderPage({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.party,
  }) : super(key: key);

  @override
  State<CheckInLeaderPage> createState() => _CheckInLeaderPageState();
}

class _CheckInLeaderPageState extends State<CheckInLeaderPage> {
  late GoogleMapController mapController;
  List<Map<String, dynamic>> checkedInMembers = [];
  bool allCheckedIn = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchcheckinMembers();
    _startAutoUpdate(); // ✅ อัปเดตสถานะสมาชิกอัตโนมัติ
  }

  // ✅ อัปเดตสถานะเช็คอินของสมาชิกทุก 10 วินาที
  void _startAutoUpdate() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchcheckinMembers();
    });
  }

  // ✅ ดึงข้อมูลสมาชิกที่เช็คอินแล้วจาก API
  Future<void> fetchcheckinMembers() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthchrckinmember/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'partyId': partyId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data =
          json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      print('สมาชิก:${data}');
      setState(() {
        checkedInMembers =
            data.map((item) => item as Map<String, dynamic>).toList();
      });
      allCheckedIn = checkedInMembers.isNotEmpty &&
          checkedInMembers.every((member) => member["checkin_status"] == true);
      print('สมาชิกที่เช็คอิน:${checkedInMembers}');
    } else {
      throw Exception('Failed to fetch members: ${response.statusCode}');
    }
  }

  // ✅ Leader กด "เริ่มออกกำลังกาย" ได้เมื่อทุกคนเช็คอินครบ
  Future<void> startWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    String? userId = prefs.getString('userid');

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/startworkout/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'partyId': partyId.toString(),
        'userId': userId ?? ''
      },
    );

    if (response.statusCode == 200) {
      print("🚀 ปาร์ตี้เริ่มออกกำลังกายแล้ว!");
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userid');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => WorkoutCountdownPage(
                  party: widget.party,
                  isLeader: widget.party['leader'] == userId,
                )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ ไม่สามารถเริ่มออกกำลังกายได้")),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ หยุดอัปเดตเมื่อออกจากหน้า
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LatLng partyLocation = LatLng(widget.latitude, widget.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text("👑 เช็คอิน"),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[800],
      body: Column(
        children: [
          // ✅ ส่วนที่ 1: Google Maps ด้านบนสุด
          Container(
            height: 250,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: partyLocation,
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: {
                Marker(
                  markerId: MarkerId("partyLocation"),
                  position: partyLocation,
                  infoWindow: InfoWindow(title: "จุดนัดหมาย"),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
          ),

          // ✅ ส่วนที่ 2: ข้อมูลปาร์ตี้
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📍 สถานที่: ${widget.party['location']['location_name']}",
                    style: GoogleFonts.notoSansThai(
                        textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))),
                Text("🏋️‍♂️ ปาร์ตี้: ${widget.party['name']}",
                    style: GoogleFonts.notoSansThai(
                        textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))),
                SizedBox(height: 10),
                Text(
                  "👀 ติดตามสถานะสมาชิก...",
                  style: GoogleFonts.notoSansThai(
                      textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.grey),
          ),
          // ✅ ส่วนที่ 3: รายการสมาชิกที่เช็คอินแล้ว

          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              color: Colors.grey[800],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "👥 สถานะสมาชิก:",
                    style: GoogleFonts.notoSansThai(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 12), // ✅ เว้นระยะหัวข้อ

                  // ✅ เงื่อนไขแสดงรายชื่อหรือไม่
                  checkedInMembers.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'ไม่มีสมาชิคเช็คอิน',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: checkedInMembers.length,
                            itemBuilder: (context, index) {
                              var member = checkedInMembers[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero, // ✅ ชิดซ้าย
                                leading: member["checkin_status"]
                                    ? Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : Icon(Icons.hourglass_empty,
                                        color: Colors.orange),
                                title: Text(
                                  member["username"],
                                  style: GoogleFonts.notoSansThai(
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                subtitle: member["checkin_status"]
                                    ? Text(
                                        "✅ เช็คอินแล้ว",
                                        style: GoogleFonts.notoSansThai(
                                          textStyle: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        "⏳ ยังไม่เช็คอิน",
                                        style: GoogleFonts.notoSansThai(
                                          textStyle: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Divider(color: Colors.grey),
          ),
          // ✅ ปุ่มเริ่มออกกำลังกาย (แสดงเฉพาะเมื่อสมาชิกเช็คอินครบ)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: allCheckedIn ? startWorkout : null,
              icon: Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                allCheckedIn ? "🚀 เริ่มออกกำลังกาย" : "⏳ สมาชิกยังมาไม่ครบ",
                style: GoogleFonts.notoSansThai(
                    textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                textStyle: TextStyle(fontSize: 18),
                backgroundColor: allCheckedIn ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
