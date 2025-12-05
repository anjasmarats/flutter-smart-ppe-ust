import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_iot_esp32_ust/firebase_options.dart';
import 'package:flutter_iot_esp32_ust/providers/sensor_provider.dart';
import 'package:flutter_iot_esp32_ust/url.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
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

  // Setup message handlers
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    log('Message received: ${message.notification?.title}');
    if (message.notification != null) {
      await showNotification(message.notification!);
    }
  });

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);

  // Initialize notifications
  await initializeNotification();

  // Setup initial notification settings
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => SensorProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool error = false, loading = false, warning = false;
  @override
  void initState() {
    super.initState();
    // _initializeApp();
    postData();
  }

  Future<void> postData() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      String tokenFcm = "";

      if (token != null) {
        tokenFcm = token;
        log('FCM Token: $token');

        // 3. Kirim token ke server aplikasi Anda di sini
        // await _sendTokenToServer(token);
      }

      var response = await http.post(
        Uri.parse("$url/api/register"),
        body: {'token': tokenFcm},
      );
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');
    } catch (e) {
      log('Error saat POST data: $e');
    }
  }

  // Future<void> _initializeApp() async {
  //   try {
  //     // Initialize sensor provider
  //     final sensorProvider = context.read<SensorProvider>();
  //     await sensorProvider.initialize();
  //   } catch (e) {
  //     log('Error initializing app: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.deepPurpleAccent,
          title: const Text(
            'Smart PPE Monitoring',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
        ),
        body: Consumer<SensorProvider>(
          builder: (context, sensorProvider, child) {
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
                    Text(
                      'Error: error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => null,
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
                          colors: [
                            Colors.green,
                            Colors.lightGreen.withValues(),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.health_and_safety,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "sensorProvider.status",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getStatusMessage("sensorProvider.status"),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sensor Cards
                  // Ammonia Sensor Card
                  _buildSensorCard(
                    title: 'Gas',
                    value: sensorProvider.gas.toString(),
                    unit: 'ppm',
                    icon: Icons.cloud,
                    color: Colors.purple,
                    description: 'Deteksi Gas Beracun',
                    maxValue: 100,
                    threshold: 30,
                    currentValue: sensorProvider.gas,
                  ),
                  const SizedBox(height: 16),

                  // Temperature Sensor Card
                  _buildSensorCard(
                    title: 'Suhu',
                    value: sensorProvider.suhu.toString(),
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: Colors.orange,
                    description: 'Temperature',
                    maxValue: 50,
                    threshold: 35,
                    currentValue: sensorProvider.suhu,
                  ),

                  const SizedBox(height: 24),

                  // EMG Sensor Card
                  _buildSensorCard(
                    title: 'Otot 1',
                    value: sensorProvider.otot_1.toString(),
                    unit: '',
                    icon: Icons.electrical_services,
                    color: Colors.blue,
                    description: 'Deteksi Kelelahan Otot',
                    maxValue: 100,
                    threshold: 60,
                    currentValue: sensorProvider.otot_1,
                  ),
                  const SizedBox(height: 16),

                  _buildSensorCard(
                    title: 'Otot 2',
                    value: sensorProvider.otot_2.toString(),
                    unit: '',
                    icon: Icons.electrical_services,
                    color: Colors.blue,
                    description: 'Deteksi Kelelahan Otot',
                    maxValue: 100,
                    threshold: 60,
                    currentValue: sensorProvider.otot_2,
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
                            Icon(
                              Icons.warning,
                              color: Colors.amber[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getAlertMessage(40, 40, 40),
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
          },
        ),
        floatingActionButton: Consumer<SensorProvider>(
          builder: (context, sensorProvider, child) {
            return FloatingActionButton(
              onPressed: () => null,
              child: loading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
            );
          },
        ),
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
                        color: color.withValues(),
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
                  '$value $unit',
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
                  'Max: ${maxValue.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  String _getAlertMessage(
    double emgValue,
    double ammoniaValue,
    double temperatureValue,
  ) {
    List<String> alerts = [];
    if (emgValue > 60) alerts.add('Kelelahan otot terdeteksi');
    if (ammoniaValue > 30) alerts.add('Gas beracun menumpuk');
    if (temperatureValue > 35) alerts.add('Suhu tinggi terdeteksi');
    return alerts.join(', ');
  }
}
