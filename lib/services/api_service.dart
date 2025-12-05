import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_iot_esp32_ust/models/sensor_model.dart';
import 'package:flutter_iot_esp32_ust/providers/sensor_provider.dart';
import 'package:provider/provider.dart';

class ApiService {
  // GlobalKey untuk mengakses context dari mana saja
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Method untuk mengakses provider dari mana saja
  static SensorProvider? getSensorProvider() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      try {
        return Provider.of<SensorProvider>(context, listen: false);
      } catch (e) {
        log('Error accessing provider: $e');
        return null;
      }
    }
    return null;
  }

  // Contoh method yang menggunakan provider
  static Future<void> setSensor(
    double suhu,
    double gas,
    double otot_1,
    double otot_2,
  ) async {
    log('Fetching data from API...');

    // Simulasi API call
    await Future.delayed(const Duration(seconds: 2));

    // Mengakses provider di luar widget tree
    final provider = getSensorProvider();
    if (provider != null) {
      // Update state berdasarkan data API
      final SensorModel sensorData = SensorModel(
        suhu: suhu,
        gas: gas,
        otot_1: otot_1,
        otot_2: otot_2,
      );
      provider.setValue(sensorData);
      log('Provider updated from API service');
    } else {
      log('Provider not available');
    }
  }

  // // Method lain yang menggunakan provider
  // static void incrementFromService() {
  //   final provider = getSensorProvider();
  //   provider?.increment();
  // }
}
