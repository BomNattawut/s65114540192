import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MakePartyPage extends StatefulWidget {
  @override
  _MakePartyPageState createState() => _MakePartyPageState();
}

class _MakePartyPageState extends State<MakePartyPage> {
  final TextEditingController _Partnamecontroller = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _finishTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedWorkout;
  List<String> workoutOptions = [];

  // ฟังก์ชันดึงข้อมูลจาก API
  Future<void> fetchWorkoutOptions() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/Smartwityouapp/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          workoutOptions = data.map((item) => item['name'].toString()).toList();
        });
      } else {
        throw Exception('Failed to load workout options');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Future<void> creatparty() async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/party/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _Partnamecontroller.text,
        'workout': _selectedWorkout,
        'date': _dateController.text,
        'start_time': _startTimeController.text,
        'finish_time': _finishTimeController.text,
        'description': _descriptionController.text,
        'location': _locationController.text, // หาก location เป็นตัวเลือกแบบ Dropdown ให้เปลี่ยนเป็น id
      }),
    );
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Party created successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create party: ${response.body}')));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}

  @override
  void initState() {
    super.initState();
    fetchWorkoutOptions(); // เรียกฟังก์ชันเพื่อดึงข้อมูล
  }

  Future<void> createParty() async {
    // ฟังก์ชันสร้างปาร์ตี้ (สามารถเพิ่มการส่งข้อมูลไปยัง API ที่นี่)
    print('Party Created');
  }
  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 0) {
      // ไปที่หน้าสร้างปาร์ตี้
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MakePartyPage()),
      );
    } else {
      // จัดการกรณีอื่น ๆ
      print("Selected tab: $index");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Party', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Make Party', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Party Name
              Text('Party Name:', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              TextFormField(
                controller: _Partnamecontroller,
                decoration: InputDecoration(
                  hintText: 'Click to name your group',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Workout
              Text('Workout:', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              workoutOptions.isEmpty
                  ? CircularProgressIndicator(color: Colors.orange) // แสดงโหลดเมื่อยังไม่ได้ข้อมูล
                  : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: workoutOptions
                          .map((workout) => DropdownMenuItem(
                                value: workout,
                                child: Text(workout, style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWorkout = value;
                        });
                      },
                      hint: Text('Choose workout', style: TextStyle(color: Colors.white54)),
                    ),
              SizedBox(height: 16),

              // Date and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date:', style: TextStyle(color: Colors.white)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            hintText: 'D/M/Y',
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
                  SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Time:', style: TextStyle(color: Colors.white)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _startTimeController,
                          decoration: InputDecoration(
                            hintText: 'Start',
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
                  SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finish Time:', style: TextStyle(color: Colors.white)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _finishTimeController,
                          decoration: InputDecoration(
                            hintText: 'End',
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
              SizedBox(height: 16),

              // Location
              Text('Location:', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Where would you workout?',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.location_on, color: Colors.white54),
                ),
              ),
              SizedBox(height: 16),

              // Description
              Text('Description:', style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Click to add about group',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    createParty();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text('Create Party'),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '',
          ),
        ],
       backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black,
      ),
    );
  }
}
