import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class PartyMapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const PartyMapScreen({Key? key, required this.latitude, required this.longitude}) : super(key: key);

  @override
  _PartyMapScreenState createState() => _PartyMapScreenState();
}

class _PartyMapScreenState extends State<PartyMapScreen> {
  late GoogleMapController mapController;
  LocationData? currentLocation;
  Set<Polyline> _polylines = {};
  late LatLng destination;

  @override
  void initState() {
    super.initState();
    destination = LatLng(widget.latitude, widget.longitude);
    requestLocationPermission();
  }

  /// 🔹 ขอสิทธิ์เข้าถึงตำแหน่ง
  Future<bool> requestLocationPermission() async {
    perm.PermissionStatus status = await perm.Permission.location.request();
    if (status == perm.PermissionStatus.granted) {
      print("✅ ได้รับอนุญาตให้เข้าถึงตำแหน่ง");
      return true;
    } else {
      print("❌ ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง");
      return false;
    }
  }

  /// 📍 ดึงตำแหน่งปัจจุบัน
  Future<void> getCurrentLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();
    setState(() {
      currentLocation = locationData;
    });

    print("📌 ตำแหน่งปัจจุบัน: ${currentLocation?.latitude}, ${currentLocation?.longitude}");
  }

  /// 🚗 ดึงเส้นทางนำทาง
  Future<void> drawRoute() async {
    if (currentLocation == null) {
      print("⚠️ ตำแหน่งปัจจุบันเป็น null");
      return;
    }

    final String apiKey = "AIzaSyCKXLb2SiCsJngW-gwXXIL6W9Cq_VzvAEU"; // 🔑 ใช้ API Key ที่ถูกต้อง
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation!.latitude},${currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    print("🔍 Fetching route from: $url");

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data["status"] == "OK") {
      List<LatLng> polylineCoordinates = [];
      var steps = data["routes"][0]["legs"][0]["steps"];

      for (var step in steps) {
        double lat = step["end_location"]["lat"];
        double lng = step["end_location"]["lng"];
        polylineCoordinates.add(LatLng(lat, lng));
      }

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: PolylineId("route"),
            color: Colors.blue,
            width: 5,
            points: polylineCoordinates,
          ),
        );
      });

      print("✅ เส้นทางถูกโหลดสำเร็จ! จุดทั้งหมด: ${polylineCoordinates.length}");

      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
                data["routes"][0]["bounds"]["southwest"]["lat"],
                data["routes"][0]["bounds"]["southwest"]["lng"]),
            northeast: LatLng(
                data["routes"][0]["bounds"]["northeast"]["lat"],
                data["routes"][0]["bounds"]["northeast"]["lng"]),
          ),
          100,
        ),
      );
    } else {
      print("❌ ไม่สามารถดึงเส้นทางได้: ${data["status"]}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("สถานที่ออกกำลังกาย")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: destination,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: {
              Marker(
                markerId: MarkerId("partyLocation"),
                position: destination,
                infoWindow: InfoWindow(title: "จุดนัดหมาย"),
              ),
            },
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              getCurrentLocation();
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: drawRoute,
              icon: Icon(Icons.directions),
              label: Text("เริ่มนำทาง"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
