import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myflutterproject/scr/createparty.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ExercisePlaceDetail extends StatelessWidget {
  final Map<String, dynamic> placeData; // ตัวแปรรับข้อมูลสถานที่
  final String currentPartyName;
  final String currentPartyDate;
  final String currentStartTime;
  final String currentFinishTime;
  final String currentDescription;

  const ExercisePlaceDetail({
    super.key,
    required this.placeData,
    required this.currentPartyName,
    required this.currentPartyDate,
    required this.currentStartTime,
    required this.currentFinishTime,
    required this.currentDescription,
  });

  Future<void> marklocation(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MakePartyPage(
          selectedPlace: placeData,
          partyName: currentPartyName,
          partyDate: currentPartyDate,
          startTime: currentStartTime,
          finishTime: currentFinishTime,
          description: currentDescription,
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    final lat = placeData['latitude'];
    final lng = placeData['longitude'];
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } 
  }

  @override
  Widget build(BuildContext context) {
    double latitude = double.tryParse(placeData['latitude'].toString()) ?? 0.0;
    double longitude =
        double.tryParse(placeData['longitude'].toString()) ?? 0.0;
    LatLng placeLocation = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(
          placeData['location_name'],
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          // ข้อมูลสถานที่
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ รูปภาพสถานที่
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'http://10.0.2.2:8000${placeData['place_image']}',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ กล่องข้อมูล
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeData['location_name'],
                          style: GoogleFonts.notoSansThai(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          placeData['opening_hours'] != null &&
                                  placeData['opening_hours'].isNotEmpty &&
                                  placeData['opening_hours'][0]['open_time'] !=
                                      null &&
                                  placeData['opening_hours'][0]['close_time'] !=
                                      null
                              ? "🕐 เวลาเปิด-ปิด: ${placeData['opening_hours'][0]['open_time']} - ${placeData['opening_hours'][0]['close_time']}"
                              : "🕐 เวลาเปิด-ปิดไม่ระบุ",
                          style: GoogleFonts.notoSansThai(
                              color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "📍 ที่อยู่: ${placeData['address']}",
                          style: GoogleFonts.notoSansThai(
                              color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          placeData['description'] ??
                              "ไม่มีรายละเอียดเพิ่มเติม",
                          style: GoogleFonts.notoSansThai(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ แผนที่ Google Map
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: placeLocation,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_place'),
                      position: placeLocation,
                      infoWindow: InfoWindow(
                        title: placeData['location_name'],
                        snippet: placeData['address'],
                      ),
                    ),
                  },
                ),
              ),
            ),
          ),

          // ✅ ปุ่มเลือกสถานที่
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  marklocation(context);
                },
                icon: Icon(Icons.gps_fixed, color: Colors.black),
                label: Text(
                  'เลือกสถานที่นี้',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _openInGoogleMaps,
                icon: Icon(Icons.map, color: Colors.amber),
                label: Text(
                  "เปิดใน Google Maps",
                  style: GoogleFonts.notoSansThai(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
