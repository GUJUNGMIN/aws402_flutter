// [인수인계] 워치 SDK의 명령 콜백과 실제 연결/측정 이벤트를 Flutter에 전달한다. SDK 연결 명령 완료와 실제 연결 확인은 별개다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'dart:async';

import '../models/health_measurement.dart';
import 'watch_client.dart';

// 구정민 : 수정 - 워치 담당자의 실제 통신 콜백을 앱 데이터 경계에 연결하는 어댑터.
class WatchBridgeClient extends WatchClient {
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;
  final Future<void> Function() onRequestMeasurement;
  final _measurements = StreamController<HealthMeasurement>.broadcast(
    sync: true,
  );
  WatchConnection _connection = WatchConnection.disconnected;
  bool _disposed = false;

  /// [인수인계] 필요한 의존성/콜백/초기값으로 WatchBridgeClient 객체를 구성한다.
  WatchBridgeClient({
    required this.onConnect,
    required this.onDisconnect,
    required this.onRequestMeasurement,
  });
  @override
  /// [인수인계] 어댑터가 보고한 현재 연결 상태를 노출한다. 실제 장치 연결 이벤트가 원본이다.
  WatchConnection get connection => _connection;
  @override
  /// [인수인계] 새 센서 묶음의 스트림 계약이다. 기본 미설정 구현은 빈 스트림이다.
  Stream<HealthMeasurement> get measurements => _measurements.stream;

  // 구정민 : 수정 - 명령 완료만으로 연결을 확정하지 않고 실제 장치 이벤트로 갱신한다.
  /// [인수인계] SDK가 실제 연결 상태를 보고한 경우에만 연결 상태를 갱신하고 리스너에 알린다.
  void reportConnection(WatchConnection value) {
    if (_disposed || _connection == value) return;
    _connection = value;
    notifyListeners();
  }

  /// [인수인계] 실제 연결된 동안 받은 센서 묶음만 측정 스트림에 전달한다.
  void reportMeasurement(HealthMeasurement sample) {
    if (_disposed || _connection != WatchConnection.connected) return;
    _measurements.add(sample);
  }

  @override
  /// [인수인계] 등록된 실제 SDK 연결 명령을 호출한다. 여기서 connected를 임의 설정하지 않는다.
  Future<void> connect() => onConnect();
  @override
  /// [인수인계] 등록된 실제 SDK 연결 해제 명령을 호출한다.
  Future<void> disconnect() => onDisconnect();
  @override
  /// [인수인계] 등록된 SDK 측정 요청 명령을 호출하고 결과는 별도의 측정 이벤트로 받는다.
  Future<void> requestMeasurement() => onRequestMeasurement();
  @override
  /// [인수인계] 브리지 측정 스트림을 닫는다. SDK의 네이티브 구독 정리는 통신 담당자가 함께 구현한다.
  void dispose() {
    _disposed = true;
    unawaited(_measurements.close());
    super.dispose();
  }
}
