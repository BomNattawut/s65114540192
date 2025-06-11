import 'dart:typed_data';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:admin_panel/src/services/auth_service.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  bool isLoading = true;
  int totalUsers = 0;
  int totalParties = 0;
  int totalLocations = 0;
  int totalPosts = 0; // ✅ เพิ่มจำนวนโพสต์

  @override
  void initState() {
    super.initState();
    _fetchDashboardData(); // โหลดข้อมูล Dashboard
  }

  // ✅ ดึงข้อมูลจาก API
  Future<void> _fetchDashboardData() async {
    var data = await _authService.getDashboardData();
    if (data != null) {
      setState(() {
        totalUsers = data['total_users'];
        totalParties = data['total_parties'];
        totalLocations = data['total_locations'];
        totalPosts = data['total_pose'];
      });
    }
  }

  // ✅ ฟังก์ชันออกจากระบบ
  Future<void> _logout() async {
    await _authService.logout(); // ลบ Token ออกจากระบบ
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (route) => false); // กลับไปหน้า Login
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
        Navigator.pushNamed(context, '/usermanage');
        break;
      case 2:
        Navigator.pushNamed(context, '/partymanage');
        break;
      case 3:
        Navigator.pushNamed(context, '/exerciseType');
        break;
      case 4:
        Navigator.pushNamed(context, '/locationmanage');
        break;
      case 5:
        Navigator.pushNamed(context, '/manageuserpost');
        break;
      case 6:
        Navigator.pushNamed(context, '/adminupdates');
        break;
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.orange,
      title: Text("แดชบอร์ด",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansThai')),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.account_circle, size: 30, color: Colors.white),
          onSelected: (String choice) {
            if (choice == 'profile') {
              Navigator.pushNamed(context, '/adminprofile');
            } else if (choice == 'logout') {
              _logout();
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
                value: 'profile',
                child: Text('👤 โปรไฟล์', style: TextStyle(fontFamily: 'NotoSansThai'))),
            PopupMenuItem(
                value: 'logout',
                child: Text('🚪 ออกจากระบบ', style: TextStyle(fontFamily: 'NotoSansThai'))),
          ],
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📌 สรุปข้อมูลทั้งหมด",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                  fontFamily: 'NotoSansThai')),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              summaryCard("👤 ผู้ใช้ทั้งหมด", totalUsers.toString()),
              summaryCard("🎉 ปาร์ตี้ทั้งหมด", totalParties.toString()),
              summaryCard("📍 สถานที่ทั้งหมด", totalLocations.toString()),
              summaryCard("📝 โพสต์ทั้งหมด", totalPosts.toString()),
            ],
          ),
          SizedBox(height: 20),
          Text("📊 กราฟแสดงผล",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                  fontFamily: 'NotoSansThai')),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: lineChartWidget()),
              SizedBox(width: 10),
              Expanded(child: barChartWidget()),
            ],
          ),
        ],
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

  // ✅ การ์ดสรุปข้อมูล
 Widget summaryCard(String title, String value) {
  return Container(
    width: 160,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.orange),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.orange.withOpacity(0.1),
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
                fontFamily: 'NotoSansThai')),
        SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'NotoSansThai')),
      ],
    ),
  );
}
  // ✅ กราฟเส้น
Widget lineChartWidget() {
  return Container(
    height: 250,
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.orange.shade100),
      borderRadius: BorderRadius.circular(10),
    ),
    child: LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 50), FlSpot(1, 80), FlSpot(2, 150), FlSpot(3, 220), FlSpot(4, 300)],
            isCurved: true,
            barWidth: 3,
            color: Colors.deepOrange,
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}

  // ✅ กราฟแท่ง
  Widget barChartWidget() {
  return Container(
    height: 250,
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.orange.shade100),
      borderRadius: BorderRadius.circular(10),
    ),
    child: BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: totalUsers.toDouble(), color: Colors.orange)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: totalParties.toDouble(), color: Colors.blue)
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: totalLocations.toDouble(), color: Colors.green)
          ]),
        ],
      ),
    ),
  );
}

}

