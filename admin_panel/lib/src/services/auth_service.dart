import 'dart:convert';
import 'dart:io';
//import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';


class AuthService {
  final String baseUrl =
      "http://localhost:8000"; // ✅ เปลี่ยนเป็น URL ของ Backend

  Future<bool> loginAdmin(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/Smartwityouapp/admin-login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String accessToken = data["access"];
      String refreshToken = data["refresh"];

      // ✅ บันทึก Token ลง SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      return true; // ✅ Login สำเร็จ
    } else {
      return false; // ❌ Login ไม่สำเร็จ
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/admin-refresh/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String newAccessToken = data["access"];

      await prefs.setString('access_token', newAccessToken);
      return true;
    } else {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getAllUsers() async {
    String? token = await getAccessToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(
          "$baseUrl/Smartwityouapp/admingetalluser/"), // ✅ เปลี่ยนเป็น URL API ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> usersData = jsonDecode(utf8.decode(response.bodyBytes));
      print('ข้อมูลuser:${usersData}');
      return usersData.cast<Map<String, dynamic>>();
    } else {
      return null;
    }
  }

  Future<bool> updateUser(
      String userId, Map<String, dynamic> updatedData) async {
    String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse(
          "$baseUrl/Smartwityouapp/EditUser/$userId/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(updatedData),
    );

    return response.statusCode == 200;
  }

  Future<bool> Deleteuser(String userId) async {
    String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse(
          "$baseUrl/Smartwityouapp/AdmindeleteUser/$userId/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>?> Getalllocation() async {
    String? token = await getAccessToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(
          "$baseUrl/Smartwityouapp/fechlocations/"), // ✅ เปลี่ยนเป็น URL API ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> locationData = jsonDecode(utf8.decode(response.bodyBytes));
      print('ข้อมูลสถานที่:${locationData}');
      return locationData.cast<Map<String, dynamic>>();
    } else {
      return null;
    }
  }

  Future<bool> updatalocation(
      int locationId, Map<String, dynamic> updatedData) async {
    String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse(
          "$baseUrl/Smartwityouapp/Adminupdatelocation/$locationId/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(updatedData),
    );

    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>?> getAllParties() async {
    String? token = await getAccessToken();
    if (token == null) return null;
    final response = await http
        .get(Uri.parse("$baseUrl/Smartwityouapp/fecthallparty/"), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });
    if (response.statusCode == 200) {
      List<dynamic> partydata = jsonDecode(utf8.decode(response.bodyBytes));
      return partydata.cast<Map<String, dynamic>>();
    } else {
      return null;
    }
  }

