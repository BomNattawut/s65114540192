import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myflutterproject/scr/workoutpage.dart';

class PartyHistoryPage extends StatefulWidget {
  @override
  _PartyHistoryPageState createState() => _PartyHistoryPageState();
}

class _PartyHistoryPageState extends State<PartyHistoryPage> {
  List<Map<String, dynamic>> partyHistory = [];
  bool memoryloading=true;

  @override
  void initState() {
    super.initState();
    fetchPartyHistory();
  }

  Future<void> fetchPartyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fecthhistorygallary/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        memoryloading=false;
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('historyparty:${data}');
        final List<dynamic> historyData = data['history'] ?? [];

        setState(() {
          partyHistory = historyData.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _openShareDialog(Map<String, dynamic> memory) {
    TextEditingController captionController = TextEditingController();
    List<String> selectedImages = []; // ✅ เก็บรูปที่ผู้ใช้เลือก

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("📸 แชร์ความทรงจำ"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("📝 เขียนแคปชั่นสำหรับโพสต์ของคุณ"),
                TextField(
                  controller: captionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "เพิ่มแคปชั่น...",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                Text("📷 เลือกรูปที่ต้องการแชร์"),
                Wrap(
                  spacing: 5,
                  children: List.generate(memory['images'].length, (index) {
                    String imageUrl = memory['images'][index];
                    bool isSelected = selectedImages.contains(imageUrl);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedImages.remove(imageUrl);
                          } else {
                            selectedImages.add(imageUrl);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          Image.network(
                            'http://10.0.2.2:8000$imageUrl',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          if (isSelected)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ยกเลิก"),
              ),
              ElevatedButton(
                onPressed: () {
                  _shareMemory(memory, captionController.text, selectedImages);
                },
                child: Text("📢 แชร์เลย!"),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _shareMemory(Map<String, dynamic> memory, String caption,
      List<String> selectedImages) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/sharememory/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          "user_id": userId ?? '',
          "party_id": memory['id'],
          "text": caption,
          "selected_images":
              selectedImages, // ✅ ส่งเฉพาะรูปที่ผู้ใช้เลือกไปยัง API
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ แชร์ Memory สำเร็จ!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ไม่สามารถแชร์ Memory ได้!")),
        );
      }
    } catch (e) {
      print("⚠️ Error: $e");
    }
  }

  Future<void> deleteAlbum(int albumId) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/deletepartyalbum/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? '',
          'albumId': albumId.toString(),
        },
      );

      if (response.statusCode == 200) {
        print("✅ ลบอัลบั้มสำเร็จ");
        fetchPartyHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎉 ลบอัลบั้มสำเร็จ!")),
        );
      } else {
        print("⛔ ลบอัลบั้มไม่สำเร็จ: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ลบอัลบั้มไม่สำเร็จ!")),
        );
      }
    } catch (e) {
      print("⚠️ เกิดข้อผิดพลาด: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📜 ปาร์ตี้ที่เข้าร่วม",style: GoogleFonts.notoSansThai(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[800],
      body: 
      memoryloading ? 
      Center(
          child: Center(
                  child: Center(child: Center(child: CircularProgressIndicator(color: Colors.orange)) ,),
              ),
      ):
      partyHistory.isEmpty
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(
            Icons.camera_alt, // 💡 ไอคอนที่เหมาะกับ "ไม่มีคำขอ"
            size: 80,
            color: Colors.grey[600],
          ),
          
         
            ],
          ),
          const SizedBox(height: 16),
           const Text(
            'ไม่มีอาลาบั้ม',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          : ListView.builder(
              itemCount: partyHistory.length,
              itemBuilder: (context, index) {
                var party = partyHistory[index];

                DateTime completedAt = DateTime.parse(party['completed_at']);
                DateTime now = DateTime.now();
                bool canUpload = now.difference(completedAt).inHours < 24;

                return Card(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _openShareDialog(party);
                            },
                            label: Text('แชร์'),
                            icon: Icon(Icons.share),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: 7,
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("ยืนยันการลบ"),
                                  content:
                                      Text("คุณต้องการลบอัลบั้มนี้ใช่หรือไม่?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text("ยกเลิก"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text("ลบ"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm) {
                                await deleteAlbum(party['id']);
                              }
                            },
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text("ลบอัลบั้ม"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                       ListTile(
                        title: Text("${party['party_name']}",style: GoogleFonts.notoSansThai(color: Colors.black,fontWeight: FontWeight.bold),),
                        subtitle: Text("ผู้นำปาร์ตี้: ${party['leader_name']}",style: TextStyle(fontWeight: FontWeight.bold),),
                      ),
                      if (party['images'].isNotEmpty)
                        Container(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: party['images'].length,
                            itemBuilder: (context, i) {
                              return Padding(
                                padding: EdgeInsets.all(5),
                                child: Image.network(
                                  'http://10.0.2.2:8000${party['images'][i]}',
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      if (canUpload)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UploadMemoryPage(party: party),
                                ),
                              );
                            },
                            icon: Icon(Icons.add_a_photo),
                            label: Text("เพิ่มรูป"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("💬 รีวิว:",
                               style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontWeight: FontWeight.bold,fontSize:16))),
                            if (party['reviews'].isEmpty) Text("ไม่มีรีวิว"),
                            if (party['reviews'].isNotEmpty)
                              Column(
                                children: List.generate(party['reviews'].length,
                                    (index) {
                                  var review = party['reviews'][index];
                                  return ListTile(
                                    title: Text("${review['voter']}",style:GoogleFonts.notoSansThai(textStyle: TextStyle(fontWeight: FontWeight.bold,fontSize:14))),
                                    subtitle: Text("${review['review']}"),
                                    trailing: Text("⭐ ${review['rating']}"),
                                  );
                                }),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

//หน้าสำหรับเเสดงรายการmemmoryของปาร์ตี้ที่สร้าง
class CreatedPartyMemoryPage extends StatefulWidget {
  @override
  _CreatedPartyMemoryPageState createState() => _CreatedPartyMemoryPageState();
}

class _CreatedPartyMemoryPageState extends State<CreatedPartyMemoryPage> {
  List<Map<String, dynamic>> createdPartyHistory = [];
  bool memoryloading=true;

  @override
  void initState() {
    super.initState();
    fetchCreatedPartyHistory();
  }

  Future<void> fetchCreatedPartyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/creatpartyhistory/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          });
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('📜 ข้อมูลที่ส่งมา:${data}');
        final List<dynamic> historyData = data['created_parties'] ?? [];

        setState(() {
          memoryloading=false;
          createdPartyHistory = historyData.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  void _openShareDialog(Map<String, dynamic> memory) {
    TextEditingController captionController = TextEditingController();
    List<String> selectedImages = []; // ✅ เก็บรูปที่ผู้ใช้เลือก

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("📸 แชร์ความทรงจำ"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("📝 เขียนแคปชั่นสำหรับโพสต์ของคุณ"),
                TextField(
                  controller: captionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "เพิ่มแคปชั่น...",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                Text("📷 เลือกรูปที่ต้องการแชร์"),
                Wrap(
                  spacing: 5,
                  children: List.generate(memory['images'].length, (index) {
                    String imageUrl = memory['images'][index];
                    bool isSelected = selectedImages.contains(imageUrl);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedImages.remove(imageUrl);
                          } else {
                            selectedImages.add(imageUrl);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          Image.network(
                            'http://10.0.2.2:8000$imageUrl',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          if (isSelected)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ยกเลิก"),
              ),
              ElevatedButton(
                onPressed: () {
                  _shareMemory(memory, captionController.text, selectedImages);
                },
                child: Text("📢 แชร์เลย!"),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _shareMemory(Map<String, dynamic> memory, String caption,
      List<String> selectedImages) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/sharememoryforleader/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          "user_id": userId ?? '',
          "party_id": memory['id'],
          "text": caption,
          "selected_images":
              selectedImages, // ✅ ส่งเฉพาะรูปที่ผู้ใช้เลือกไปยัง API
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ แชร์ Memory สำเร็จ!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ไม่สามารถแชร์ Memory ได้!")),
        );
      }
    } catch (e) {
      print("⚠️ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("👑 ปาร์ตี้ที่สร้าง",style:  GoogleFonts.notoSansThai(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[800],
      body: 
      
      memoryloading ?
      Center(
        child: Center(
          child: Center(
                  child: Center(child: Center(child: CircularProgressIndicator(color: Colors.orange)) ,),
              ),
      )
      ):
      createdPartyHistory.isEmpty
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Icon(
            Icons.camera_alt, // 💡 ไอคอนที่เหมาะกับ "ไม่มีคำขอ"
            size: 80,
            color: Colors.grey[600],
          ),
          
         
            ],
          ),
          const SizedBox(height: 16),
           const Text(
            'ไม่มีอาลาบั้ม',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          : ListView.builder(
              itemCount: createdPartyHistory.length,
              itemBuilder: (context, index) {
                var party = createdPartyHistory[index];

                // ✅ เช็คว่าปาร์ตี้จบไปแล้วกี่ชั่วโมง
                DateTime completedAt =
                    DateTime.parse(party['completed_at']); // เวลาปาร์ตี้จบ
                DateTime now = DateTime.now();
                bool canUpload = now.difference(completedAt).inHours <
                    24; // เช็คว่าไม่เกิน 24 ชม.

                return Card(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _openShareDialog(party);
                            },
                            label: Text('แชร์'),
                            icon: Icon(Icons.share),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          SizedBox(
                            width: 7,
                          ),
                          IconButton(
                              onPressed: () {

                                
                              },
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                              )),
                          SizedBox(width: 10),
                        ],
                      ),
                      ListTile(
                        title: Text("${party['party_name']}",style: GoogleFonts.notoSansThai(color: Colors.black,fontWeight: FontWeight.bold),),
                        subtitle: Text("ผู้นำปาร์ตี้: ${party['leader_name']}",style: TextStyle(fontWeight: FontWeight.bold),),
                      ),

                      if (party['images'].isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
    child: party['images'].length == 1
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'http://10.0.2.2:8000${party['images'][0]}',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: party['images'].length,
              itemBuilder: (context, i) {
                return Container(
                  margin: EdgeInsets.only(right: 10),
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'http://10.0.2.2:8000${party['images'][i]}',
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
  ),

                      // ✅ แสดงปุ่ม "เพิ่มรูป" ถ้ายังไม่เกิน 24 ชม.
                      if (canUpload)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UploadMemoryPage(party: party),
                                ),
                              );
                            },
                            icon: Icon(Icons.add_a_photo),
                            label: Text("เพิ่มรูป"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("💬 รีวิว:",
                                style: GoogleFonts.notoSansThai(textStyle: TextStyle(fontWeight: FontWeight.bold,fontSize:16))),
                            if (party['reviews'].isEmpty) Text("ไม่มีรีวิว"),
                            if (party['reviews'].isNotEmpty)
                              Column(
                                children: List.generate(party['reviews'].length,
                                    (index) {
                                  var review = party['reviews'][index];
                                  return ListTile(
                                    title: Text("${review['voter']}",style:GoogleFonts.notoSansThai(textStyle: TextStyle(fontWeight: FontWeight.bold,fontSize:14))),
                                    subtitle: Text("${review['review']}"),
                                    trailing: Text("⭐ ${review['rating']}"),
                                  );
                                }),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
