import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CheckInScreen extends StatefulWidget {
  final int partyId;

  CheckInScreen({required this.partyId});

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool hasCheckedIn = false;

  Future<void> _checkIn() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/check_in/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "party_id": widget.partyId,
         // ดึง user_id ของผู้ใช้ปัจจุบัน
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Check-in สำเร็จ!");
      setState(() {
        hasCheckedIn = true; // อัปเดต UI ให้แสดงว่า Check-in แล้ว
      });
    } else {
      print("❌ Check-in ล้มเหลว");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Check-in")),
      body: Center(
        child: hasCheckedIn
            ? Text("✅ คุณเช็คอินแล้ว!", style: TextStyle(fontSize: 20, color: Colors.green))
            : ElevatedButton.icon(
                onPressed: _checkIn,
                icon: Icon(Icons.check, color: Colors.white),
                label: Text('Check-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
      ),
    );
  }
}