  Future<bool> deleteParty(int party_id) async {
    String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse(
          "$baseUrl/Smartwityouapp/admindeleteparty/$party_id/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> deletelocation(int location_id) async {
    String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse(
          "$baseUrl/Smartwityouapp/Admindeletelocation/$location_id/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> addLocation({
    required String name,
    required String address,
    required String description,
    required String latitude,
    required String longitude,
    required String locationType,
    Uint8List? imageBytes,
    required String city,
    required province,
  }) async {
    String? token = await getAccessToken();
    if (token == null) return false;

    var uri = Uri.parse("$baseUrl/Smartwityouapp/Adminaddlocation/");
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['location_name'] = name
      ..fields['address'] = address
      ..fields['description'] = description
      ..fields['city'] = city
      ..fields['province'] = province
      ..fields['latitude'] = latitude
      ..fields['longitude'] = longitude
      ..fields['exercise_type'] = locationType; // ✅ เพิ่ม locationType

    // ✅ ตรวจสอบและเพิ่มรูปภาพ
    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'place_image', // ✅ ชื่อฟิลด์ที่ API ใช้
        imageBytes,
        filename: "location_image.jpg",
        contentType: MediaType('image', 'jpeg'), // ✅ กำหนด MIME Type
      ));
    }

    var response = await request.send();

    // ✅ Debug Response
    String responseBody = await response.stream.bytesToString();
    print("Response Status: ${response.statusCode}");
    print("Response Body: $responseBody");

    return response.statusCode == 201;
  }

  Future<List<Map<String, dynamic>>?> getLocationTypes() async {
    String? token = await getAccessToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(
          "$baseUrl/Smartwityouapp/fechexercisepalcetype/"), // ✅ เปลี่ยนเป็น URL API ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> exercise_type = jsonDecode(utf8.decode(response.bodyBytes));
      return exercise_type.cast<Map<String, dynamic>>();
    } else {
      return null;
    }
  }

  Future<bool?> addLocationType(String locationName) async {
    String? token = await getAccessToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse(
          "$baseUrl/Smartwityouapp/Adminaddlocationtype/"), // ✅ เปลี่ยน URL API ให้ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(
          {"location_name": locationName}), // ✅ ส่งข้อมูลเป็น JSON Object
    );

    if (response.statusCode == 201) {
      print("✅ เพิ่มประเภทสถานที่สำเร็จ");
      return true;
    } else {
      print("❌ ไม่สามารถเพิ่มประเภทสถานที่ได้: ${response.statusCode}");
      print("Response: ${response.body}");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getExerciseTypes() async {
    String? token = await getAccessToken();
    if (token == null) return null;
    final response = await http.get(
      Uri.parse(
          "$baseUrl/Smartwityouapp/fechworkout/"), // ✅ เปลี่ยนเป็น URL API ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> exercise_type = jsonDecode(utf8.decode(response.bodyBytes));
      return exercise_type.cast<Map<String, dynamic>>();
    } else {
      return null;
    }
  }

  Future<bool?> addExerciseType(String name, String description) async {
    String? token = await getAccessToken();
    if (token == null) return null;

    final response = await http.post(
      Uri.parse(
          "$baseUrl/Smartwityouapp/AddExercisetype/"), // ✅ เปลี่ยน URL API ให้ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "description": description
      }), // ✅ ส่งข้อมูลเป็น JSON Object
    );

    if (response.statusCode == 201) {
      print("✅ เพิ่มประเภทสถานที่สำเร็จ");
      return true;
    } else {
      print("❌ ไม่สามารถเพิ่มประเภทสถานที่ได้: ${response.statusCode}");
      print("Response: ${response.body}");
      return false;
    }
  }

  Future<bool?>deleteExerciseType(int exercise_typeId)async{
    String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse(
          "$baseUrl/Smartwityouapp/deleteExercisetype/$exercise_typeId/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 200;

  }

  Future<List<Map<String, dynamic>>?> getallmember(int party_id) async{
    String? token = await getAccessToken();
    if (token == null) return null;
    final response = await http.post(
      Uri.parse(
          "$baseUrl/Smartwityouapp/Admingetallmember/"), // ✅ เปลี่ยนเป็น URL API ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        
      },
      body: jsonEncode({
         'partyid':party_id.toString()
      })
      
    );

    if (response.statusCode == 200) {
      List<dynamic> members = jsonDecode(utf8.decode(response.bodyBytes));
      print(members);
      return members.cast<Map<String, dynamic>>();
    } else {
      return null;
    }

  }

   Future<List<Map<String, dynamic>>?> getAllUpdates() async {
    String? token = await getAccessToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/Smartwityouapp/system_updates/"), // URL API Django
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
       final decodedData = utf8.decode(response.bodyBytes); // ✅ แปลงเป็น UTF-8
      final jsonData = jsonDecode(decodedData);
      print(jsonData); // ✅ แปลง String เป็น JSON
      return List<Map<String, dynamic>>.from(jsonData);
    } else {
      print("❌ ไม่สามารถโหลดอัปเดตระบบได้: ${response.body}");
      return null;
    }
  }
  Future<bool> createUpdate({
  required String title,
  required String description,
  File? image,
  Uint8List? imageBytes, // ✅ ใช้รองรับภาพแบบ bytes (Web)
}) async {
  String? token = await getAccessToken();
  if (token == null) return false;

  var request = http.MultipartRequest(
    "POST",
    Uri.parse("$baseUrl/Smartwityouapp/system_updates/"),
  );

  request.headers.addAll({
    "Authorization": "Bearer $token",
  });

  request.fields["title"] = title;
  request.fields["description"] = description;

  // ✅ เช็คว่าเป็น Mobile หรือ Web
  if (!kIsWeb && image != null) {
    // 🔹 อัปโหลดรูปจากไฟล์ (สำหรับ Mobile)
    request.files.add(await http.MultipartFile.fromPath("image", image.path));
  } else if (kIsWeb && imageBytes != null) {
    // 🔹 อัปโหลดรูปจาก Uint8List (สำหรับ Web)
    var uuid = Uuid();
String uniqueFileName = "upload_${uuid.v4()}.jpg"; // ✅ ใช้ UUID

request.files.add(
  http.MultipartFile.fromBytes(
    "image",
    imageBytes,
    filename: uniqueFileName, // ✅ ชื่อไฟล์ไม่ซ้ำกัน
  ),
);
  }

  var response = await request.send();
  if (response.statusCode == 201) {
    print("✅ โพสต์อัปเดตสำเร็จ");
    return true;
  } else {
    print("❌ ไม่สามารถโพสต์อัปเดตได้: ${response.statusCode}");
    return false;
  }
}

  Future<Map<String, dynamic>?> getDashboardData() async {
    String? token = await getAccessToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Smartwityouapp/getdashborddata/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print("❌ ไม่สามารถโหลดข้อมูล Dashboard ได้: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ เกิดข้อผิดพลาด: $e");
      return null;
    }
  }
  Future<List<Map<String, dynamic>>?> getUserPosts() async {
  String? token = await getAccessToken();
  if (token == null) return null;

  var response = await http.get(
    Uri.parse("$baseUrl/Smartwityouapp/partyposts/"),
    headers: {"Authorization": "Bearer $token"},
  );

  print("📡 API Response: ${utf8.decode(response.bodyBytes)}"); // ✅ Debugging ดูค่า API ที่ถูกต้อง

  if (response.statusCode == 200) {
    var data = json.decode(utf8.decode(response.bodyBytes)); // ✅ Decode UTF-8

    if (data is Map && data.containsKey("posts")) {
      return List<Map<String, dynamic>>.from(data["posts"]); // ✅ ดึงค่า `posts`
    } else {
      print("❌ ไม่พบ key 'posts' ใน JSON");
      return null;
    }
  } else {
    print("❌ ไม่สามารถโหลดโพสต์ได้, Status Code: ${response.statusCode}");
    return null;
  }
}
  Future<bool?>deletePost(int postId)async{
      String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse(
          "$baseUrl/Smartwityouapp/admindeletepost/$postId/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },

    );

    return response.statusCode == 200;
  }
 Future<bool?>deleteupdate(int update_id)async{
  String? token = await getAccessToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse(
          "$baseUrl/Smartwityouapp/admindeleteupdate/$update_id/"), // ✅ เปลี่ยนเป็น URL ที่ถูกต้อง
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },

    );

    return response.statusCode == 200;
 }
