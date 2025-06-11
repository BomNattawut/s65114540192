import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:myflutterproject/scr/notification_service.dart';

class WorkoutCountdownPage extends StatefulWidget {
  final Map<String, dynamic> party;
  final bool isLeader;

  const WorkoutCountdownPage(
      {Key? key, required this.party, required this.isLeader})
      : super(key: key);

  @override
  _WorkoutCountdownPageState createState() => _WorkoutCountdownPageState();
}

class _WorkoutCountdownPageState extends State<WorkoutCountdownPage>
    with SingleTickerProviderStateMixin {
  bool isFinished = false;
  bool finishworkout = false;
  int totalMembers = 0;
  int completedMembers = 0;
  List<Map<String, dynamic>> members = [];
  Timer? _statusTimer;
  late AnimationController _controller;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchWorkoutStatus();
    _startAutoUpdate();
    _notificationService.initNotification();
    

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  void _startAutoUpdate() {
    _statusTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchWorkoutStatus();
      if(!widget.isLeader){
      fectworkoutmemberstatus();}
      
      if (isFinished && !widget.isLeader) {
       print("🔥 isFinished: ${isFinished}");
       print("📌 เปลี่ยนไปหน้ารีวิวปาร์ตี้");
       Navigator.pushReplacement(
           context, 
           MaterialPageRoute(builder: (context) => PartyReviewPage(party: widget.party))
       );
     }
    });
  }

  Future<void> _fetchWorkoutStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/getfinishworkout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalMembers = data['total_members'];
          completedMembers = data['completed_members'];
          print('สถานะปาร์ตี้:${data['status']}');
          isFinished = data['status'] == "completed";
          print('สถานะปาร์ตี้ในisfinished:${isFinished}');
          members = List<Map<String, dynamic>>.from(data['members']);
        });

        print("✅ สมาชิกที่ออกกำลังกายเสร็จแล้ว: $completedMembers / $totalMembers");
      }
    } catch (e) {
      print("⚠️ เกิดข้อผิดพลาด: $e");
    }
  }

  Future<void> _markWorkoutComplete() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    String? userId=prefs.getString('userid');

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/finishworkout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
          'userId': userId ?? ''
        },
      );

      if (response.statusCode == 200) {
        fectworkoutmemberstatus();
        _fetchWorkoutStatus();
      }
    } catch (e) {
      print("⚠️ เกิดข้อผิดพลาด: $e");
    }
  }
  Future<void>fectworkoutmemberstatus() async{
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    String? userId=prefs.getString('userid');
    try {
        final response= await http.get(Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthworkoutstatus/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
          'userId': userId ?? ''
        }
        );
        if (response.statusCode==200) {
            final data= json.decode(response.body);
            setState(() {
                finishworkout = data;
            });
        }
    } catch (e) {
      print('Error:${e}');
    }
  }
  Future<void> _finishWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/finishparty/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'partyId': partyId.toString(),
          
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isFinished = true;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      print("⚠️ เกิดข้อผิดพลาด: $e");
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _controller.dispose();
    _notificationService.cancelNotification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("🎉 ปาร์ตี้ออกกำลังกายเริ่มเเล้ว"),
      backgroundColor: Colors.orange,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    backgroundColor: Colors.grey[900], // ✅ พื้นหลังเป็นสีเทาเข้ม
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ✅ แสดงจำนวนคนที่ออกกำลังกายเสร็จแล้ว
          Text(
            "✅ สมาชิกที่ออกกำลังกายเสร็จแล้ว: $completedMembers / $totalMembers",
            style: GoogleFonts.notoSansThai(textStyle:  TextStyle(fontSize: 16, color: Colors.orange)),
          ),

          const SizedBox(height: 20),

          // ✅ เปลี่ยน ListTile เป็น Card
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                var member = members[index];
                return Card(
                  color: Colors.grey[850], // ✅ เปลี่ยนสีการ์ดเป็นสีเทาเข้ม
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // ✅ ทำให้โค้งมนขึ้น
                  ),
                  elevation: 4, // ✅ เพิ่มเงาให้ดูโดดเด่น
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: member['profile_image'] != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(member['profile_image']),
                          )
                        : const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                    title: Text(
                      member['username'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      member['finish_workout'] ? "✔ ออกกำลังกายเสร็จแล้ว" : "⏳ กำลังออกกำลังกาย",
                      style: TextStyle(
                        color: member['finish_workout'] ? Colors.green : Colors.orange,
                      ),
                    ),
                    trailing: member['finish_workout']
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                        : AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _controller.value * 6.28,
                                child: const Icon(Icons.hourglass_top,
                                    size: 28, color: Colors.orange),
                              );
                            },
                          ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          if (!widget.isLeader)
          // ✅ ปุ่ม "ออกกำลังกายเสร็จแล้ว"
          ElevatedButton(
            onPressed: finishworkout ? null : _markWorkoutComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: finishworkout ? Colors.grey : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: finishworkout
                ? const Text("🏁 ออกกำลังกายเสร็จแล้ว", style: TextStyle(fontSize: 18))
                : const Text('✅ ออกกำลังกายเสร็จแล้ว', style: TextStyle(fontSize: 18)),
          ),

          const SizedBox(height: 10),

          // ✅ ปุ่ม "จบปาร์ตี้" (เฉพาะ Leader)
          if (widget.isLeader)
            ElevatedButton(
              onPressed: (completedMembers == totalMembers) ? _finishWorkout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    (completedMembers == totalMembers) ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text("🎯 จบปาร์ตี้", style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontSize: 18))),
            ),

          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}
}

