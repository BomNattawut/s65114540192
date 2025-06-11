import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Home.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final String user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;

  Future<void> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/feactProfile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': widget.user
        },
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        print('ข้อมูลโปรไฟล์:${data}');
        setState(() {
          profile = data;
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  String formatExerciseTypes(List<dynamic> types) {
    return types
        .map((type) => type['name'])
        .join(", "); // ให้แต่ละชนิดคั่นด้วย ", "
  }

  String formatWorkoutTimes(List<dynamic> times) {
    return times
        .map((time) =>
            "${time['day']}: ${time['start_time']} - ${time['end_time']}")
        .join("\n"); // ให้แต่ละรายการอยู่คนละบรรทัด
  }

  Future<void> removefriend(String friendID) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.delete(
        Uri.parse(
            'http://10.0.2.2:8000/Smartwityouapp/removefriend/${friendID}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ลบเพือนเเล้ว!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ลบเพือนไม่สำเร็จ!")),
        );
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            Text('เพื่อน', style: TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: profile == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                          onPressed: () {
                            removefriend(profile!['id']);
                          },
                          icon: Icon(
                            Icons.person_remove,
                            color: Colors.red,
                          ), label: Text('ลบเพื่อน',style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.bold)),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 129, 129, 129)
                          ),      
                                )
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.5,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: profile!['background'] == null
                                ? Colors.orange
                                : null, // ✅ ใช้สีพื้นหลังถ้าไม่มีรูป
                            image: profile!['background'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        'http://10.0.2.2:8000/${profile!['background']}'),
                                    fit: BoxFit.cover,
                                  )
                                : null, // ✅ ถ้าไม่มีรูป ให้ไม่ใช้ `image`
                          ),
                        ),
                      ),
                      Positioned(
                        child: CircleAvatar(
                          radius: 58,
                          backgroundImage: profile!['profile_image'] != null
                              ? NetworkImage(
                                  'http://10.0.2.2:8000/${profile!['profile_image']}',
                                )
                              : null,
                          child: profile!['profile_image'] == null
                              ? Icon(Icons.person,
                                  size: 60, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 16),
                      Text('ชื่อ:',
                        style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.bold))),
                      SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                      Text(
                        '${profile!['username'] ?? "Unknown"}',
                        style: GoogleFonts.notoSansThai(
                            textStyle: TextStyle(
                                color: const Color.fromARGB(255, 151, 150, 150),
                                fontSize: 16)),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                  _buildInfoRow("ประเภทการออกที่ชอบ:",
                      formatExerciseTypes(profile!['exercise_types'] ?? [])),

                  SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                  _buildInfoRow("วันสะดวกออกำลังกาย:",
                      formatWorkoutTimes(profile!['exercise_times'] ?? [])),
                  SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 30),
                      Text(
                        'คำอธิบาย',
                        style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                 
                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      profile!['description'] ?? "No description available.",
                      style: GoogleFonts.notoSansThai(
                          textStyle: TextStyle(
                              color: const Color.fromARGB(255, 151, 150, 150),
                              fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String title, dynamic content) {
    String displayContent;

    if (content is List) {
      displayContent = content.join(", "); // แปลงลิสต์เป็นข้อความ
    } else {
      displayContent = content.toString(); // แปลงค่าปกติเป็นข้อความ
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.notoSansThai(
                  textStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              displayContent,
              style: GoogleFonts.notoSansThai(
                  textStyle: TextStyle(
                      color: const Color.fromARGB(255, 151, 150, 150),
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class Userprofile extends StatefulWidget {
  const Userprofile({super.key});

  @override
  State<Userprofile> createState() => _UserprofileState();
}

class _UserprofileState extends State<Userprofile> {
  Map<String, dynamic>? userprofile;
  Future<void> fecthProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/feactProfile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        print('ข้อมูลโปรไฟล์:${data}');
        setState(() {
          userprofile = data;
        });
      } else {
        print('Error${response.statusCode}');
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  @override
  void initState() {
    super.initState();
    fecthProfile();
  }

  String formatExerciseTypes(List<dynamic> types) {
    return types
        .map((type) => type['name'])
        .join(", "); // ให้แต่ละชนิดคั่นด้วย ", "
  }

  String formatWorkoutTimes(List<dynamic> times) {
    return times
        .map((time) =>
            "${time['day']}: ${time['start_time']} - ${time['end_time']}")
        .join("\n"); // ให้แต่ละรายการอยู่คนละบรรทัด
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: Text(
          'โปรไฟล์',
          style: GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false, // ลบ Stack ทั้งหมด
          ),
        ),
      ),
      body: userprofile == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                  userprofile: userprofile ?? {}),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        label: Text('เเก้ไขโปรไฟล์',style: GoogleFonts.notoSansThai(color: Colors.white),),
                        icon: Icon(Icons.edit),
                      )
                    ],
                  ),
                  SizedBox(height: 5),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.5,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: userprofile!['background'] == null
                                ? Colors.orange
                                : null, // ✅ ใช้สีพื้นหลังถ้าไม่มีรูป
                            image: userprofile!['background'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        'http://10.0.2.2:8000/${userprofile!['background']}'),
                                    fit: BoxFit.cover,
                                  )
                                : null, // ✅ ถ้าไม่มีรูป ให้ไม่ใช้ `image`
                          ),
                        ),
                      ),
                      Positioned(
                        child: CircleAvatar(
                          radius: 58,
                          backgroundImage: userprofile!['profile_image'] != null
                              ? NetworkImage(
                                  'http://10.0.2.2:8000/${userprofile!['profile_image']}',
                                )
                              : null,
                          child: userprofile!['profile_image'] == null
                              ? Icon(Icons.person,
                                  size: 60, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 20),
                      Text(
                        'ชื่อ:',
                        style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        '${userprofile!['username'] ?? "Unknown"}',
                        style: GoogleFonts.notoSansThai(
                            textStyle: TextStyle(
                                color: const Color.fromARGB(255, 151, 150, 150),
                                fontSize: 16)),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        'อีเมล:',
                        style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        '${userprofile!['email']}',
                        style: GoogleFonts.notoSansThai(
                            textStyle: TextStyle(
                                color: const Color.fromARGB(255, 151, 150, 150),
                                fontSize: 16)),
                      )
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                  _buildInfoRow(
                      "ประเภทออกกำลังกายที่ชอบ:",
                      formatExerciseTypes(
                          userprofile!['exercise_types'] ?? [])),
                  SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                  _buildInfoRow("เวลาออกำลังกาย:",
                      formatWorkoutTimes(userprofile!['exercise_times'] ?? [])),
                  SizedBox(height: 20),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Divider(color: Colors.grey),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 30),
                      Text(
                        'คำอธิบายตัวเอง',
                        style: GoogleFonts.notoSansThai(
                            textStyle:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      userprofile!['description'] ??
                          "No description available.",
                      style: GoogleFonts.notoSansThai(
                          textStyle: TextStyle(
                              color: const Color.fromARGB(255, 151, 150, 150),
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String title, dynamic content) {
    String displayContent;

    if (content is List) {
      displayContent = content.join(", "); // แปลงลิสต์เป็นข้อความ
    } else {
      displayContent = content.toString(); // แปลงค่าปกติเป็นข้อความ
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansThai(
                textStyle: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(displayContent,
                style: GoogleFonts.notoSansThai(
                    textStyle: TextStyle(
                        color: const Color.fromARGB(255, 151, 150, 150),
                        fontSize: 16))),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userprofile;

  EditProfileScreen({required this.userprofile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  File? _profileImage;
  File? _backgroundImage;

  List<String> selectedExerciseTypes = [];
  List<Map<String, String>> selectedExerciseTimes = [];

  List<Map<String, dynamic>> exerciseTypeOptions = [];
  List<Map<String, String>> daysOfWeek = [
    {"id": "MON", "name": "จันทร์"},
    {"id": "TUE", "name": "อังคาร"},
    {"id": "WED", "name": "พุธ"},
    {"id": "THU", "name": "พฤหัส"},
    {"id": "FRI", "name": "ศุกร์"},
    {"id": "SAT", "name": "เสาร์"},
    {"id": "SUN", "name": "อาทิตย์"},
  ];

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.userprofile['username'] ?? "";
    emailController.text = widget.userprofile['email'] ?? "";
    descriptionController.text = widget.userprofile['description'] ?? "";
    fecthworkout();

    selectedExerciseTypes = (widget.userprofile['exercise_types'] as List?)
            ?.map((e) => e['excercise_id'].toString()) // ✅ เก็บเฉพาะ `id`
            .toList() ??
        [];

    selectedExerciseTimes = (widget.userprofile['exercise_times'] as List?)
            ?.map((e) => {
                  'day': e['day'].toString(),
                  'start_time': e['start_time'].toString(),
                  'end_time': e['end_time'].toString(),
                })
            .toList() ??
        [];
    print(' ประเภทที่มีอยู่ก่อนหน้า: ${widget.userprofile['exercise_types']}');
    print('เวลาที่เลือก:${selectedExerciseTimes}');
    print(' ค่า `selectedExerciseTypes` ที่โหลดมา:${selectedExerciseTypes}');
  }

  Future<void> fecthworkout() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fechworkout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? ''
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('ประเภท:${data}');
        setState(() {
          exerciseTypeOptions = data
              .map((item) => {'id': item['id'], 'name': item['name']})
              .toList();
        });
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  // 📌 ฟังก์ชันเลือกไฟล์รูปภาพ
  Future<void> _pickImage(bool isProfile) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _backgroundImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<String?> pickTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
      initialEntryMode:
          TimePickerEntryMode.inputOnly, // ✅ บังคับให้ใช้แบบป้อนตัวเลข
    );

    if (picked != null) {
      return "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
    }
    return null;
  }

  Future<String?> _selectDayDialog(BuildContext context) async {
    String? selectedDay;

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("เลือกวัน"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: daysOfWeek.map((day) {
              return ListTile(
                title: Text(day['name']!),
                onTap: () {
                  selectedDay = day['id'];
                  Navigator.pop(context, selectedDay);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // 📌 ฟังก์ชันบันทึกข้อมูลที่แก้ไข
  void _saveProfile() async {
    Map<String, dynamic> updatedProfile = {
      "username": usernameController.text,
      "email": emailController.text,
      "description": descriptionController.text,
      "profile_image": _profileImage != null
          ? _profileImage!.path
          : widget.userprofile['profile_image'],
      "background_image": _backgroundImage != null
          ? _backgroundImage!.path
          : widget.userprofile['background'],
      "exercise_types": selectedExerciseTypes,
      "exercise_times": selectedExerciseTimes,
    };

    // ✅ TODO: ส่ง `updatedProfile` ไปยัง API เพื่ออัปเดตข้อมูล
    print('ข้อมูลที่จะอัพเดต${updatedProfile}');
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? userId = prefs.getString('userid');

      final response = await http.put(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/updateprofile/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'userId': userId ?? ''
          },
          body: json.encode({'updateprofile': updatedProfile}));
      if (response.statusCode == 200) {
        print('messgae:${response.body}');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('อัพเดตโปรไฟล์เเล้ว')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Userprofile()),
          (route) => false, // ลบ Stack ทั้งหมด
        );
      } else {
        print('Error:${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัพเดตโปรไฟล์ไม่สำเร็จ')));
      }
    } catch (e) {
      print('Error:${e}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "แก้ไขโปรไฟล์",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[800],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ พื้นหลังโปรไฟล์
            GestureDetector(
              onTap: () => _pickImage(false),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  image: _backgroundImage != null
                      ? DecorationImage(
                          image: FileImage(_backgroundImage!),
                          fit: BoxFit.cover)
                      : widget.userprofile['background'] != null
                          ? DecorationImage(
                              image: NetworkImage(
                                  'http://10.0.2.2:8000/${widget.userprofile['background']}'),
                              fit: BoxFit.cover)
                          : null,
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 40),
              ),
            ),
            SizedBox(height: 20),

            // ✅ รูปโปรไฟล์
            GestureDetector(
              onTap: () => _pickImage(true),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : widget.userprofile['profile_image'] != null
                        ? NetworkImage(
                                'http://10.0.2.2:8000/${widget.userprofile['profile_image']}')
                            as ImageProvider
                        : null,
                backgroundColor: Colors.grey.shade400,
                child: _profileImage == null &&
                        widget.userprofile['profile_image'] == null
                    ? Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 20),

            // ✅ ฟิลด์แก้ไขข้อมูลโปรไฟล์
            _buildTextField("ชื่อผู้ใช้", usernameController),
            _buildTextField("อีเมล", emailController),
            _buildTextField("คำอธิบาย", descriptionController, maxLines: 3),

            SizedBox(height: 20),

            // ✅ เลือกประเภทออกกำลังกายที่ชอบ
            _buildExerciseTypeSelector(),

            SizedBox(height: 20),

            // ✅ เลือกช่วงเวลาออกกำลังกาย
            _buildWorkoutTimeSelector(),

            SizedBox(height: 20),

            // ✅ ปุ่มบันทึก
            ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: Icon(Icons.save),
              label: Text("บันทึก"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.grey[700],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // 📌 ฟังก์ชันสร้าง Dropdown ให้เลือกประเภทออกกำลังกาย
  Widget _buildExerciseTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ประเภทออกกำลังกายที่ชอบ:",
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Wrap(
          children: exerciseTypeOptions.map((type) {
            return ChoiceChip(
              label:
                  Text(type['name'].toString()), // ✅ แสดงชื่อประเภทออกกำลังกาย
              selected: selectedExerciseTypes
                  .contains(type['id'].toString()), // ✅ ตรวจสอบ ID ใน List
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedExerciseTypes.add(type['id'].toString());
                    print(
                        'ค่าที่เลือก:${selectedExerciseTypes}'); // ✅ เก็บ `id` เป็น `String`
                  } else {
                    selectedExerciseTypes.remove(type['id'].toString());
                    print('ค่าที่เลือก:${selectedExerciseTypes}');
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 📌 ฟังก์ชันสร้าง Dropdown ให้เลือกช่วงเวลาออกกำลังกาย
  Widget _buildWorkoutTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("เวลาออกกำลังกาย:",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),

        ...selectedExerciseTimes.map((time) {
          return Card(
            color: Colors.grey[900],
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                "${daysOfWeek.firstWhere((d) => d['id'] == time['day'])['name']}",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "เริ่ม: ${time['start_time']} - สิ้นสุด: ${time['end_time']}",
                style: TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    selectedExerciseTimes.remove(time);
                  });
                },
              ),
            ),
          );
        }).toList(),

        // ✅ ปุ่มเพิ่มวันและเวลา
        ElevatedButton.icon(
          onPressed: () async {
            String? selectedDay = await _selectDayDialog(context);
            if (selectedDay != null) {
              String? startTime = await pickTime(context);
              if (startTime != null) {
                String? endTime = await pickTime(context);
                if (endTime != null) {
                  setState(() {
                    selectedExerciseTimes.add({
                      "day": selectedDay,
                      "start_time": startTime,
                      "end_time": endTime,
                    });
                  });
                }
              }
            }
          },
          icon: Icon(Icons.add),
          label: Text("เพิ่มช่วงเวลา"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      ],
    );
  }
}
