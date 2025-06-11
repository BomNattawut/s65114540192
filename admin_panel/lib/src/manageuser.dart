import 'package:flutter/material.dart';
import 'package:admin_panel/src/services/auth_service.dart';

import 'package:google_fonts/google_fonts.dart';



class UserManagePage extends StatefulWidget {
  @override
  _UserManagePageState createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  final TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _GetallUser(); // ✅ โหลดข้อมูล Users ทันทีที่เปิดหน้า
  }

  // ✅ ฟังก์ชันดึง Users จาก Backend
  void _GetallUser() async {
    List<Map<String, dynamic>>? fetchedUsers = await _authService.getAllUsers();

    if (fetchedUsers != null) {
      setState(() {
        users = fetchedUsers;
        filteredUsers = users; // ✅ ใช้ข้อมูลที่ดึงมาเป็นค่าเริ่มต้น
      });
    } else {
      print("❌ ไม่สามารถดึงข้อมูลผู้ใช้ได้");
    }
  }

  // ✅ ค้นหาผู้ใช้
  void searchUser(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        return user["username"].toLowerCase().contains(query.toLowerCase()) ||
               user["email"].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }


void deleteUser(int index) async {
  if (index < 0 || index >= users.length) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ ไม่พบผู้ใช้ในระบบ")),
    );
    return;
  }

  String userId = users[index]["id"]; 
  print('user_id:${userId}');
  bool success = await _authService.Deleteuser(userId); 

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ ลบผู้ใช้สำเร็จ")),
    );

    setState(() {
      users.removeAt(index); // ✅ ลบผู้ใช้จาก List
      filteredUsers = List.from(users); // ✅ อัปเดต filteredUsers
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ ไม่สามารถลบผู้ใช้ได้")),
    );
  }
}

  // ✅ ฟังก์ชันเปลี่ยนหน้า Navigation
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
      backgroundColor: Colors.white,
     appBar: AppBar(
      backgroundColor: Colors.orange,
      title: Row(
        children: [
          Icon(Icons.account_circle, color: Colors.white),
          SizedBox(width: 10),
          Text("จัดการผู้ใช้",
              style: TextStyle(color: Colors.white, fontFamily: 'NotoSansThai')),
        ],
      ),
    ),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 ค้นหาผู้ใช้
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: searchUser,
                  style: TextStyle(color: Colors.orange[900], fontFamily: 'NotoSansThai'),
                  decoration: InputDecoration(
                    hintText: "ค้นหาด้วยชื่อผู้ใช้",
                    hintStyle:
                        TextStyle(color: Colors.orange[300], fontFamily: 'NotoSansThai'),
                    filled: true,
                    fillColor: Colors.orange[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.white),
                    Text(" ค้นหา",
                        style:
                            TextStyle(color: Colors.white, fontFamily: 'NotoSansThai')),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // 🔹 รายการผู้ใช้
          Text("รายชื่อผู้ใช้",
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansThai')),
          Divider(color: Colors.orange),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                dataRowColor: MaterialStateProperty.resolveWith(
                    (states) => Colors.orange[50]),
                headingRowColor: MaterialStateProperty.resolveWith(
                    (states) => Colors.orange[200]),
                columns: [
                  DataColumn(
                      label: Text("ID",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                  DataColumn(
                      label: Text("ชื่อผู้ใช้",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                  DataColumn(
                      label: Text("อีเมล",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                  DataColumn(
                      label: Text("เพศ",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                  DataColumn(
                      label: Text("ยืนยัน",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                  DataColumn(
                      label: Text("บทบาท",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                  DataColumn(
                      label: Text("รูปโปรไฟล์",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                  DataColumn(
                      label: Text("การดำเนินการ",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                ],
                rows: filteredUsers.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> user = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(user["id"].toString(),
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                      DataCell(Text(user["username"],
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                      DataCell(Text(user["email"],
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                      DataCell(Text(user["gender"].isNotEmpty ? user["gender"] : "ไม่ระบุ",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                      DataCell(Text(
                          user["email_verified"]
                              ? "✅ ยืนยันแล้ว"
                              : "❌ ยังไม่ยืนยัน",
                          style: TextStyle(
                              color: user["email_verified"]
                                  ? Colors.green
                                  : Colors.red,
                              fontFamily: 'NotoSansThai'))),
                      DataCell(Text(user["is_staff"] ? "แอดมิน" : "ผู้ใช้ทั่วไป",
                          style: TextStyle(
                              color: Colors.orange[900],
                              fontFamily: 'NotoSansThai'))),
                      DataCell(user["profile_image"] != null &&
                              user["profile_image"].isNotEmpty
                          ? Image.network(
                              'http://localhost:8000${user["profile_image"]}',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            )
                          : Text("ไม่มีรูป",
                              style: TextStyle(
                                  color: Colors.orange[300],
                                  fontFamily: 'NotoSansThai'))),
                      DataCell(Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditUserPage(
                                            userData: user,
                                          )));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: Text("แก้ไข",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'NotoSansThai')),
                          ),
                          SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: () => deleteUser(index),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: Text("ลบ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'NotoSansThai')),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
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
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "User"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Party"),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Exercise"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Location"),
          BottomNavigationBarItem(icon: Icon(Icons.comment), label: "Manage Posts"),
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: "Update"),
        ],
      ),
    );
  }
}




class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditUserPage({required this.userData});

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final AuthService _authService = AuthService();

  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;
  late String selectedGender ;
  bool isStaff = false;
  bool emailVerified = false;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.userData["username"]);
    emailController = TextEditingController(text: widget.userData["email"]);
    descriptionController = TextEditingController(text: widget.userData["description"] ?? "");
    selectedGender = (widget.userData["gender"] != null && widget.userData["gender"].trim().isNotEmpty)
    ? widget.userData["gender"]
    : "Other";
    isStaff = widget.userData["is_staff"] ?? false;
    emailVerified = widget.userData["email_verified"] ?? false;
  }

  void _updateUser() async {
    Map<String, dynamic> updatedData = {
      "username": usernameController.text,
      "email": emailController.text,
      "description": descriptionController.text,
      "gender":selectedGender, 
      "is_staff": isStaff,
      "email_verified": emailVerified,
    };

    bool success = await _authService.updateUser(widget.userData["id"], updatedData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ อัปเดตข้อมูลสำเร็จ")));
      Navigator.push(context, MaterialPageRoute(builder: (context)=>UserManagePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ไม่สามารถอัปเดตข้อมูลได้")));
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: Text("เเก้ไขผู้ใช้งาน", style: GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.white))),
      backgroundColor: Colors.orange,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    body: Center(
      child: Container(
        width: 400,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50], // โทนพื้นหลังฟอร์ม
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔶 Username
            Text("ชื่อ", style: GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))),
            TextField(
              controller: usernameController,
              decoration: _buildInputDecoration(),
            ),
            SizedBox(height: 10),

            // 🔶 Email
            Text("อีเมล", style:GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))),
            TextField(
              controller: emailController,
              decoration: _buildInputDecoration(),
            ),
            SizedBox(height: 10),

            // 🔶 Description
            Text("Description", style: GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))),
            TextField(
              controller: descriptionController,
              decoration: _buildInputDecoration(),
            ),
            SizedBox(height: 10),

            // 🔶 Gender Dropdown
            Text("Gender", style: GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedGender,
                isExpanded: true,
                underline: SizedBox(),
                iconEnabledColor: Colors.orange,
                dropdownColor: Colors.white,
                style: TextStyle(color: Colors.orange[900]),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGender = newValue!;
                  });
                },
                items: ["man", "women", "Other"].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 10),

            // 🔶 Checkboxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isStaff,
                      activeColor: Colors.orange,
                      onChanged: (value) => setState(() => isStaff = value!),
                    ),
                    Text("ผู้ดูเเลระบบ", style:GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: emailVerified,
                      activeColor: Colors.orange,
                      onChanged: (value) => setState(() => emailVerified = value!),
                    ),
                    Text("สถานะยืนยันอีเมลเเล้ว", style: GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // 🔶 Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateUser,
                icon: Icon(Icons.save, color: Colors.white),
                label: Text("บันทึก", style: GoogleFonts.notoSansThai(textStyle: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ✅ ฟังก์ชันตกแต่ง TextField
InputDecoration _buildInputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.orange),
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.orange.shade200),
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

}