// ✅ หน้ารีวิวปาร์ตี้
class PartyReviewPage extends StatefulWidget {
  final Map<String, dynamic> party;

  const PartyReviewPage({Key? key, required this.party}) : super(key: key);

  @override
  _PartyReviewPageState createState() => _PartyReviewPageState();
}

class _PartyReviewPageState extends State<PartyReviewPage> {
  int rating = 0; // ⭐ จำนวนดาวที่เลือก
  TextEditingController reviewController = TextEditingController();
  bool isSubmitting = false; // ป้องกันการกดซ้ำ

  Future<void> _submitReview() async {
    if (rating == 0 || reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("กรุณาให้คะแนนและเขียนรีวิวก่อนส่ง!")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    String? userId=prefs.getString('userid');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/submitvote/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          "party_id": partyId.toString(),
          "rating": rating,
          "review": reviewController.text,
          'user_id': userId ?? ''
          
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ รีวิวถูกส่งเรียบร้อย!")),
        );
        _showUploadPhotoDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ไม่สามารถส่งรีวิวได้!")),
        );
      }
    } catch (e) {
      print("⚠️ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ มีข้อผิดพลาดเกิดขึ้น!")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }
  void _showUploadPhotoDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("📸 เพิ่ม Party Memory"),
      content: Text("คุณต้องการอัปโหลดรูปภาพ Party Memory ไหม?"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => UploadMemoryPage(party: widget.party)),
            );
          },
          child: Text("✅ ใช่, อัปโหลดรูป!"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
          child: Text("❌ ไม่, ข้ามไปเลย"),
        ),
      ],
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(
      backgroundColor: Colors.orange,
      title: Text("📝 รีวิวปาร์ตี้", style: TextStyle(color: Colors.black)),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    body: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🎉 รีวิวปาร์ตี้ ${widget.party['name']}",
            style: GoogleFonts.notoSansThai(textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),)
          ),
        
          SizedBox(height: 20),

          Text("🌟 ให้คะแนน:",
              style:GoogleFonts.notoSansThai(textStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 123, 123, 122),
            ),)),

          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    rating = index + 1;
                  });
                },
              );
            }),
          ),

          SizedBox(height: 20),

          TextField(
            controller: reviewController,
            maxLines: 3,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              hintText: "เขียนรีวิวของคุณ...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),

          SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: isSubmitting
                  ? CircularProgressIndicator(color: Colors.black)
                  : Text(
                      "✅ ส่งรีวิว",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

  }


class UploadMemoryPage extends StatefulWidget {
  final Map<String, dynamic> party;
  const UploadMemoryPage({Key? key, required this.party}) : super(key: key);

  @override
  _UploadMemoryPageState createState() => _UploadMemoryPageState();
}

class _UploadMemoryPageState extends State<UploadMemoryPage> {
  File? _image;
  bool isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      isUploading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? partyId = widget.party['id'];
    String? userId = prefs.getString('userid');

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://10.0.2.2:8000/Smartwityouapp/upload_memory/"),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $accessToken',
    });
    request.fields['party_id'] = partyId.toString();
    request.fields['user_id'] = userId ?? '';
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ อัปโหลดรูปสำเร็จ!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ อัปโหลดรูปไม่สำเร็จ!")),
      );
    }

    setState(() {
      isUploading = false;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(
      backgroundColor: Colors.orange,
      automaticallyImplyLeading: false,
      title: Text(
        "📸 เพิ่ม Party Memory",
        style: GoogleFonts.notoSansThai(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ],
                      image: DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Text(
                    "📷 กรุณาเลือกรูปจากอัลบั้ม",
                    style: GoogleFonts.notoSansThai(
                      fontSize: 18,
                      color: Colors.white54,
                    ),
                  ),
            const SizedBox(height: 30),

            // 📂 เลือกรูป
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.folder_open),
                label: Text(
                  "📂 เลือกรูปภาพ",
                  style: GoogleFonts.notoSansThai(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ อัปโหลดรูป
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : _uploadImage,
                icon: isUploading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(Icons.cloud_upload),
                label: Text(
                  isUploading ? "กำลังอัปโหลด..." : "✅ อัปโหลดรูป",
                  style: GoogleFonts.notoSansThai(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

