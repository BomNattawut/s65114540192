import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myflutterproject/scr/apifirebase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class showjoinpartyrequest extends StatefulWidget {
  const showjoinpartyrequest({super.key});

  @override
  State<showjoinpartyrequest> createState() => _showjoinpartyrequestState();
}

class _showjoinpartyrequestState extends State<showjoinpartyrequest> {
  List<Map<String, dynamic>> joinRequests = [];
  bool isLoading =true;

  Future<void> feachAllajoinrequest() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthallrequest/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          isLoading=false;
          joinRequests =
              data.map((item) => item as Map<String, dynamic>).toList();
        });
        print('รายการคำขอที่ส่งมา:${joinRequests}');
      }
    } catch (e) {
      print('Error${e}');
    }
  }

  void initState() {
    super.initState();
    feachAllajoinrequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('คำขอเข้าร่วมทั้งหมด'),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: const Color.fromARGB(255, 71, 70, 70),
      body: 
      isLoading?  const Center(
        child:Center(child: CircularProgressIndicator(color: Colors.orange)) ,
      ):
      joinRequests.isEmpty
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(
            Icons.group_off, // 💡 ไอคอนที่เหมาะกับ "ไม่มีคำขอ"
            size: 80,
            color: Colors.grey[600],
          ),
          
         
            ],
          ),
          const SizedBox(height: 16),
           const Text(
            'ไม่มีคำขอเข้าร่วม',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          : ListView.builder(
              itemCount: joinRequests.length,
              itemBuilder: (context, index) {
                final request = joinRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: request['sender_user_profile'] != null
                          ? NetworkImage(
                              'http://10.0.2.2:8000/${request['sender_user_profile']}')
                          : null,
                      child: request['sender_user_profile'] == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white,
                            )
                          : null,
                      backgroundColor: Colors.grey,
                    ),
                    title: Text('คำขอเข้าร่วมจาก${request['sender_username']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${request['sender_username']}ต้องการเข้าน่สมปาร์ตี้ของคุณ',
                        ),
                        Text('ปาร์ตี้:${request['party_name']}'),
                        Text('วันที่ส่ง:${request['send_date']}'),
                        Text('เวลา:${request['send_time']}'),
                        Text('สถานะ:${request['status']}')
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => showjoinrequestDetail(
                            requestdetail: request,
                          ),
                        ),
                      );

                      // ตรวจสอบค่าที่ส่งกลับมา
                      if (result != null && result == true) {
                        // ทำการรีเฟรชหน้า หรือดำเนินการอื่นๆ ที่ต้องการ
                        feachAllajoinrequest();
                      }
                    },
                  ),
                );
              }),
    );
  }
}

class showjoinrequestDetail extends StatefulWidget {
  final Map<String, dynamic> requestdetail;
  const showjoinrequestDetail({super.key, required this.requestdetail});

  @override
  State<showjoinrequestDetail> createState() => _showjoinrequestDetailState();
}

