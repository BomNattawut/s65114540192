
import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/auth_service/Authservice.dart';
import 'package:myflutterproject/scr/createparty.dart';
import 'package:myflutterproject/scr/intro.dart';
import 'package:myflutterproject/scr/login.dart';
import 'package:myflutterproject/scr/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:myflutterproject/scr/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificationService().initNotification();
  await NotificationService().isInitialized;
  FirebaseMessaging.onMessage.listen((RemoteMessage message){
        if (message.notification != null){
          
           print('ค่าที่ส่งมาจากmessage${message.data}');
           final title =message.notification?.title;
           final body=message.notification?.body;
           NotificationService().showNotification(title: title ?? 'No title', body: body ?? 'No title');

        }
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message){
     if (message.notification != null){
         print(message.data);
         final title =message.notification?.title;
         final body =message.notification?.body;
         NotificationService().showNotification(title: title ?? 'No title' , body: body ?? 'No body');
     }
  });
     
  
  bool isLoggedIn = await AuthService.getLoginStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn,));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key,required this.isLoggedIn});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ใช้ navigatorKey
      title: "MyApp",
      initialRoute:isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => IntroPage(),
        '/home': (context) => HomePage(),
        '/login': (context) => const Loginpage(),
        '/register': (context) => const Registerpage(),
        '/creatparty': (context) => const MakePartyPage(),
      },
    );
  }
}