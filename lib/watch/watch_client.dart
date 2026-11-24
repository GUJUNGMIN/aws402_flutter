// [인수인계] 실제 워치 통신 구현이 따라야 할 계약이다. 기본 UnavailableWatchClient는 연결 성공/가상 측정값을 생성하지 않는다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/foundation.dart';

import '../models/health_measurement.dart';

enum WatchConnection { disconnected, connecting, connected }

// 구정민 : 수정 - 워치 담당자가 구현할 통신 경계. 실제 전송 방식은 UI/서버 코드와 분리한다.
abstract class WatchClient extends ChangeNotifier {
  static WatchClient instance = UnavailableWatchClient();

  /// [인수인계] 실제 통신 구현이 제공할 연결 상태다. 미설정 구현은 disconnected를 반환한다.
  WatchConnection get connection;

  /// [인수인계] 새 센서 묶음의 스트림 계약이다. 기본 미설정 구현은 빈 스트림이다.
  Stream<HealthMeasurement> get measurements;

  /// [인수인계] 워치 연결 명령 계약이다. 기본 미설정 구현은 연결 성공을 만들지 않는다.
  Future<void> connect();

  /// [인수인계] 워치 연결 해제 명령 계약이다. 미설정 구현은 별도 장치 동작이 없다.
  Future<void> disconnect();

  /// [인수인계] 새 측정 요청 계약이다. 미설정 구현은 오류를 알리고 가상값을 반환하지 않는다.
  Future<void> requestMeasurement();
}

// 구정민 : 수정 - 어댑터 미설정 시 가상 연결이나 가상 측정값을 만들지 않는다.
class UnavailableWatchClient extends WatchClient {
  @override
  /// [인수인계] 실제 통신 구현이 제공할 연결 상태다. 미설정 구현은 disconnected를 반환한다.
  WatchConnection get connection => WatchConnection.disconnected;
  @override
  /// [인수인계] 새 센서 묶음의 스트림 계약이다. 기본 미설정 구현은 빈 스트림이다.
  Stream<HealthMeasurement> get measurements => const Stream.empty();
  @override
  /// [인수인계] 워치 연결 명령 계약이다. 기본 미설정 구현은 연결 성공을 만들지 않는다.
  Future<void> connect() async => throw StateError('워치 연결 모듈이 아직 연결되지 않았습니다.');
  @override
  /// [인수인계] 워치 연결 해제 명령 계약이다. 미설정 구현은 별도 장치 동작이 없다.
  Future<void> disconnect() async {}
  @override
  /// [인수인계] 새 측정 요청 계약이다. 미설정 구현은 오류를 알리고 가상값을 반환하지 않는다.
  Future<void> requestMeasurement() async =>
      throw StateError('워치를 먼저 연결해 주세요.');
}
