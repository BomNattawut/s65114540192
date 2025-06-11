import 'package:flutter/material.dart';
import 'package:admin_panel/src/login.dart';
import 'package:admin_panel/src/admin_dashbord.dart';
import 'package:admin_panel/src/manageuser.dart';
import 'package:admin_panel/src/manageparty.dart';
import 'package:admin_panel/src/location.dart';
import 'package:admin_panel/src/exercisetype.dart';
import 'package:admin_panel/src/Addminupdatepage.dart';
import 'package:admin_panel/src/manageuserpost.dart';


void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: '/login',
    routes: {
      '/login': (context) => AdminLoginPage(),
      '/dashboard': (context) => AdminDashboardPage(),
      '/usermanage': (context) => UserManagePage(),
      '/partymanage': (context) => ManagePartyPage(),
      '/locationmanage': (context) => ExercisePlacesPage(),
      '/exerciseType':(context)=>ManageExerciseTypesPage(),
      '/adminupdates':(context)=>AdminUpdatePage(),
      '/manageuserpost':(context)=>ManageUserPostsPage(),
      '/adminprofile': (context) => AdminProfilePage(),
      
    },
  ));
}