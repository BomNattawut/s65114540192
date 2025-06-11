import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PartyFeedPage extends StatefulWidget {
  @override
  _PartyFeedPageState createState() => _PartyFeedPageState();
}

class _PartyFeedPageState extends State<PartyFeedPage> {
  List<Map<String, dynamic>> posts = [];
  Timer? _timer;
  String? Userid;
  TextEditingController commentcontroller = TextEditingController();
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchPosts();
    loadUserId();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchPosts();
    });
  }

  Future<void> toggleLike(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/Like/$postId/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // ✅ อัปเดตจำนวนไลค์ และสถานะว่าไลค์หรือยัง
          posts = posts.map((post) {
            if (post["id"] == postId) {
              post["likes_count"] = data["likes_count"];
              post["liked"] = data["liked"];
            }
            return post;
          }).toList();
        });
        fetchPosts();
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');
    setState(() {
      Userid = userId;
    });
  }

  Future<void> fetchPosts() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/partyposts/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        isLoading = false;
        final List<dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes))['posts'] ?? [];

        print('📢 รายการโพสต์: $data');
        setState(() {
          posts = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> sendComment(int postId, String commentText) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');

    if (commentText.trim().isEmpty) return; // ✅ ป้องกันส่งค่าว่าง

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/add_comment/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'post_id': postId.toString(),
          'user_id': userId,
          'comment': commentText,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ ส่งความคิดเห็นสำเร็จ');
        fetchPosts(); // ✅ โหลดโพสต์ใหม่ เพื่ออัปเดตคอมเมนต์
      } else {
        print('❌ ไม่สามารถส่งความคิดเห็นได้: ${response.body}');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> deletepost(int post_id) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? userId = prefs.getString('userid');
    print('โพสIDที่จะส่งไปbackend${post_id}');
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/deletepost/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'userId': userId ?? '',
        },
        body: jsonEncode({
          'post_id': post_id.toString(),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ ลบโพสเเล้ว');
        fetchPosts(); // ✅ โหลดโพสต์ใหม่ เพื่ออัปเดตคอมเมนต์
      } else {
        print('❌ ไม่สามารถลบโพสต์ได้: ${response.body}');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  void confirmDeletePost(int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("🗑️ ยืนยันการลบ"),
        content: Text("คุณต้องการลบโพสต์นี้ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () {
              print('โพสID${postId}');
              Navigator.pop(context);
              deletepost(postId);
            },
            child: Text("ลบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
    backgroundColor: Colors.orange,
    title: Text(
      "📢 โพสกิจกรรม",
      style: GoogleFonts.notoSansThai(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
  backgroundColor: Colors.grey[900],
  body: isLoading
      ? const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        )
      : posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed, size: 80, color: Colors.grey[600]),
                  SizedBox(height: 16),
                  Text(
                    'ไม่พบปาร์ตี้',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var post = posts[index];
                var userData = post['user_data'] ?? {};
                var username = userData["username"] ?? "ไม่ทราบชื่อ";
                var profileImage = userData["profile_image"];
                var likecount = post['likes'].length;
                bool isLike = post['likes'] is List &&
                    post['likes'].any((like) => like['user'] == Userid);
                bool isOwner = post["user"] == Userid;

                return Card(
                  margin: EdgeInsets.all(12),
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 💖 ไลค์ & ลบ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$likecount', style: TextStyle(color: Colors.white)),
                            IconButton(
                              icon: Icon(
                                isLike ? Icons.favorite : Icons.favorite_border,
                                color: isLike ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                toggleLike(post["id"]);
                              },
                            ),
                            if (isOwner)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => confirmDeletePost(post["id"]),
                              ),
                          ],
                        ),

                        // 👤 ข้อมูลผู้โพสต์
                        ListTile(
                          leading: profileImage != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    'http://10.0.2.2:8000$profileImage',
                                  ),
                                )
                              : CircleAvatar(child: Icon(Icons.person)),
                          title: Text(username,
                              style: GoogleFonts.notoSansThai(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          subtitle: Text(post['text'] ?? "",
                              style: GoogleFonts.notoSansThai(
                                  color: Colors.white70)),
                        ),

                        // 🖼 รูปภาพ
                        if ((post['images'] ?? []).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: post['images'].length == 1
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      'http://10.0.2.2:8000${post['images'][0]}',
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: post['images'].length,
                                      itemBuilder: (context, i) {
                                        return Container(
                                          margin: EdgeInsets.only(right: 10),
                                          width: 160,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              'http://10.0.2.2:8000${post['images'][i]}',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),

                        // 💬 ความคิดเห็น
                        if (post["comments"] != null &&
                            post["comments"].isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(color: Colors.grey),
                                Text("💬 ความคิดเห็น",
                                    style: GoogleFonts.notoSansThai(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold)),

                                SizedBox(height: 6),
                                Container(
                                  height: 140,
                                  child: ListView.builder(
                                    itemCount: post["comments"].length,
                                    itemBuilder: (context, index) {
                                      var comment = post["comments"][index];
                                      return ListTile(
                                        leading: Icon(Icons.comment,
                                            color: Colors.grey),
                                        title: Text(comment["user"],
                                            style: GoogleFonts.notoSansThai(
                                                color: Colors.white)),
                                        subtitle: Text(comment["text"],
                                            style: GoogleFonts.notoSansThai(
                                                color: Colors.white70)),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 📝 ช่องแสดงความคิดเห็น
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentcontroller,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[700],
                                  hintText: "แสดงความคิดเห็น...",
                                  hintStyle:
                                      TextStyle(color: Colors.grey[300]),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.send, color: Colors.orange),
                              onPressed: () {
                                sendComment(post['id'], commentcontroller.text);
                                commentcontroller.clear();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
);

  }
}

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  TextEditingController _postController = TextEditingController();
  List<File> _images = [];
  String _postType = "Memory"; // ✅ Default เป็นโพสต์ความทรงจำ

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _submitPost() async {
    if (_postController.text.isEmpty && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("กรุณาเพิ่มข้อความหรือรูปภาพก่อนโพสต์!")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    var request = http.MultipartRequest(
      "POST",
      Uri.parse('http://10.0.2.2:8000/Smartwityouapp/create_post/'),
    );
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.fields["text"] = _postController.text;
    request.fields["post_type"] = _postType; // ✅ ส่งประเภทโพสต์ไปด้วย

    for (var image in _images) {
      request.files
          .add(await http.MultipartFile.fromPath("images", image.path));
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ โพสต์สำเร็จ!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ไม่สามารถโพสต์ได้")),
        );
      }
    } catch (e) {
      print("⚠️ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ มีข้อผิดพลาดเกิดขึ้น!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📝 สร้างโพสต์")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _postType,
              onChanged: (String? newValue) {
                setState(() {
                  _postType = newValue!;
                });
              },
              items: ["Memory", "Party Completed"].map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _postController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "เขียนโพสต์ของคุณ...",
              ),
            ),
            SizedBox(height: 10),
            if (_images.isNotEmpty)
              Wrap(
                children: _images.map((image) {
                  return Padding(
                    padding: EdgeInsets.all(5),
                    child: Image.file(image, width: 100, height: 100),
                  );
                }).toList(),
              ),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text("เพิ่มรูป"),
            ),
            ElevatedButton(
              onPressed: _submitPost,
              child: Text("✅ โพสต์"),
            ),
          ],
        ),
      ),
    );
  }
}
