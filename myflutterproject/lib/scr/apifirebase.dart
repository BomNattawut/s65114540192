import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Future<bool> aceptjoinrequest(
    String user_id, int party_id, int joinreqest_id) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');

  try {
    final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/joinrequest/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'userid': user_id,
          'party_id': party_id,
          'joireqest_id': joinreqest_id
        }));
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Response: $responseData');
      return true;
    } else {
      print('Error:${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error:${e}');
    return false;
  }
}

Future<bool> acceptfriend(int friendrequest) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try {
    final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/aceptfriend/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'friendreq': friendrequest}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('results:${data}');
      print('ยอมรับคำขอเพื่อนเเล้ว');
      return true;
    } else {
      print('Error${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error${e}');
    return false;
  }
}

Future<bool> rejectedfriend(
  int friendrequest,
) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try {
    final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/rejectfirend/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'friendreq': friendrequest}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('ค่าที่ส่งมาจากbackend${data}');
      return true;
    } else {
      print('Error${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error${e}');
    return false;
  }
}

Future<bool> rejectedjoinrequest(int joinreqest_id, String sender_id) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');

  try {
    final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/rejectedjoinrequest/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body:
            jsonEncode({'senderId': sender_id, 'joinreqestId': joinreqest_id}));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('results:${data}');
      return true;
    } else {
      print('Error${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error${e}');
    return false;
  }
}

Future<void> removemember(int member) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try {
    final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/Smartwityouapp/removemember/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'memberId': member}));
    if (response.statusCode == 200) {
      print('ลลสมาชิกสำเร็จ');
    } else {
      print('Error${response.statusCode}');
    }
  } catch (e) {
    print('Error:${e}');
  }
}

Future<void> addmember(String user, int party) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try {
    final response = await http.post(Uri.parse(''),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'userId': user, 'party': party}));
    if(response.statusCode==200){
      print('เพิ่มสมาชิกสำเร็จ');
    }
    else{
      print('Error${response.statusCode}');
    }
  } catch (e) {
    print('Error:${e}');

  }
}
Future<void>Sendinvitation(String user,int party) async{
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try{
      final response=await http.post(Uri.parse('http://10.0.2.2:8000/Smartwityouapp/sendinvitation/'),
       headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'receiver_id':user,
          'party_id':party
        })
      );
      if (response.statusCode == 200) {
        print('ส่งคำเชิญเเล้ว');
      }
      else{
        print('Error:${response.statusCode}');
      }
  }
  catch (e){
      print('Error:${e}');
  }
}
Future<bool>accepintavitation(int invitation)async{
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try{
      final response = await http.post(Uri.parse('http://10.0.2.2:8000/Smartwityouapp/acceptedinvitation/'),
      headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      body: jsonEncode({
          'invitation_id':invitation
      })
      );
      if(response.statusCode==200){
        print('ยอมรับคำขอเเล้ว');
        return true;
      }
      else{
         print('Error:${response.statusCode}');
         return false;
      }
  }
  catch (e){
      print('Error:${e}');
      return false;
  }
}
Future<bool>rejectedinvitation(int invitation) async{
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try{
      final response = await http.post(Uri.parse('http://10.0.2.2:8000/Smartwityouapp/rejectedInvite/'),
      headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      body: jsonEncode({
          'invitation_id':invitation
      })
      );
      if(response.statusCode==200){
        print('ปฏิเสธเเล้ว');
        return true;
      }
      else{
         print('Error:${response.statusCode}');
         return false;
      }
  }
  catch (e){
      print('Error:${e}');
      return false;
  }
}
Future<bool>leaveparty(int party,String user) async{
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('access_token');
  try{
      final response= await http.post(Uri.parse('http://10.0.2.2:8000/Smartwityouapp/leaveparty/'),
       headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      body: jsonEncode({
          'party_id': party,
          'user_id': user
      })
      );
      if(response.statusCode==200){
          print('ออกจากปาร์ตี้เเล้ว');
          return true;
      }
      else{
        print('Error:${response.statusCode}');
          return false;
      }
  }
  catch (e){
      print('Error${e}');
      return false;
  }
}