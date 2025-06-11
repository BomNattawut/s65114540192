import 'package:flutter/material.dart';
import 'package:admin_panel/src/services/auth_service.dart';

class ManagePartyPage extends StatefulWidget {
  @override
  _ManagePartyPageState createState() => _ManagePartyPageState();
}

class _ManagePartyPageState extends State<ManagePartyPage> {
  List<Map<String, dynamic>> parties = [];
  List<Map<String, dynamic>> filteredParties = [];
  TextEditingController searchController = TextEditingController();
  final AuthService _authService = AuthService();
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchParties(); // โหลดข้อมูลปาร์ตี้
  }

  // ✅ ดึงข้อมูลปาร์ตี้จาก API
  Future<void> _fetchParties() async {
    List<Map<String, dynamic>>? partyList = await _authService.getAllParties();
    print('🎉 รายชื่อปาร์ตี้: ${partyList}');

    if (partyList != null) {
      setState(() {
        parties = partyList;
        filteredParties = parties; // อัปเดตข้อมูลที่ใช้แสดง
      });
    } else {
      print("❌ ไม่สามารถโหลดข้อมูลปาร์ตี้ได้");
    }
  }

  // ✅ ค้นหาปาร์ตี้
  void _searchParties(String query) {
    setState(() {
      filteredParties = parties.where((party) {
        return party["party_name"]
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            party["location"].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // ✅ ลบปาร์ตี้
  void _deleteParty(int partyId) async {
    bool success = await _authService.deleteParty(partyId);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("✅ ลบปาร์ตี้สำเร็จ")));
      _fetchParties(); // โหลดข้อมูลใหม่
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ ไม่สามารถลบปาร์ตี้ได้")));
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
      appBar: AppBar(
        title: Text("🎉 จัดการปาร์ตี้"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // 🔍 Search Bar
            TextField(
              controller: searchController,
              onChanged: _searchParties,
              decoration: InputDecoration(
                labelText: "ค้นหาปาร์ตี้...",
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 10),

            // 🔹 รายการปาร์ตี้
            Expanded(
              child: filteredParties.isEmpty
                  ? Center(child: Text("ไม่มีข้อมูลปาร์ตี้"))
                  : ListView.builder(
                      itemCount: filteredParties.length,
                      itemBuilder: (context, index) {
                        var party = filteredParties[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: Icon(Icons.event,
                                size: 50, color: Colors.orange),
                            title: Text(party["name"],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "📍 สถานที่: ${party["location"]['location_name']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PartyDetailPage(party)));
                                  },
                                  child: Text('รายละเอียด'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteParty(party["id"]),
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

class PartyDetailPage extends StatefulWidget {
  final Map<String, dynamic> party;

  PartyDetailPage(this.party);

  @override
  _PartyDetailPageState createState() => _PartyDetailPageState();
}

class _PartyDetailPageState extends State<PartyDetailPage> {
  List<dynamic> members = []; // รายชื่อสมาชิก
  bool isLoading = true; // เช็คว่ากำลังโหลดข้อมูลอยู่หรือไม่
  final AuthService _authService = AuthService();
  @override
  void initState() {
    super.initState();
    _fetchMembers(widget.party['id']); // โหลดข้อมูลสมาชิกเมื่อหน้าถูกเปิด
  }

  // ✅ ดึงข้อมูลสมาชิกจาก API
  Future<void> _fetchMembers(int party_id) async {
    print("${party_id}");
   List<Map<String, dynamic>>? member = await _authService.getallmember(party_id);
   print('${member}');
    
    if (member != null) {
      setState(() {
         members=member;
         isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียดปาร์ตี้"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15),

              // ✅ ข้อมูลปาร์ตี้
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🎉 ชื่อปาร์ตี้", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("${widget.party["name"]}", style: TextStyle(fontSize: 14)),
                      Divider(),

                      Text("📍 สถานที่", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("${widget.party["location"]["location_name"]}", style: TextStyle(fontSize: 14)),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                          height: 150,
                          child: widget.party["location"]["place_image"] != null &&
                                  widget.party["location"]["place_image"].isNotEmpty
                              ? Image.network(
                                  'http://localhost:8000${widget.party["location"]["place_image"]}',
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.event, size: 80, color: Colors.grey),
                        ),
                      ),
                      Divider(),

                      Text("📅 วันที่จัด", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("${widget.party["date"]}", style: TextStyle(fontSize: 14)),
                      Divider(),

                      Text("ℹ️ รายละเอียด", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("${widget.party["description"]}", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // ✅ รายชื่อสมาชิก
              Text("👥 สมาชิกที่เข้าร่วมปาร์ตี้", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              isLoading
    ? Center(child: CircularProgressIndicator()) // ✅ แสดงโหลดข้อมูล
    : members.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              var member = members[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
  backgroundImage: member['profile_image'] != null && member['profile_image'].isNotEmpty
      ? NetworkImage(member['profile_image']) 
      : null, 
  child: member['profile_image'] == null || member['profile_image'].isEmpty
      ? Icon(Icons.person, color: Colors.orange) // ✅ ใช้ Icon แทนรูป
      : null, 
),

                  title: Text(member["username"], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(member["email"]),
                ),
              );
            },
          )
        : Center(
            child: Text("ยังไม่มีสมาชิกเข้าร่วม", style: TextStyle(color: Colors.grey)),
          ),

            ],
          ),
        ),
      ),
    );
  }
}