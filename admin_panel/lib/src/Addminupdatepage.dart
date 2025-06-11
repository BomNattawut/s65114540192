import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // ใช้ kIsWeb
import 'package:flutter/material.dart';
import 'package:admin_panel/src/services/auth_service.dart';

class AdminUpdatePage extends StatefulWidget {
  @override
  _AdminUpdatePageState createState() => _AdminUpdatePageState();
}

class _AdminUpdatePageState extends State<AdminUpdatePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  Uint8List? _imageBytes; // ✅ ใช้แทน File
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> updates = [];
  int _currentIndex =6;
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchUpdates(); // โหลดโพสต์ที่มีอยู่
  }

  // ✅ ดึงข้อมูลโพสต์ทั้งหมด
  Future<void> _fetchUpdates() async {
    List<Map<String, dynamic>>? updateList = await _authService.getAllUpdates();
    if (updateList != null) {
      setState(() {
        updates = updateList;
        
      });
    }
  }


  // ✅ เลือกรูปภาพ (ใช้ FilePicker แทน ImagePicker)
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // ✅ อนุญาตให้เลือกเฉพาะไฟล์รูปภาพ
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes; // ✅ ใช้ Bytes แทน File
      });
    }
  }

  // ✅ ฟังก์ชันโพสต์อัปเดต
  Future<void> _postUpdate() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ กรุณากรอกข้อมูลให้ครบ")));
      return;
    }

    bool success = await _authService.createUpdate(
      title: titleController.text,
      description: descriptionController.text,
      imageBytes: _imageBytes, // ✅ ส่งรูปเป็น Bytes
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ โพสต์อัปเดตสำเร็จ")));
      _fetchUpdates(); // โหลดโพสต์ใหม่
      titleController.clear();
      descriptionController.clear();
      setState(() {
        _imageBytes = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ไม่สามารถโพสต์อัปเดตได้")));
    }
  }
  
  Future<void>deleteupdate(int update_id) async{
      bool? succes= await _authService.deleteupdate(update_id);
      if (succes==true) 
      {
             _fetchUpdates();
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ลบโพสต์อัปเดตสำเร็จ")));
      }
      else{
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ไม่สามารถลบโพสต์อัปเดตได้")));
      }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushNamed(context,'/usermanage');
        break;
      case 2:
        Navigator.pushNamed(context, '/partymanage');
      case 4:
         Navigator.pushNamed(context, '/locationmanage');
      case 3:
          Navigator.pushNamed(context, '/exerciseType');
      case 6:
        Navigator.pushNamed(context, '/adminupdates');
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📢 อัปเดตระบบ (Admin)"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(titleController, "หัวข้ออัปเดต", Icons.title),
              _buildTextField(descriptionController, "รายละเอียด", Icons.description, maxLines: 3),

              // ✅ เลือกรูปภาพ
              SizedBox(height: 10),
              Text("📸 เพิ่มรูปภาพ (ถ้ามี)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_imageBytes!, width: 200, height: 150, fit: BoxFit.cover),
                        )
                      : Container(
                          width: 200,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                        ),
                ),
              ),
              SizedBox(height: 20),

              // ✅ ปุ่มบันทึกโพสต์
              Center(
                child: ElevatedButton.icon(
                  onPressed: _postUpdate,
                  icon: Icon(Icons.send),
                  label: Text("โพสต์อัปเดต"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // ✅ รายการโพสต์ที่มีอยู่
              Text("📋 รายการอัปเดตล่าสุด", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              updates.isEmpty
                  ? Center(child: Text("ยังไม่มีอัปเดต"))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: updates.length,
                      itemBuilder: (context, index) {
                        var update = updates[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: update["image"] != null
                                ? Image.network(
                                    'http://localhost:8000${update["image"]}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.notifications, size: 50, color: Colors.grey),
                            title: Text(update["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(update["description"]),
                            trailing: ElevatedButton.icon(onPressed: (){
                                    deleteupdate(update['id']);
                            }, label: Text('ลบ'),icon: Icon(Icons.delete),),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, 
        onTap: _onTabTapped, 
        backgroundColor: Colors.orange,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        unselectedLabelStyle: TextStyle(color: Colors.grey),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.people, ), label: "User"),
          BottomNavigationBarItem(icon: Icon(Icons.event, ), label: "Party"),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center, ), label: "Exercise"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on,), label: "Location"),
          BottomNavigationBarItem(icon: Icon(Icons.comment), label: "mangepose"),
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: "Update"),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}


