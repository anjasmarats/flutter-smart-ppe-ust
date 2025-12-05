import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_iot_esp32_ust/firebase_options.dart';
import 'package:flutter_iot_esp32_ust/url.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// Inisialisasi notifikasi
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  log('Handling a background message data: ${message.data}');

  // Pastikan payload notification tidak null sebelum menampilkan
  if (message.notification != null) {
    await showNotification(message.notification!);
  }
}

Future<void> initializeNotification() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(RemoteNotification notification) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'your_channel_id',
        'Your Channel Name',
        channelDescription: 'Your Channel Description',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    notification.title ?? 'Notifikasi',
    notification.body ?? 'Pesan baru',
    platformChannelSpecifics,
    payload: 'item x',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request permission untuk notifikasi
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Setup initial notification settings
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize notifications
  await initializeNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart PPE Monitoring',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // State untuk data sensor
  double suhu = 0.0;
  double gas = 0.0;
  double otot1 = 0.0;
  double otot2 = 0.0;
  String status = 'Normal';
  bool loading = false;
  bool error = false;
  bool warning = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _postFCMToken();
  }

  // Setup Firebase Messaging
  void _initializeFirebaseMessaging() {
    // Listen untuk pesan yang diterima saat app berjalan di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('Message received: ${message.notification?.body}');

      try {
        // Parse data dari body notifikasi
        final Map<String, dynamic> data = jsonDecode(
          message.notification?.body ?? '{}',
        );

        // Update state dengan data baru
        setState(() {
          suhu = (data["temperature"] ?? 0.0).toDouble();
          gas = (data["gas"] ?? 0.0).toDouble();
          otot1 = (data["otot_1"] ?? 0.0).toDouble();
          otot2 = (data["otot_2"] ?? 0.0).toDouble();

          // Update status berdasarkan nilai sensor
          _updateStatus();

          // Update warning status
          warning = _checkWarning();
        });

        // Tampilkan notifikasi lokal
        if (message.notification != null) {
          await showNotification(message.notification!);
        }
      } catch (e) {
        log('Error parsing notification data: $e');
      }
    });

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
  }

  // Post FCM token ke server
  Future<void> _postFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        log('FCM Token: $token');

        var response = await http.post(
          Uri.parse("$url/api/register"),
          body: {'token': token},
        );

        log('Response status: ${response.statusCode}');
        log('Response body: ${response.body}');
      }
    } catch (e) {
      log('Error saat POST data: $e');
      setState(() {
        error = true;
      });
    }
  }

  // Update status berdasarkan nilai sensor
  void _updateStatus() {
    if (gas > 50 || suhu > 40 || otot1 > 80 || otot2 > 80) {
      status = 'Bahaya';
    } else if (gas > 30 || suhu > 35 || otot1 > 60 || otot2 > 60) {
      status = 'Peringatan';
    } else {
      status = 'Normal';
    }
  }

  // Check apakah ada kondisi warning
  bool _checkWarning() {
    return gas > 30 || suhu > 35 || otot1 > 60 || otot2 > 60;
  }

  // Refresh data (simulasi)
  Future<void> _refreshData() async {
    setState(() {
      loading = true;
    });

    // Simulasi delay
    await Future.delayed(const Duration(seconds: 1));

    // Di sini Anda bisa menambahkan kode untuk fetch data dari API
    // Contoh: final data = await ApiService.getSensorData();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text(
          'Smart PPE Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        child: loading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Icon(Icons.refresh),
        tooltip: 'Refresh Data',
      ),
    );
  }

  Widget _buildBody() {
    // Tampilkan loading indicator jika data sedang dimuat
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Periksa apakah ada error
    if (error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _postFCMToken,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getStatusGradientColors(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 48,
                    color: _getStatusIconColor(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusMessage(status),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sensor Cards
          // Gas Sensor Card
          _buildSensorCard(
            title: 'Gas',
            value: gas.toStringAsFixed(1),
            unit: '',
            icon: Icons.cloud,
            color: Colors.purple,
            description: 'Kadar Gas',
            maxValue: 100,
            threshold: 30,
            currentValue: gas,
          ),
          const SizedBox(height: 16),

          // Temperature Sensor Card
          _buildSensorCard(
            title: 'Suhu',
            value: suhu.toStringAsFixed(1),
            unit: '°C',
            icon: Icons.thermostat,
            color: Colors.orange,
            description: 'Temperature',
            maxValue: 50,
            threshold: 35,
            currentValue: suhu,
          ),

          const SizedBox(height: 24),

          // EMG Sensor Cards
          _buildSensorCard(
            title: 'Otot 1',
            value: otot1.toStringAsFixed(1),
            unit: '',
            icon: Icons.electrical_services,
            color: Colors.blue,
            description: 'Deteksi Kelelahan Otot',
            maxValue: 100,
            threshold: 60,
            currentValue: otot1,
          ),
          const SizedBox(height: 16),

          _buildSensorCard(
            title: 'Otot 2',
            value: otot2.toStringAsFixed(1),
            unit: '',
            icon: Icons.electrical_services,
            color: Colors.blue,
            description: 'Deteksi Kelelahan Otot',
            maxValue: 100,
            threshold: 60,
            currentValue: otot2,
          ),
          const SizedBox(height: 16),

          // Alert Section
          if (warning)
            Card(
              elevation: 4,
              color: Colors.amber[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber[700]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber[700], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getAlertMessage(),
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String description,
    required double maxValue,
    required double threshold,
    required double currentValue,
  }) {
    double percentage = (currentValue / maxValue) * 100;
    percentage = percentage > 100 ? 100 : percentage;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '$value$unit',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > threshold ? Colors.red : color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Max: ${maxValue.toStringAsFixed(0)}$unit',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getStatusMessage(String status) {
    switch (status) {
      case 'Bahaya':
        return 'Kondisi berbahaya! Segera ambil tindakan';
      case 'Peringatan':
        return 'Kondisi memerlukan perhatian';
      case 'Normal':
      default:
        return 'Semua parameter aman dan normal';
    }
  }

  List<Color> _getStatusGradientColors() {
    switch (status) {
      case 'Bahaya':
        return [Colors.red, Colors.redAccent];
      case 'Peringatan':
        return [Colors.orange, Colors.orangeAccent];
      case 'Normal':
      default:
        return [Colors.green, Colors.lightGreen];
    }
  }

  Color _getStatusIconColor() {
    switch (status) {
      case 'Bahaya':
        return Colors.red[100]!;
      case 'Peringatan':
        return Colors.orange[100]!;
      case 'Normal':
      default:
        return Colors.green[100]!;
    }
  }

  String _getAlertMessage() {
    List<String> alerts = [];
    if (otot1 > 60 || otot2 > 60) alerts.add('Kelelahan otot terdeteksi');
    if (gas > 30) alerts.add('Gas beracun menumpuk');
    if (suhu > 35) alerts.add('Suhu tinggi terdeteksi');
    return alerts.join(', ');
  }
}
