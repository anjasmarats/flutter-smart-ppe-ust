import 'package:flutter/foundation.dart';
import '../models/sensor_model.dart';

class SensorProvider with ChangeNotifier {
  SensorModel _sensor = SensorModel(suhu: 0, gas: 0, otot_1: 0, otot_2: 0);

  SensorModel get counter => _sensor;

  double get suhu => _sensor.suhu;
  double get gas => _sensor.gas;
  double get otot_1 => _sensor.otot_1;
  double get otot_2 => _sensor.otot_2;

  void reset() {
    _sensor = SensorModel(suhu: 0, gas: 0, otot_1: 0, otot_2: 0);
    notifyListeners();
  }

  void setValue(SensorModel newValue) {
    _sensor = _sensor.copyWith(
      suhu: newValue.suhu,
      gas: newValue.gas,
      otot_1: newValue.otot_1,
      otot_2: newValue.otot_2,
    );
    notifyListeners();
  }
}
