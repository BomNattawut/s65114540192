import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:myflutterproject/scr/selecatlocationpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/notification.dart';
import 'package:myflutterproject/scr/searchparty.dart';
import 'package:intl/intl.dart';
import 'package:myflutterproject/scr/Freind.dart';
import 'package:url_launcher/url_launcher.dart';

class MakePartyPage extends StatefulWidget {
  final Map<String, dynamic>? selectedPlace; // รับข้อมูลสถานที่
  final String? partyName;
  final String? partyDate;
  final String? startTime;
  final String? finishTime;
  final String? description; // เพิ่มตรงนี้
  const MakePartyPage({
    super.key,
    this.selectedPlace,
    this.partyName,
    this.partyDate,
    this.startTime,
    this.finishTime,
    this.description,
  }); // เพิ่มตรงนี้
  @override
  _MakePartyPageState createState() => _MakePartyPageState();
}

class _MakePartyPageState extends State<MakePartyPage> {
  int _currentindex = 0;
  final TextEditingController _Partnamecontroller = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _finishTimeController = TextEditingController();
  Map<String, dynamic>? _selectedPlace;

  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedWorkout;
  List<Map<String, dynamic>> workoutOptions = []; //เเก้ตรงนี้
  // ฟังก์ชันดึงข้อมูลจาก API
  Future<void> _selectDate(BuildContext context) async {
    //เเก้ตรงนี้
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd')
            .format(picked); // แปลงวันที่เป็น YYYY-MM-DD
      });
    }
  }

  Future<void> _selectTime(
      //เเก้ตรงนี้
      BuildContext context,
      TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final formattedTime = DateFormat('HH:mm:ss').format(
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
        );
        controller.text = formattedTime; // แปลงเวลาเป็น HH:mm:ss
      });
    }
  }

  Future<void> fetchWorkoutOptions() async {
    final prefs = await SharedPreferences.getInstance();
  
    String? accessToken = prefs.getString('access_token');
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/fechworkout/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('ค่าที่ส่งมา:$data');
        setState(() {
          workoutOptions = data
              .map((item) => {'id': item['id'], 'name': item['name']})
              .toList();
        });
      } else {
        throw Exception('Failed to load workout options');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> creatparty() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
   
    // ดึงค่า user_id จาก SharedPreferences
    
    if (_Partnamecontroller.text.isEmpty ||
        _selectedWorkout == null ||
        _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')));
      return;
    } else {
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/Smartwityouapp/creatparty/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
          body: json.encode({
            'name': _Partnamecontroller.text,
            'exercise_type': _selectedWorkout,
            'date': _dateController.text,
            'start_time': _startTimeController.text,
            'finish_time': _finishTimeController.text,
            'description': _descriptionController.text,
            'location': _selectedPlace?['id'],
            'leader': userId,
            // เพิ่มฟิลด์ leader
          }),
        );

        final data = jsonDecode(response.body);
print('data: $data');

if (response.statusCode == 401 && data.containsKey("auth_url")) {
      String authUrl = data["auth_url"];
      print('url เชื่อมcalendar${authUrl}');
      print("🔹 Google Auth URL: $authUrl");
      await launchUrl(Uri.parse(authUrl));
     
    }
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Party created successfully!')));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()), //เเก้ตรงนี้
            (route) => false, // ลบ Stack ทั้งหมด
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to create party: ${response.body}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWorkoutOptions();
    _selectedPlace = widget.selectedPlace;
    _Partnamecontroller.text = widget.partyName ?? '';
    _dateController.text = widget.partyDate ?? '';
    _startTimeController.text = widget.startTime ?? '';
    _finishTimeController.text = widget.finishTime ?? '';
    _descriptionController.text = widget.description ?? ''; // เพิ่มตรงนี้
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
    } else if(_currentindex == 3){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>Freindpage()));
    }else if(_currentindex ==4){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>notification()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('สร้างปาร์ตี้', style:  GoogleFonts.notoSansThai(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),),
        
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Party Name
              const Text('ชื่อปาร์ตี้:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _Partnamecontroller,
                decoration: InputDecoration(
                  hintText: 'เพิ่มชื่อปาร์ตี้',
                 
                  hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 186, 186, 186)),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Workout
              const Text('Workout:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              workoutOptions.isEmpty
                  ? const CircularProgressIndicator(
                      color: Colors.orange) // แสดงโหลดเมื่อยังไม่ได้ข้อมูล
                  : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        icon: Icon(Icons.fitness_center,color: Colors.orange,),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      dropdownColor: const Color.fromARGB(255, 63, 63, 63),
                      items: workoutOptions
                          .map((workout) => DropdownMenuItem(
                                value: workout['id'].toString(),
                                child: Text(workout['name'],
                                    style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWorkout = value;
                        });
                      },
                      hint: const Text('เลือกการออก',
                          style: TextStyle(color: Colors.white54)),
                    ),
              const SizedBox(height: 16),

              // Date and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('วันเวลา:', style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dateController,
                          onTap: () => _selectDate(context),
                          decoration: InputDecoration(
                            hintText: 'D/M/Y',
                            icon: Icon(Icons.calendar_month),
                            hintStyle: const TextStyle(
                                color:
                                    Color.fromARGB(255, 186, 186, 186)),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('เวลาเริ่ม:',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _startTimeController,
                          onTap: () =>
                              _selectTime(context, _startTimeController),
                          decoration: InputDecoration(
                            hintText: 'เริ่ม',
                            icon: Icon(Icons.access_time),
                            hintStyle: const TextStyle(
                                color:
                                    Color.fromARGB(255, 186, 186, 186)),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('เวลาสิ้นสุด:',
                            style: TextStyle(color: Colors.white),),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _finishTimeController,
                          onTap: () =>
                              _selectTime(context, _finishTimeController),
                          decoration: InputDecoration(
                            hintText: 'สิ้นสุด',
                            icon: Icon(Icons.access_time),
                            hintStyle: const TextStyle(
                                color:
                                    Color.fromARGB(255, 186, 186, 186)),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              Row(
                children: [

              Text('สถานที:',style: TextStyle(color: Colors.white),),
              SizedBox(width: 20,),    
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Selecatlocationpage(
                        currentPartyName: _Partnamecontroller.text,
                        currentPartyDate: _dateController.text,
                        currentStartTime: _startTimeController.text,
                        currentFinishTime: _finishTimeController.text,
                        currentDescription:
                            _descriptionController.text, //เพิ่มตรงนี้
                      ),
                    ),
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      _selectedPlace = result; // เก็บข้อมูลสถานที่ทั้งหมด
                    });
                  }
                },
                label: Text(
                  _selectedPlace?['location_name'] ?? "เลือกสถานที่",
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                   backgroundColor:  const Color.fromARGB(255, 60, 59, 59)
                ),
                icon:  Icon(Icons.place,color: Colors.orange,),
              ),
                ],
              ),

              SizedBox(height: 16,),
              // Description
              const Text('คำอธิบาย:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  icon: Icon(Icons.description,color: Colors.orange,),
                  hintText: 'เพิ่มคำอธิบายของปาร์ตี้',
                  hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 186, 186, 186)),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    creatparty();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  icon: Icon(Icons.event_available),
                  label:  Text('สร้างปาร์ตี้',style:  GoogleFonts.notoSansThai(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 39, 38, 38),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentindex,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'makeparty',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Searchparty',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'add firneds',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notfication',
          ),
        ],
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
      ),
    );
  }
}