class AdminProfilePage extends StatefulWidget {
  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? adminData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile(); // ✅ โหลดข้อมูลโปรไฟล์
  }

  // ✅ ดึงข้อมูลโปรไฟล์ Admin
  Future<void> _fetchAdminProfile() async {
    var data = await _authService.getAdminProfile();
    if (data != null) {
      setState(() {
        adminData = data;
        isLoading = false;
      });
    }
  }

  // ✅ ฟังก์ชันออกจากระบบ
  Future<void> _logout() async {
    bool? success = await _authService.logout();
    if (success == true) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (route) => false); // ✅ กลับไปหน้า Login
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("โปรไฟล์ผู้ดูแล",
          style: TextStyle(fontFamily: 'NotoSansThai', color: Colors.white)),
      backgroundColor: Colors.orange,
       leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
    ),
    backgroundColor: Colors.orange[50],
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange[100],
                    backgroundImage: adminData?["profile_image"] != null
                        ? NetworkImage(
                            "http://localhost:8000${adminData!["profile_image"]}")
                        : null,
                    child: adminData?["profile_image"] == null
                        ? Icon(Icons.person,
                            size: 50, color: Colors.orange[800])
                        : null,
                  ),
                ),
                SizedBox(height: 24),

                _buildProfileRow("👤 ชื่อผู้ใช้", adminData?["username"]),
                _buildProfileRow("📧 อีเมล", adminData?["email"]),
                _buildProfileRow("📝 คำอธิบาย",
                    adminData?["description"] ?? "ไม่มีข้อมูล"),

                SizedBox(height: 30),

                // ✅ ปุ่มแก้ไขโปรไฟล์
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditAdminProfilePage(adminData!)));
                    },
                    icon: Icon(Icons.edit, color: Colors.white),
                    label: Text("แก้ไขโปรไฟล์",
                        style: TextStyle(
                            fontFamily: 'NotoSansThai', color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // ✅ ปุ่มออกจากระบบ
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: Icon(Icons.logout, color: Colors.white),
                    label: Text("ออกจากระบบ",
                        style: TextStyle(
                            fontFamily: 'NotoSansThai', color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}


Widget _buildProfileRow(String title, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: Colors.orange),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "$title: $value",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'NotoSansThai',
              color: Colors.orange[900],
            ),
          ),
        ),
      ],
    ),
  );
}

}

class EditAdminProfilePage extends StatefulWidget {
  final Map<String, dynamic> adminData;

  EditAdminProfilePage(this.adminData);

  @override
  _EditAdminProfilePageState createState() => _EditAdminProfilePageState();
}

class _EditAdminProfilePageState extends State<EditAdminProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  Uint8List? _imageBytes;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.adminData["username"] ?? "";
    emailController.text = widget.adminData["email"] ?? "";
    descriptionController.text = widget.adminData["description"] ?? "";
  }

  // ✅ เลือกรูปภาพ
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes;
      });
    }
  }

  // ✅ อัปเดตข้อมูลโปรไฟล์
  Future<void> _updateProfile() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ กรุณากรอกข้อมูลให้ครบ")),
      );
      return;
    }

    bool success = await _authService.updateAdminProfile(
      username: nameController.text,
      email: emailController.text,
      description: descriptionController.text,
      imageBytes: _imageBytes,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ อัปเดตโปรไฟล์สำเร็จ")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ไม่สามารถอัปเดตโปรไฟล์ได้")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("แก้ไขโปรไฟล์"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _imageBytes != null
                      ? MemoryImage(_imageBytes!)
                      : widget.adminData["profile_image"] != null
                          ? NetworkImage("http://localhost:8000${widget.adminData["profile_image"]}") as ImageProvider
                          : null,
                          child: widget.adminData["profile_image"] == null
                          ? Icon(Icons.person,
                              size: 40, color: Colors.white) 
                          : null,
                  
                ),
              ),
            ),
            SizedBox(height: 20),
            
            _buildTextField(nameController, "ชื่อผู้ใช้", Icons.person),
            _buildTextField(emailController, "อีเมล", Icons.email),
            _buildTextField(descriptionController, "คำอธิบาย", Icons.info, maxLines: 3),
            
            SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: _updateProfile,
                icon: Icon(Icons.save),
                label: Text("บันทึกข้อมูล"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันสร้าง TextField
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