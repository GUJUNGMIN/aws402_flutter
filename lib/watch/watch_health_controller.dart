// [인수인계] 신규 워치 이벤트 검사 → GPS 포함 HTTP 전송 → 저장 확인 → WorkState 갱신을 조정한다. 실패/전송 중 샘플은 재전송 큐에 쌓지 않는다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/step2_feature_flags.dart';
import '../mobile/mobile_api.dart';
import '../models/health_measurement.dart';
import '../models/work_state.dart';
import 'watch_client.dart';

// 구정민 : 수정 - 새 워치값 수신 → GPS 포함 전송 → 서버 저장/판정 확인을 한 경로로 처리한다.
class WatchHealthController extends ChangeNotifier {
  final WatchClient watch;
  final MobileApi api;
  final WorkState state;
  final DateTime Function() now;
  final Duration maxSampleAge;
  final Duration measurementTimeout;
  final void Function(HealthMeasurement, String)? onStatusChanged;
  late final StreamSubscription<HealthMeasurement> _subscription;
  WatchConnection? _connection;
  DateTime? _lastSampleTime;
  DateTime? _acceptAfter;
  String? _lastSampleId;
  Timer? _measurementTimer;
  bool _disposed = false;
  int _generation = 0;
  bool sending = false;
  bool waitingForMeasurement = false;
  String message = '워치를 연결하고 건강 측정을 진행해 주세요.';

  /// [인수인계] 수신 스트림과 연결 리스너를 구독한다. 주입받은 상태를 홈/측정 화면이 공유하며 dispose에서 해제한다.
  WatchHealthController({
    WatchClient? watch,
    MobileApi? api,
    WorkState? state,

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    DateTime Function()? now,
    this.maxSampleAge = const Duration(minutes: 2),
    this.measurementTimeout = const Duration(seconds: 90),
    this.onStatusChanged,
  }) : watch = watch ?? WatchClient.instance,
       api = api ?? MobileApi.instance,
       state = state ?? WorkState(),
       now = now ?? DateTime.now {
    this.watch.addListener(_connectionChanged);
    _subscription = this.watch.measurements.listen(
      _receive,
      onError: (Object error) {
        if (_disposed) return;
        _finishWaiting();
        message = '워치 측정값을 수신하지 못했습니다.';
        notifyListeners();
      },
      onDone: () {
        if (!_disposed && this.state.watchConnected) {
          _connection = WatchConnection.disconnected;
          _invalidate('워치 데이터 연결이 종료되었습니다.', disconnected: true);
        }
      },
    );
    _connectionChanged();
  }

  /// [인수인계] 최초 수신 대기 또는 HTTP 저장 중인지 반환해 요청/근무 시작 중복을 막는다.
  bool get busy => sending || waitingForMeasurement;

  /// [인수인계] 어댑터가 보고한 현재 연결 상태를 노출한다. 실제 장치 연결 이벤트가 원본이다.
  WatchConnection get connection => _connection ?? WatchConnection.disconnected;

  /// [인수인계] 연결 이벤트가 달라졌을 때 이전 최초 측정 완료 상태와 진행 중 응답의 유효성을 초기화한다.
  void _connectionChanged() {
    if (_disposed || _connection == watch.connection) return;
    _connection = watch.connection;
    _invalidate(
      _connection == WatchConnection.connected
          ? '워치 연결 완료. 새 건강 측정을 진행해 주세요.'
          : '워치 연결을 확인해 주세요.',
      disconnected: _connection != WatchConnection.connected,
    );
  }

  /// [인수인계] 세대 번호를 올려 이전 비동기 응답을 무효화하고 이번 연결/근무의 측정 기준 시각을 갱신한다.
  void _invalidate(String text, {required bool disconnected}) {
    _generation++;
    _acceptAfter = now();
    _finishWaiting();
    state.updateWatchConnection(!disconnected);
    state.resetInitialMeasurement();
    message = text;
    notifyListeners();
  }

  // 구정민 : 수정 - 근무 종료/전환 중 응답이 이전 측정 완료 상태를 되살리지 않게 한다.
  /// [인수인계] 워치 연결은 유지하면서 다음 근무의 최초 측정 완료 조건을 초기화한다.
  void resetForNextWork() => _invalidate(
    '다음 근무 전에 새 건강 측정이 필요합니다.',
    disconnected: connection != WatchConnection.connected,
  );

  /// [인수인계] 실제 어댑터에 연결을 요청한다. 성공 상태는 어댑터 이벤트로만 반영한다.
  Future<void> connect() async {
    try {
      await watch.connect();
    } catch (error) {
      if (!_disposed) {
        message = MobileApi.errorMessage(error);
        notifyListeners();
      }
    }
  }

  /// [인수인계] 실제 연결 해제를 요청하고 명령 실패를 사용자 메시지로 표시한다.
  Future<void> disconnect() async {
    try {
      await watch.disconnect();
    } catch (error) {
      if (!_disposed) {
        message = MobileApi.errorMessage(error);
        notifyListeners();
      }
    }
  }

