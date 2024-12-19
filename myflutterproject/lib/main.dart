import 'package:flutter/material.dart';
import 'package:myflutterproject/scr/login.dart';
import 'package:myflutterproject/scr/waitingverified.dart';
import 'package:myflutterproject/scr/Home.dart';
import 'package:myflutterproject/scr/intro.dart';
import "package:myflutterproject/scr/register.dart";
import 'package:myflutterproject/scr/createparty.dart';


void main() {
  runApp(MaterialApp(
    title: "Myapp",
    initialRoute:  '/',
    routes: {
      '/': (context) => IntroPage(),   // หน้าแรก (IntroPage)
      '/home': (context) => HomePage(),
      '/login':(context) => Loginpage(),
      'register':(context)=>Registerpage(),
      'creatparty':(context) => MakePartyPage(),// เส้นทางไปหน้า Home
    },
  ));
}
