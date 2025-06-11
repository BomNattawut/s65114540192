import 'package:flutter/material.dart';

class notification extends StatelessWidget {
  const notification({super.key});

  @override
  Widget build(BuildContext context) {
    // สร้างรายการข้อมูลตัวอย่าง (แทนที่ด้วยข้อมูลจริงจาก WebSocketProvider)
    final List<NotificationItem> notifications = [
      NotificationItem(
        title: 'คำขอเข้าร่วมปาร์ตี้',
        message: 'ผู้ใช้ yaiyaimark ต้องการเข้าร่วมปาร์ตี้วิ่งของคุณ',
        onAccept: () {
          // โค้ดสำหรับตอบรับคำขอ
          print('Accept John Doe');
        },
        onReject: () {
          // โค้ดสำหรับปฏิเสธคำขอ
          print('Reject John Doe');
        },
      ),
      NotificationItem(
        title: 'คำเชิญเข้าร่วมกิจกรรม',
        message: 'ผู้ใช้ yaiayaimark เชิญคุณเข้าร่วมปาร์ตี้ปั่นจักรยาน',
        onAccept: () {
          // โค้ดสำหรับตอบรับคำเชิญ
          print('Accept Jane Doe');
        },
        onReject: () {
          // โค้ดสำหรับปฏิเสธคำเชิญ
          print('Reject Jane Doe');
        },
      ),
      // เพิ่มรายการอื่นๆ ได้ตามต้องการ
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
      ),
      body: notifications.isEmpty // ตรวจสอบว่ามีรายการแจ้งเตือนหรือไม่
          ? const Center(child: Text('ไม่มีการแจ้งเตือน')) // แสดงข้อความเมื่อไม่มี
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationCard(notification: notification);
              },
            ),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  NotificationItem({
    required this.title,
    required this.message,
    required this.onAccept,
    required this.onReject,
  });
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8.0),
            Text(notification.message),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: notification.onReject,
                  child: const Text('ปฏิเสธ'),
                ),
                ElevatedButton(
                  onPressed: notification.onAccept,
                  child: const Text('ตอบรับ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}