  /// [인수인계] 중복 요청을 막고 요청 이후의 새 샘플을 기다린다. 90초 대기 타이머는 측정값 생성용이 아니다.
  Future<void> requestMeasurement() async {
    if (_disposed || busy || !state.watchConnected) return;
    waitingForMeasurement = true;
    _acceptAfter = now();
    message = '워치의 새 측정값을 기다리는 중입니다.';
    _measurementTimer?.cancel();
    _measurementTimer = Timer(measurementTimeout, () {
      if (_disposed || !waitingForMeasurement) return;
      _finishWaiting();
      message = '측정값 수신 시간이 초과되었습니다. 다시 측정해 주세요.';
      notifyListeners();
    });
    notifyListeners();
    // 연결 해제/근무 종료 이후 돌아온 과거 HTTP 응답을 적용하지 않기 위한 요청 세대다.
    final generation = _generation;
    try {
      await watch.requestMeasurement();
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _finishWaiting();
      message = MobileApi.errorMessage(error);
      notifyListeners();
    }
  }

  /// [인수인계] 최초 측정 대기 타이머와 대기 플래그를 함께 정리한다.
  void _finishWaiting() {
    waitingForMeasurement = false;
    _measurementTimer?.cancel();
    _measurementTimer = null;
  }

  /// [인수인계] 신규·완전·시간 순서가 맞는 샘플만 전송한다. saved/판정/ID/시각을 확인한 DB 저장 수치만 화면에 반영한다.
  Future<void> _receive(HealthMeasurement sample) async {
    if (_disposed ||
        !state.watchConnected ||
        (state.phase == WorkPhase.ready &&
            !waitingForMeasurement &&
            !sending)) {
      return;
    }
    // 수신 검사는 형식·신선도·순서를 확인한다. 건강 등급은 아래 서버 응답으로만 결정한다.
    final current = now();
    if (!sample.isValid ||
        current.difference(sample.measuredAt) > maxSampleAge ||
        sample.measuredAt.isAfter(current.add(const Duration(seconds: 5))) ||
        (_acceptAfter != null && sample.measuredAt.isBefore(_acceptAfter!)) ||
        sample.sampleId == _lastSampleId ||
        (_lastSampleTime != null &&
            !sample.measuredAt.isAfter(_lastSampleTime!))) {
      message = '새롭고 완전한 워치 측정값이 필요합니다.';
      notifyListeners();
      return;
    }
    if (sample.fallDetected && !Step2FeatureFlags.showFall) {
      message = '현재 지원하지 않는 측정 신호입니다.';
      notifyListeners();
      return;
    }
    // 구정민 : 수정 - 실패한 측정도 재전송하지 않고 다음 신규 샘플만 받는다.
    _lastSampleId = sample.sampleId;
    _lastSampleTime = sample.measuredAt;
    if (sending) return; // 구정민 : 수정 - 전송 중 수신 샘플은 보관·재전송하지 않는다.
    _finishWaiting();
    sending = true;
    message = '측정값을 서버에 저장 중입니다.';
    notifyListeners();
    final generation = _generation;
    try {
      final response = await api.sendMeasurement(sample);
      if (_disposed || generation != _generation) return;
      final grade = response['status'];
      if (response['saved'] != true ||
          !const [
            'NORMAL',
            'NOTICE',
            'WARNING',
            'DANGER',
            'EMERGENCY',
          ].contains(grade)) {
        throw StateError('서버 저장 및 판정 결과를 확인하지 못했습니다.');
      }
      // 요청 수치가 아니라 DB 저장/반올림 수치를 읽어 화면의 서버 저장 확인값으로 사용한다.
      final storedJson = response['measurement'];
      if (storedJson is! Map) throw StateError('서버 저장 수치를 확인하지 못했습니다.');
      final stored = HealthMeasurement.fromServerJson(
        Map<String, dynamic>.from(storedJson),
      );
      if (stored.sampleId != sample.sampleId ||
          !stored.measuredAt.isAtSameMomentAs(sample.measuredAt)) {
        throw StateError('전송한 측정과 서버 저장 응답이 일치하지 않습니다.');
      }
      state.applyServerMeasurement(
        stored.bpm,
        stored.temperature,
        stored.spo2,
        sample.fallDetected,
        grade as String,
      );
      message = '서버 저장 완료 · 서버 판정: $grade';
      if (!Step2FeatureFlags.showEmergency &&
          Step2FeatureFlags.isEmergencyStatus(grade)) {
        message = '서버 저장 완료 · 현재 표시하지 않는 상태';
        state.serverMessage = message;
      } else if (response['statusChanged'] == true &&
          grade != 'NORMAL' &&
          state.phase != WorkPhase.ready) {
        onStatusChanged?.call(stored, grade);
      }
    } catch (error) {
      if (_disposed || generation != _generation) return;
      state.markServerFailure();
      message = MobileApi.errorMessage(error);
    } finally {
      sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  /// [인수인계] 타이머·연결 리스너·측정 구독을 정리하고 늦게 도착한 저장 응답을 무효화한다.
  void dispose() {
    _disposed = true;
    _generation++;
    _finishWaiting();
    watch.removeListener(_connectionChanged);
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
