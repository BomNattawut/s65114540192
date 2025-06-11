import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermissions() async {
  var status = await Permission.notification.status;
    if (status.isGranted) {
      print("Notification permission granted");
    } else {
    if (status.isDenied) {
      status = await Permission.notification.request();
      if (status.isGranted) {
        // สิทธิ์ได้รับอนุญาต
        print('Notification permission granted.');
      } else if (status.isPermanentlyDenied) {
        // สิทธิ์ถูกปฏิเสธอย่างถาวร ควรแสดง dialog เพื่อนำผู้ใช้ไปที่ Settings
        print('Notification permission permanently denied.');
        openAppSettings(); // เปิดหน้า Settings ของแอป
      } else {
        // สิทธิ์ถูกปฏิเสธ
        print('Notification permission denied.');
      }
    }
  }
}