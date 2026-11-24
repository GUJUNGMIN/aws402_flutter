import 'dart:async';

import 'package:aws402_flutter/models/health_measurement.dart';
import 'package:aws402_flutter/watch/watch_client.dart';

// 구정민 : 수정 - 가상 워치 데이터는 테스트 폴더에서만 생성한다.
class FakeWatchClient extends WatchClient {
  final _samples = StreamController<HealthMeasurement>.broadcast(sync: true);
  WatchConnection _connection = WatchConnection.disconnected;
  int _sequence = 0;
  bool autoMeasure = true;
  bool connectFails = false;
  int requestedMeasurements = 0;
  @override
  WatchConnection get connection => _connection;
  @override
  Stream<HealthMeasurement> get measurements => _samples.stream;
  void setConnection(WatchConnection value) {
    _connection = value;
    notifyListeners();
  }

  @override
  Future<void> connect() async {
    if (connectFails) throw StateError('워치 연결 실패');
    setConnection(WatchConnection.connected);
  }

  @override
  Future<void> disconnect() async =>
      setConnection(WatchConnection.disconnected);
  @override
  Future<void> requestMeasurement() async {
    requestedMeasurements++;
    if (autoMeasure) emit(sample());
  }

  HealthMeasurement sample({
    int bpm = 85,
    double temperature = 36.5,
    int spo2 = 98,
    DateTime? measuredAt,
    String? id,
  }) => HealthMeasurement(
    sampleId: id ?? (++_sequence).toString(),
    measuredAt: measuredAt ?? DateTime.now(),
    bpm: bpm,
    temperature: temperature,
    spo2: spo2,
  );
  void emit(HealthMeasurement value) => _samples.add(value);
  Future<void> close() => _samples.close();
}
