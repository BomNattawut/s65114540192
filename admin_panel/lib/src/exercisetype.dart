import 'package:admin_panel/src/services/auth_service.dart';
import 'package:flutter/material.dart';

class ManageExerciseTypesPage extends StatefulWidget {
  @override
  _ManageExerciseTypesPageState createState() => _ManageExerciseTypesPageState();
}

class _ManageExerciseTypesPageState extends State<ManageExerciseTypesPage> {
  List<Map<String, dynamic>> exerciseTypes = []; // เก็บประเภท

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController=TextEditingController();
  int _currentIndex =3;

  @override
  void initState() {
    super.initState();
    _fetchExerciseTypes(); // โหลดข้อมูลประเภท
  }

  // 📌 โหลดข้อมูลประเภทจาก API
  Future<void> _fetchExerciseTypes() async {
    List<Map<String, dynamic>>? data = await AuthService().getExerciseTypes();
    if (data != null) {
      setState(() {
        exerciseTypes = data;
      });
    }
  }

  // ✅ เพิ่มประเภทใหม่
  void _addExerciseType(String name,String description) async {
    if (nameController.text.isEmpty) return;

    bool? success = await AuthService().addExerciseType(name,description);
    if (success ==true) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ เพิ่มข้อมูลสำเร็จ")));
      _fetchExerciseTypes(); // รีเฟรชข้อมูล
      Navigator.pop(context);
    }
    else{
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ❌ ไม่สามารถเพิ่มข้อมูลได้")));
    }
  }

  // ✅ ลบประเภท
  void _deleteExerciseType(int id) async {
    bool? success = await AuthService().deleteExerciseType(id);
    if (success==true) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ลบข้อมูลสำเร็จ")));
      _fetchExerciseTypes();
      
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ❌ ไม่สามารถลบข้อมูลได้")));
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
      appBar: AppBar(title: Text("จัดการประเภทการออกกำลังกาย"), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 ปุ่มเพิ่มประเภท
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("เพิ่มประเภท"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("เพิ่มประเภท"),
                  content:Column(
                     children: [
                       TextField(controller: nameController, decoration: InputDecoration(labelText: "ชื่อประเภท")),
                        TextField(controller: descriptionController, decoration: InputDecoration(labelText: "คำอธิบาย"))
                     ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text("ยกเลิก")),
                    ElevatedButton(onPressed: ()=>_addExerciseType(nameController.text,descriptionController.text), child: Text("บันทึก"))
                  ],
                ),
              ),
            ),
              ],
            ),
            SizedBox(height: 25),

            // 🔹 แสดงรายการประเภท
            Expanded(
              child: ListView.builder(
                itemCount: exerciseTypes.length,
                itemBuilder: (context, index) {
                  var type = exerciseTypes[index];
                  return ListTile(
                    leading: Icon(Icons.fitness_center, color: Colors.orange),
                    title: Text(type["name"], style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteExerciseType(type["id"]),
                    ),
                  );
                },
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
