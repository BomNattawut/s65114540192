
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import 'package:admin_panel/src/services/auth_service.dart';
import 'package:flutter/material.dart';


class ExercisePlacesPage extends StatefulWidget {
  @override
  _ExercisePlacesPageState createState() => _ExercisePlacesPageState();
}

class _ExercisePlacesPageState extends State<ExercisePlacesPage> {
  List<Map<String, dynamic>> places = [];
  List<Map<String, dynamic>> filteredPlaces = [];
  TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService();
  int _currentIndex = 4;
  TextEditingController _locationTypeController=TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLocations(); // ✅ โหลดข้อมูลสถานที่จาก API
  }

  // ✅ ดึงข้อมูลสถานที่ออกกำลังกายจาก API
  Future<void> _fetchLocations() async {
    List<Map<String, dynamic>>? locationList = await _authService.Getalllocation();
    print('ข้อมูลสถานที่: $locationList');

    if (locationList != null) {
      setState(() {
        places = locationList;
        filteredPlaces = List.from(places); // กำหนดค่าที่ใช้แสดงผล
      });
    } else {
      print("❌ ไม่สามารถโหลดข้อมูลได้");
    }
  }

  // ✅ ฟังก์ชันค้นหาสถานที่
  void _searchPlaces(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPlaces = List.from(places); // รีเซ็ตเมื่อไม่มีการค้นหา
      } else {
        filteredPlaces = places.where((place) {
          return place["location_name"].toLowerCase().contains(query.toLowerCase()) ||
                 place["address"].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
  void _deletelocation(int location_id)async{

    bool success=await _authService.deletelocation(location_id);
    if (success){
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ อัปเดตข้อมูลสำเร็จ")));
       _fetchLocations();
    }
    else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ไม่สามารถลบข้อมูลได้")));
    }

  }

void _addLocationType(String locationType) async{
    bool? success= await _authService.addLocationType(locationType);
    if(success==true){
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ เพิ่มข้อมูลสำเร็จ")));
    }
    else{
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ❌ ไม่สามารถลบข้อมูลได้")));
    }
}
 void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("เพิ่มประเภทสถานที่"),
          content: TextField(
            controller: _locationTypeController,
            decoration: InputDecoration(
              labelText: "ชื่อประเภทสถานที่",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ❌ ปิด Dialog โดยไม่บันทึก
              },
              child: Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () {
                _addLocationType(_locationTypeController.text); // ✅ บันทึกประเภทสถานที่ใหม่
                Navigator.pop(context);
              },
              child: Text("บันทึก"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("สถานที่ออกกำลังกาย"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // 🔍 Search Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(onPressed: (){
                      _showDialog();
                }, label: Text('เพิ่มประเภทสถานที่'),
                icon: Icon(Icons.fitness_center_outlined),
                ),
                SizedBox(width: 15,),
                 ElevatedButton.icon(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder:(context)=>AddLocationPage()));
            }, label: Text('เพิ่มสถานที่'),
            icon: Icon(Icons.add_location),
            ),
              ],
            ),
            SizedBox(height: 20,),
            TextField(
              controller: searchController,
              onChanged: _searchPlaces, // ✅ ใช้ฟังก์ชันค้นหา
              decoration: InputDecoration(
                labelText: "ค้นหาสถานที่...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),

            // 🔹 รายการสถานที่ออกกำลังกาย
            Expanded(
              child: filteredPlaces.isEmpty
                  ? Center(child: Text("ไม่มีข้อมูลสถานที่ออกกำลังกาย"))
                  : ListView.builder(
                      itemCount: filteredPlaces.length,
                      itemBuilder: (context, index) {
                        var place = filteredPlaces[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: place["place_image"] != null && place["place_image"].isNotEmpty
                                ? Image.network(
                                    'http://localhost:8000${place["place_image"]}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.fitness_center, size: 50, color: Colors.grey),
                            title: Text(place["location_name"], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(place["address"]),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(onPressed: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ExercisePlaceDetailPage(place)));
                                }, child: Text('รายละเอียด'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange
                                ),
                                ),
                                SizedBox(width: 10,),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: (){
                                      _deletelocation(place['id']);
                                  }
                                ),
                              ],
                            ),
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

// ✅ หน้ารายละเอียดสถานที่


class ExercisePlaceDetailPage extends StatelessWidget {
  final Map<String, dynamic> place;

  ExercisePlaceDetailPage(this.place);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place["location_name"]),
        backgroundColor: Colors.orange,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ แสดงภาพพร้อมอัตราส่วนที่พอดีกับหน้าจอ
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // ทำให้ขอบภาพโค้งมน
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4, // ปรับให้กว้าง 60% ของหน้าจอ
                    height: 200, // ปรับขนาดให้เล็กลง
                    child: place["place_image"] != null && place["place_image"].isNotEmpty
                        ? Image.network(
                            'http://localhost:8000${place["place_image"]}',
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.fitness_center, size: 60, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 15),

              // ✅ ข้อมูลสถานที่
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📍 ที่อยู่", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("${place["address"]}", style: TextStyle(fontSize: 14)),
                      Divider(),

                      Text("🌍 พิกัด", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.map, size: 18, color: Colors.orange),
                          SizedBox(width: 5),
                          Text("ละติจูด: ${place['latitude']}", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.map, size: 18, color: Colors.orange),
                          SizedBox(width: 5),
                          Text("ลองติจูด: ${place['longitude']}", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Divider(),

                      Text("ℹ️ รายละเอียด", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("${place["description"]}", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

            // ✅ ปุ่มแก้ไขข้อมูลสถานที่
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditExercisePlacePage(place),
                    ),
                  );
                },
                icon: Icon(Icons.edit),
                label: Text("แก้ไขข้อมูลสถานที่"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

class EditExercisePlacePage extends StatefulWidget {
  final Map<String, dynamic> place;
  
  EditExercisePlacePage(this.place);

  @override
  _EditExercisePlacePageState createState() => _EditExercisePlacePageState();
}

class _EditExercisePlacePageState extends State<EditExercisePlacePage> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController latitudeController;
  late TextEditingController longitudeController;
  late TextEditingController descriptionController;
  final AuthService _authService = AuthService();
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.place["location_name"]);
    addressController = TextEditingController(text: widget.place["address"]);
    latitudeController = TextEditingController(text: widget.place["latitude"].toString());
    longitudeController = TextEditingController(text: widget.place["longitude"].toString());
    descriptionController = TextEditingController(text: widget.place["description"]);
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ✅ ฟังก์ชันบันทึกข้อมูล
  void _saveChanges()async {
    print("✅ บันทึกข้อมูลสำเร็จ");
    print("ชื่อสถานที่: ${nameController.text}");
    print("ที่อยู่: ${addressController.text}");
    print("ละติจูด: ${latitudeController.text}");
    print("ลองจิจูด: ${longitudeController.text}");
    print("รายละเอียด: ${descriptionController.text}");
    Map<String,dynamic>updataData={
      "location_name":nameController.text,
      "adress":addressController.text,
      "latitude":latitudeController.text,
      "longtitude":latitudeController.text,
      'description':descriptionController.text
    };
    bool success= await _authService.updatalocation(widget.place['id'], updataData);
    if (success){
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ อัปเดตข้อมูลสำเร็จ")));
         Navigator.push(context, MaterialPageRoute(builder: (context)=>ExercisePlacesPage()));
    }
     // ปิดหน้าแก้ไขหลังจากบันทึกเสร็จ
    else{
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ไม่สามารถอัปเดตข้อมูลได้"))); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("แก้ไขสถานที่"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ แสดงรูปสถานที่
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 150,
                  child: widget.place["place_image"] != null && widget.place["place_image"].isNotEmpty
                      ? Image.network(
                          'http://localhost:8000${widget.place["place_image"]}',
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.fitness_center, size: 60, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(height: 15),

            // ✅ ฟอร์มแก้ไขข้อมูล
            _buildTextField(nameController, "ชื่อสถานที่"),
            _buildTextField(addressController, "ที่อยู่"),
            _buildTextField(latitudeController, "ละติจูด"),
            _buildTextField(longitudeController, "ลองจิจูด"),
            _buildTextField(descriptionController, "รายละเอียด"),

            SizedBox(height: 20),

            // ✅ ปุ่มบันทึกและยกเลิก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: Icon(Icons.save),
                  label: Text("บันทึกการเปลี่ยนแปลง"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.cancel),
                  label: Text("ยกเลิก"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันสร้าง TextField
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class AddLocationPage extends StatefulWidget {
  @override
  _AddLocationPageState createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController citycontroller= TextEditingController();
  final TextEditingController provinceccontroller=TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  
  Uint8List? _imageBytes; // ✅ ใช้แทน File
  final AuthService _authService = AuthService();
  
  // ✅ ประเภทสถานที่ (ดึงจาก API)
  List<Map<String, dynamic>> locationTypes = [];
  String? selectedLocationType;

  @override
  void initState() {
    super.initState();
    _fetchLocationTypes(); // โหลดข้อมูลประเภทสถานที่
  }

  // ✅ โหลดประเภทสถานที่จาก API
  Future<void> _fetchLocationTypes() async {
    List<Map<String, dynamic>>? types = await _authService.getLocationTypes();
    if (types != null) {
      setState(() {
        locationTypes = types;
      });
    } else {
      print("❌ ไม่สามารถโหลดประเภทสถานที่ได้");
    }
  }

  // ✅ เลือกรูปภาพ (ใช้ file_picker แทน image_picker)
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // ✅ อนุญาตให้เลือกเฉพาะไฟล์รูปภาพ
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.first.bytes; // ✅ ใช้ bytes แทน File
      });
    }
  }

  // ✅ ฟังก์ชันเพิ่มสถานที่
  Future<void> _addLocation() async {
    if (nameController.text.isEmpty || addressController.text.isEmpty || selectedLocationType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ กรุณากรอกข้อมูลให้ครบ")),
      );
      return;
    }

    bool success = await _authService.addLocation(
      name: nameController.text,
      address: addressController.text,
      description: descriptionController.text,
      latitude: latitudeController.text,
      city:citycontroller.text,
      province: provinceccontroller.text  , 
      longitude: longitudeController.text,
      locationType: selectedLocationType.toString(),
      imageBytes: _imageBytes, // ✅ เปลี่ยนจาก File เป็น Bytes
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ เพิ่มสถานที่สำเร็จ")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ไม่สามารถเพิ่มสถานที่ได้")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("เพิ่มสถานที่ออกกำลังกาย"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(nameController, "ชื่อสถานที่", Icons.place),
              _buildTextField(addressController, "ที่อยู่", Icons.location_on),
              _buildTextField(descriptionController, "รายละเอียด", Icons.info, maxLines: 3),
              _buildTextField(citycontroller,"เมือง", Icons.location_city),
              _buildTextField(provinceccontroller,"อำเภอ",Icons.location_city),
              _buildTextField(latitudeController, "ละติจูด", Icons.map),
              _buildTextField(longitudeController, "ลองติจูด", Icons.map),

              // ✅ Dropdown เลือกประเภทสถานที่
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedLocationType,
                hint: Text("เลือกประเภทสถานที่"),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLocationType = newValue;
                  });
                },
                items: locationTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type["id"].toString(),
                    child: Text(type["name"]),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.category),
                ),
              ),

              SizedBox(height: 10),
              Text("📸 รูปสถานที่", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

              Center(
                child: ElevatedButton.icon(
                  onPressed: _addLocation,
                  icon: Icon(Icons.save),
                  label: Text("บันทึกสถานที่"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
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

