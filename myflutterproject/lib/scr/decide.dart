import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JoinRequestsPage extends StatefulWidget {
  const JoinRequestsPage({Key? key}) : super(key: key);

  @override
  State<JoinRequestsPage> createState() => _JoinRequestsPageState();
}

class _JoinRequestsPageState extends State<JoinRequestsPage> {
  List<dynamic> joinRequests = [];
  bool isLoading = true;

  // ดึงข้อมูลคำขอเข้าร่วมปาร์ตี้
  Future<void> fetchJoinRequests() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse(''),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          joinRequests = data;
          isLoading = false;
        });
      } else {
        print('Failed to fetch join requests: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching join requests: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // อนุมัติคำขอเข้าร่วมปาร์ตี้
  Future<void> approveRequest(int requestId) async {
    // ดำเนินการอนุมัติคำขอที่นี่
    print('Approved request ID: $requestId');
  }

  // ปฏิเสธคำขอเข้าร่วมปาร์ตี้
  Future<void> rejectRequest(int requestId) async {
    // ดำเนินการปฏิเสธคำขอที่นี่
    print('Rejected request ID: $requestId');
  }

  @override
  void initState() {
    super.initState();
    fetchJoinRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('คำขอเข้าร่วมปาร์ตี้'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : joinRequests.isEmpty
              ? Center(child: Text('ไม่มีคำขอเข้าร่วมปาร์ตี้'))
              : ListView.builder(
                  itemCount: joinRequests.length,
                  itemBuilder: (context, index) {
                    final request = joinRequests[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: request['sender']['profile_image'] != null
                              ? NetworkImage(
                                  'http://10.0.2.2:8000${request['sender']['profile_image']}')
                              : null,
                          child: request['sender']['profile_image'] == null
                              ? Icon(Icons.person, size: 30, color: Colors.white)
                              : null,
                          backgroundColor: Colors.grey.shade400,
                        ),
                        title: Text(request['sender']['username']),
                        subtitle: Text('คำขอเข้าร่วมปาร์ตี้: ${request['party']['name']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => approveRequest(request['id']),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => rejectRequest(request['id']),
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

class Friendsrequespage extends StatefulWidget {
  const Friendsrequespage({super.key});

  @override
  State<Friendsrequespage> createState() => _FriendsrequespageState();
}

class _FriendsrequespageState extends State<Friendsrequespage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}