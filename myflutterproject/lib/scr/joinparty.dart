import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/refresh_token.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:myflutterproject/scr/Home.dart';

class Joinparty extends StatefulWidget {
  final Map<String, dynamic> selectparty;

  const Joinparty({super.key, required this.selectparty});

  @override
  State<Joinparty> createState() => _JoinpartyState();
}

class _JoinpartyState extends State<Joinparty> {
  List<Map<String, dynamic>> members = [];
  int membercount = 0;
  @override
  void initState() {
    super.initState();
    fecthmember();
  }

  Future<void> joinparty() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    final refreshToken = prefs.getString('refresh_token');
    print('user_id: $userId (${userId.runtimeType})');
    print(
        'party id: ${widget.selectparty['id']} (${widget.selectparty['id'].runtimeType})');
    print(
        'receiver id: ${widget.selectparty['leader']} (${widget.selectparty['leader'].runtimeType})');
    if (accessToken == null || accessToken.isEmpty) {
      accessToken = await refreshAccessToken(refreshToken!);
      if (accessToken != null) {
        await prefs.setString('access_token', accessToken);
      } else {
        print('Unable to refresh token');
        return;
      }
    }
    try {
      final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/joinparty/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            // ตรวจสอบว่ามี userId หรือไม่
          },
          body: jsonEncode({
            'sender': userId,
            'party': widget.selectparty['id'],
            'receiver': widget.selectparty['leader']
          }));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ส่งคำขอเข้าร่วมเเล้ว')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), //เเก้ตรงนี้
          (route) => false, // ลบ Stack ทั้งหมด
        );
      } else {
        print("Error:${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> fecthmember() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    print('ประเภทของidที่ส่วไป${widget.selectparty['id'].runtimeType}');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthmember/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyid': jsonEncode(widget.selectparty['id'])
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List;
        print('ข้อมูลที่ส่งมา$data');
        setState(() {
          members = data.map((item) => item as Map<String, dynamic>).toList();
        });
        membercount = members.length + 1;
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Join Party',
              style: TextStyle(color: Colors.white),
            ),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                Text(
                  '$membercount', // แสดงจำนวนสมาชิกที่นับได้
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            )
          ],
        ),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: const Color.fromARGB(255, 45, 45, 45),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            children: [
              Center(
                child: Container(
                  height: 250, // เพิ่มขนาดของภาพให้เด่นขึ้น
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      'http://10.0.2.2:8000${widget.selectparty['location']['place_image']}',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.all(20.0), // เพิ่ม Padding ให้ดูโล่งขึ้น
                width: double.infinity, // ขยายให้เต็มความกว้างของหน้าจอ
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Party Name: ${widget.selectparty['name']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Exercise: ${widget.selectparty['exercise_type']['name']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Location: ${widget.selectparty['location']['location_name']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Date: ${widget.selectparty['date']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Time: ${widget.selectparty['start_time']} - ${widget.selectparty['finish_time']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.selectparty['description']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: joinparty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text(
                  "Join Party",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