Future<bool?> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      if (token == null) {
        print("⚠️ ไม่มี Token อยู่แล้ว ไม่ต้องออกจากระบบ");
        return false;
      }

      // 🔹 ส่งคำขอไปยังเซิร์ฟเวอร์เพื่อแจ้งว่าผู้ใช้ล็อกเอาต์
      var response = await http.post(
        Uri.parse("$baseUrl/Smartwityouapp/logout/"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("✅ ออกจากระบบสำเร็จ");

        // 🔹 ลบ Token ออกจากเครื่อง
        await prefs.remove("access_token");

        return true;
      } else {
        print("❌ ไม่สามารถออกจากระบบได้: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดระหว่างออกจากระบบ: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAdminProfile() async {
  String? token = await getAccessToken();
  if (token == null) return null;

  var response = await http.get(
    Uri.parse("$baseUrl/Smartwityouapp/adminprofile/"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    print("❌ ไม่สามารถโหลดโปรไฟล์แอดมินได้");
    return null;
  }
}

Future<bool> updateAdminProfile({
  required String username,
  required String email,
  required String description,
  Uint8List? imageBytes,
}) async {
  String? token = await getAccessToken();
  if (token == null) return false;

  var request = http.MultipartRequest(
    "PUT",
    Uri.parse("$baseUrl/Smartwityouapp/admineditprofile/"),
  );

  request.headers.addAll({
    "Authorization": "Bearer $token",
  });

  request.fields["username"] = username;
  request.fields["email"] = email;
  request.fields["description"] = description;

  if (imageBytes != null) {
     String uniqueFileName = "profile_${Uuid().v4()}.jpg"; 

    request.files.add(http.MultipartFile.fromBytes(
      "profile_image",
      imageBytes,
      filename: uniqueFileName,
    ));
  }

  var response = await request.send();
  return response.statusCode == 200;
}
  }

