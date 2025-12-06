import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesMonitor {
  // Stream to listen for preference changes
  late Stream<Map<String, dynamic>> _stream;
  // Controller for the stream
  late StreamController<Map<String, dynamic>> _controller;
  // Singleton instance
  static final SharedPreferencesMonitor _instance =
      SharedPreferencesMonitor._internal();
  SharedPreferences? _preferences;

  factory SharedPreferencesMonitor() {
    return _instance;
  }

  SharedPreferencesMonitor._internal() {
    _controller = StreamController<Map<String, dynamic>>.broadcast();
    _stream = _controller.stream;
    _init();
  }

  // Initialize and load initial preferences
  Future<void> _init() async {
    _preferences = await SharedPreferences.getInstance();
    _notifyListeners();
  }

  // Get the stream for listening
  Stream<Map<String, dynamic>> get stream => _stream;

  // Get all key-value pairs from SharedPreferences
  Map<String, dynamic> _getAllPrefs() {
    final Map<String, dynamic> allPrefs = {};
    if (_preferences != null) {
      // Iterate through all keys and get their values[citation:5]
      for (String key in _preferences!.getKeys()) {
        allPrefs[key] = _preferences!.get(key);
      }
    }
    return allPrefs;
  }

  // Notify all listeners with the latest preferences
  void _notifyListeners() {
    if (!_controller.isClosed) {
      _controller.add(_getAllPrefs());
    }
  }

  // --- Public Methods to Wrap SharedPreferences Operations ---
  // Each method updates preferences and then notifies listeners

  Future<bool> setString(String key, String value) async {
    final success = _preferences != null
        ? await _preferences!.setString(key, value)
        : await Future.value(false);
    if (success) _notifyListeners();
    return success;
  }

  Future<bool> setInt(String key, int value) async {
    final success = _preferences != null
        ? await _preferences!.setInt(key, value)
        : await Future.value(false);
    if (success) _notifyListeners();
    return success;
  }

  Future<bool> setBool(String key, bool value) async {
    final success = _preferences != null
        ? await _preferences!.setBool(key, value)
        : await Future.value(false);
    if (success) _notifyListeners();
    return success;
  }

  Future<bool> setDouble(String key, double value) async {
    final success = _preferences != null
        ? await _preferences!.setDouble(key, value)
        : await Future.value(false);
    if (success) _notifyListeners();
    return success;
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final success = _preferences != null
        ? await _preferences!.setStringList(key, value)
        : await Future.value(false);
    if (success) _notifyListeners();
    return success;
  }

  // Direct getters (don't trigger notifications)
  String? getString(String key) => _preferences?.getString(key);
  int? getInt(String key) => _preferences?.getInt(key);
  bool? getBool(String key) => _preferences?.getBool(key);
  double? getDouble(String key) => _preferences?.getDouble(key);
  List<String>? getStringList(String key) => _preferences?.getStringList(key);

  Future<bool> remove(String key) async {
    final success = _preferences != null
        ? await _preferences!.remove(key)
        : await Future.value(false);
    if (success) _notifyListeners();
    return success;
  }

  Future<bool> clear() async {
    final success = _preferences != null
        ? await _preferences!.clear()
        : await Future.value(false);
    if (success) _notifyListeners();
    return success;
  }

  // Manual trigger to force notification (e.g., if prefs were modified elsewhere)
  void refresh() {
    _notifyListeners();
  }

  // Close the stream controller when done
  void dispose() {
    _controller.close();
  }
}