class _showjoinrequestDetailState extends State<showjoinrequestDetail> {
  void initState() {
    super.initState();
    print('เลขIdของคำขอ${widget.requestdetail['id']}');
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(
      title: Text(
        'รายละเอียดคำขอ',
        style: GoogleFonts.notoSansThai(color: Colors.white),
      ),
      backgroundColor: Colors.orange,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: widget.requestdetail['sender_user_profile'] != null
                      ? NetworkImage(
                          'http://10.0.2.2:8000/${widget.requestdetail['sender_user_profile']}')
                      : null,
                  child: widget.requestdetail['sender_user_profile'] == null
                      ? Icon(Icons.person, color: Colors.white, size: 50)
                      : null,
                  backgroundColor: Colors.grey[600],
                ),
                SizedBox(height: 20),

                Text(
                  'ขอเข้าร่วมปาร์ตี้จาก ${widget.requestdetail['sender_username']}',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),

                Text(
                  '📍 สถานที่: ${widget.requestdetail['location']['location_name']}',
                  style: GoogleFonts.notoSansThai(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'http://10.0.2.2:8000/${widget.requestdetail['location']['place_image']}',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                SizedBox(height: 16),
                Text(
                  '🎉 ชื่อปาร์ตี้: ${widget.requestdetail['party_name']}',
                  style: GoogleFonts.notoSansThai(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  '📅 วันที่ส่งคำขอ: ${widget.requestdetail['send_date']}',
                  style: GoogleFonts.notoSansThai(fontSize: 16, color: Colors.white70),
                ),

                SizedBox(height: 24),

                // ✅ ปุ่ม
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool success = await rejectedjoinrequest(
                          widget.requestdetail['id'],
                          widget.requestdetail['sender'],
                        );
                        Navigator.pop(context, success);
                      },
                      icon: Icon(Icons.cancel, color: Colors.white),
                      label: Text(
                        'ปฏิเสธคำขอ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool success = await aceptjoinrequest(
                          widget.requestdetail['sender'],
                          widget.requestdetail['party'],
                          widget.requestdetail['id'],
                        );
                        Navigator.pop(context, success);
                      },
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        'ยอมรับคำขอ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  }

class ShowAllinvitation extends StatefulWidget {
  const ShowAllinvitation({super.key});

  @override
  State<ShowAllinvitation> createState() => _ShowAllinvitationState();
}

class _ShowAllinvitationState extends State<ShowAllinvitation> {
  List<Map<String, dynamic>> allinvitation = [];
  bool isLoading =true;


  Future<void> fetchAllInvitations() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthallinvitation/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        isLoading =false;
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          allinvitation =
              data.map((item) => item as Map<String, dynamic>).toList();
        });
        print('รายการคำเชิญทั้งหมด: ${allinvitation}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAllInvitations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('คำเชิญทั้งหมด'),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: const Color.fromARGB(255, 71, 70, 70),
      body: 
       isLoading?  const Center(
        child:Center(child: CircularProgressIndicator(color: Colors.orange)) ,
      ):
      
      allinvitation.isEmpty
          ?Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(
            Icons.inbox_outlined, // 💡 ไอคอนที่เหมาะกับ "ไม่มีคำขอ"
            size: 80,
            color: Colors.grey[600],
          ),
          
         
            ],
          ),
          const SizedBox(height: 16),
           const Text(
            'ไม่มีคำขอเข้าเชิญ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          : ListView.builder(
              itemCount: allinvitation.length,
              itemBuilder: (context, index) {
                final invitation = allinvitation[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: invitation['sender_user_profile'] != null
                          ? NetworkImage(
                              'http://10.0.2.2:8000/${invitation['sender_user_profile']}')
                          : null,
                      child: invitation['sender_user_profile'] == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white,
                            )
                          : null,
                      backgroundColor: Colors.grey,
                    ),
                    title: Text('คำเชิญจาก ${invitation['sender_username']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${invitation['sender_username']} เชิญคุณเข้าร่วมปาร์ตี้'),
                        Text('ปาร์ตี้: ${invitation['party_detail']['name']}'),
                        Text('วันที่ส่ง: ${invitation['send_date']}'),
                        Text('เวลา: ${invitation['send_time']}'),
                        Text('สถานะ: ${invitation['status']}')
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShowInvitationDetail(
                            invitationDetail: invitation,
                          ),
                        ),
                      );
                      if (result != null && result == true) {
                        fetchAllInvitations();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}


class ShowInvitationDetail extends StatefulWidget {
  final Map<String, dynamic> invitationDetail;
  const ShowInvitationDetail({super.key, required this.invitationDetail});

  @override
  _ShowInvitationDetailState createState() => _ShowInvitationDetailState();
}

class _ShowInvitationDetailState extends State<ShowInvitationDetail> {
  late Map<String, dynamic> invitationDetail;
  final String baseUrl = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    invitationDetail = widget.invitationDetail;
    print('invitationId:${invitationDetail}');
  }


    
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(
      title: Text(
        'รายละเอียดคำเชิญ',
        style: GoogleFonts.notoSansThai(color: Colors.white),
      ),
      backgroundColor: Colors.orange,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.grey[850],
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🧑 รูปโปรไฟล์
                CircleAvatar(
                  radius: 50,
                  backgroundImage: invitationDetail['sender_user_profile'] != null
                      ? NetworkImage('$baseUrl${invitationDetail['sender_user_profile']}')
                      : null,
                  child: invitationDetail['sender_user_profile'] == null
                      ? const Icon(Icons.person, color: Colors.white, size: 50)
                      : null,
                  backgroundColor: Colors.grey[600],
                ),
                const SizedBox(height: 20),

                // ✨ ข้อมูลคำเชิญ
                Text(
                  'ขอเชิญเข้าร่วมปาร์ตี้จาก ${invitationDetail['sender_username']}',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '📍 สถานที่: ${invitationDetail['party_detail']['location']['location_name']}',
                  style: GoogleFonts.notoSansThai(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),

                // 🖼 รูปสถานที่
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    '$baseUrl${invitationDetail['party_detail']['location']['place_image']}',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '🎉 ชื่อปาร์ตี้: ${invitationDetail['party_detail']['name']}',
                  style: GoogleFonts.notoSansThai(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '📅 วันที่ส่งคำเชิญ: ${invitationDetail['send_date']}',
                  style: GoogleFonts.notoSansThai(fontSize: 16, color: Colors.white70),
                ),

                const SizedBox(height: 24),

                // ✅ ปุ่มยอมรับ/ปฏิเสธ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool success = await rejectedinvitation(invitationDetail['id']);
                        Navigator.pop(context, success);
                      },
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: Text(
                        'ปฏิเสธ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        bool success = await accepintavitation(invitationDetail['id']);
                        Navigator.pop(context, success);
                      },
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        'ยอมรับ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  }


