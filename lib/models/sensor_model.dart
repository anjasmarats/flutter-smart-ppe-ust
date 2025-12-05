class SensorModel {
  final double suhu, gas, otot_1, otot_2;
  // final DateTime lastUpdated;
  // final String lastAction;

  SensorModel({
    required this.suhu,
    required this.gas,
    required this.otot_1,
    required this.otot_2,
  });

  SensorModel copyWith({
    double? suhu,
    double? gas,
    double? otot_1,
    double? otot_2,
  }) {
    return SensorModel(
      suhu: suhu ?? this.suhu,
      gas: gas ?? this.gas,
      otot_1: otot_1 ?? this.otot_1,
      otot_2: otot_2 ?? this.otot_2,
    );
  }

  Map<String, dynamic> toJson() {
    return {'suhu': suhu, 'gas': gas, 'otot_1': otot_1, 'otot_2': otot_2};
  }

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      suhu: json['suhu'],
      gas: json['gas'],
      otot_1: json['otot_1'],
      otot_2: json['otot_2'],
    );
  }
}
