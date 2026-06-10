import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// PERBAIKAN ALIAS: Menggunakan tz_data dan tz agar tidak bentrok
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Inisialisasi data zona waktu global
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Meminta izin notifikasi untuk Android 13+ (API 33+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Inisialisasi menggunakan named parameter 'settings'
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Logika ketika notifikasi diklik (bisa dibiarkan kosong)
      },
    );

    // 2. Jalankan penjadwalan pengingat harian otomatis setiap kali aplikasi di-init
    await scheduleDailyReminder();
  }

  // Tampilkan notifikasi instan (Dipakai untuk sukses nabung & penyemangat wishlist)
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'tabungan_channel_id',
          'Notifikasi Aktivitas',
          channelDescription: 'Menampilkan info sukses mencatat tabungan',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Menggunakan named parameters secara lengkap untuk .show()
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // Menjadwalkan pengingat harian jam 8 malam
  static Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_reminder_channel_id',
          'Pengingat Harian',
          channelDescription:
              'Mengingatkan pengguna untuk menabung setiap malam',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Menggunakan named parameter 'id:' untuk metode .cancel()
    await _notificationsPlugin.cancel(id: 999);

    // PERBAIKAN UTAMA: uiLocalNotificationDateInterpretation dihapus karena sudah tidak didukung di versi baru
    await _notificationsPlugin.zonedSchedule(
      id: 999, // ID khusus untuk reminder harian
      title: 'Yuk, Cek Keuanganmu! 🪙',
      body:
          'Oh, kamu belum menabung hari ini. Jangan lupa sisihkan uangmu untuk target wishlist ya!',
      scheduledDate: _nextInstanceOfEightPM(),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode
          .inexactAllowWhileIdle, // Sangat aman untuk lintas versi OS Android
      matchDateTimeComponents:
          DateTimeComponents.time, // Berulang setiap hari pada jam yang sama
    );
  }

  // Helper untuk mencari waktu jam 8 malam berikutnya berdasarkan zona waktu lokal perangkat
  static tz.TZDateTime _nextInstanceOfEightPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // Jam 20:00 (8 Malam)
      0,
    );

    // Jika jam 8 malam hari ini sudah lewat, ganti ke jam 8 malam esok hari
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
