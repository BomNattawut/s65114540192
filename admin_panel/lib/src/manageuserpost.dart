import 'package:flutter/material.dart';
import 'package:admin_panel/src/services/auth_service.dart';

class ManageUserPostsPage extends StatefulWidget {
  @override
  _ManageUserPostsPageState createState() => _ManageUserPostsPageState();
}

class _ManageUserPostsPageState extends State<ManageUserPostsPage> {
  List<Map<String, dynamic>> posts = [];
  final AuthService _authService = AuthService();
  bool isLoading=true;
  int _currentIndex=5;

  @override
  void initState() {
    super.initState();
    loadPosts(); // ✅ โหลดโพสต์เมื่อเปิดหน้า
  }

  // ✅ ดึงโพสต์จากฟังก์ชัน `getUserPosts()`
  Future<void> loadPosts() async {
    try {
      List<Map<String, dynamic>>? fetchedPosts = await _authService.getUserPosts();
      if (fetchedPosts != null) {
        setState(() {
          posts = fetchedPosts;
          isLoading=false;
        });
      } else {
        print("❌ ไม่สามารถโหลดโพสต์ได้");
      }
    } catch (e) {
      print("⚠️ เกิดข้อผิดพลาด: $e");
    }
  }

  // ✅ ฟังก์ชันลบโพสต์
  Future<void> deletePost(int postId) async {
    try {
      bool? success = await _authService.deletePost(postId);
      if (success==true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ลบโพสต์สำเร็จ")));
        loadPosts(); // โหลดโพสต์ใหม่หลังจากลบ
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ ไม่สามารถลบโพสต์ได้")));
      }
    } catch (e) {
      print("⚠️ เกิดข้อผิดพลาดในการลบโพสต์: $e");
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

  // ✅ ฟังก์ชันแสดง Dialog ยืนยันการลบ
  void confirmDelete(int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("⚠️ ยืนยันการลบ"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?"),
        actions: [
          TextButton(
            child: Text("ยกเลิก"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("ลบ"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deletePost(postId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📢 จัดการโพสต์ของผู้ใช้"),
        backgroundColor: Colors.orange,
      ),
      body: posts.isEmpty
          ? Center(child: isLoading ==true? CircularProgressIndicator():Text('ไม่มีรายการโพสต์',style: TextStyle(fontSize: 20),))
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return buildPostItem(post);
              },
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
          BottomNavigationBarItem(icon: Icon(Icons.comment), label: "mangepose"),
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: "Update"),
        ],
      ), 
    );
  }

  // ✅ Widget แสดงโพสต์ พร้อมปุ่มลบ
 Widget buildPostItem(Map<String, dynamic> post) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 ผู้ใช้ที่โพสต์
          Row(
            children: [
              post["user_data"]["profile_image"] != null
                  ? ClipOval(
                      child: Image.network(
                        "http://localhost:8000${post["user_data"]["profile_image"]}",
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.account_circle,
                      size: 45, color: Colors.orange[200]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  post["user_data"]["username"] ?? "ไม่ทราบชื่อ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'NotoSansThai',
                    color: Colors.orange[900],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => confirmDelete(post["id"]),
              ),
            ],
          ),
          SizedBox(height: 12),

          // 🔹 ข้อความโพสต์
          Text(
            post["text"] ?? "ไม่มีข้อความ",
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'NotoSansThai',
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),

          // 🔹 แสดงรูปถ้ามี
          if (post["images"] != null && post["images"].isNotEmpty) ...[
            Container(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: post["images"].length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "http://localhost:8000${post["images"][index]}",
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
          ],

          // 🔹 วันที่สร้าง
          Text(
            "📅 โพสต์เมื่อ: ${post["created_at"]}",
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'NotoSansThai',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  );
}

}
