import 'dart:async';

import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:aws402_flutter/watch/watch_client.dart';
import 'package:aws402_flutter/watch/watch_bridge_client.dart';
import 'package:aws402_flutter/watch/watch_health_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_watch_client.dart';

Future<void> until(bool Function() complete) async {
  for (var i = 0; i < 200 && !complete(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(complete(), true, reason: '비동기 처리 완료');
}

void main() {
  late FakeWatchClient watch;
  late WatchHealthController controller;
  late List<Map<String, dynamic>> posted;
  late Map<String, dynamic> response;
  Completer<void>? responseGate;

  setUp(() {
    watch = FakeWatchClient();
    posted = [];
    response = {'saved': true, 'status': 'NORMAL', 'statusChanged': false};
    responseGate = null;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          posted.add(Map<String, dynamic>.from(options.data as Map));
          if (responseGate != null) await responseGate!.future;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                ...response,
                'measurement':
                    response['measurement'] ??
                    Map<String, dynamic>.from(options.data as Map),
              },
              statusCode: 200,
            ),
          );
        },
      ),
    );
    controller = WatchHealthController(
      watch: watch,
      api: MobileApi(dio: dio),
    );
  });
  tearDown(() async {
    controller.dispose();
    await watch.close();
  });

  test('어댑터 미설정 시 연결 성공을 가장하지 않는다', () async {
    final unavailable = UnavailableWatchClient();
    await expectLater(unavailable.connect(), throwsStateError);
    expect(unavailable.connection, WatchConnection.disconnected);
    expect(controller.state.canStartWork, false);
    expect(posted, isEmpty);
  });

  test('7001과 7005 저장 응답을 정상과 응급으로 해석한다', () async {
    response = {'saved': true, 'statusCode': '7001'};
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    expect(controller.state.canStartWork, true);
    response = {'saved': true, 'statusCode': '7005', 'statusChanged': true};
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    expect(controller.state.latestGrade, 'EMERGENCY');
    expect(controller.state.canStartWork, false);
  });

  test('워치 실측 세 값만 저장 후 화면과 시작 조건에 반영한다', () async {
    await controller.connect();
    expect(controller.state.canStartWork, false);
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    expect(posted, hasLength(1));
    expect(posted.single.containsKey('steps'), false);
    expect(posted.single.containsKey('scenario'), false);
    expect(controller.state.latestBpm, 85);
    expect(controller.state.latestTemperature, 36.5);
    expect(controller.state.latestSpo2, 98);
    expect(controller.state.canStartWork, true);
  });

  test('저장 미확인/알 수 없는 판정은 측정 완료로 표시하지 않는다', () async {
    response = {'saved': false, 'status': 'NORMAL'};
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    expect(controller.state.hasSavedMeasurement, false);
    expect(controller.state.canStartWork, false);
    response = {'saved': true, 'status': 'UNKNOWN'};
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    expect(controller.state.hasSavedMeasurement, false);
    expect(controller.state.canStartWork, false);
  });

  test('정상 이후 비정상 최신 판정이면 시작 조건을 해제한다', () async {
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    expect(controller.state.canStartWork, true);
    response = {'saved': true, 'status': 'WARNING'};
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    expect(controller.state.latestGrade, 'WARNING');
    expect(controller.state.hasSavedMeasurement, true);
    expect(controller.state.canStartWork, false);
  });

  test('오래된 값·잘못된 값·중복 ID를 서버로 보내지 않는다', () async {
    watch.autoMeasure = false;
    await controller.connect();
    await controller.requestMeasurement();
    watch.emit(
      watch.sample(
        measuredAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    );
    watch.emit(watch.sample(temperature: double.nan));
    expect(posted, isEmpty);
    final sample = watch.sample();
    watch.emit(sample);
    await until(() => !controller.sending && posted.isNotEmpty);
    expect(posted, hasLength(1));
    controller.state.startWork();
    watch.emit(sample);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(posted, hasLength(1));
  });

  test('연결 해제 후 도착한 저장 응답은 표시·시작 상태를 복구하지 않는다', () async {
    responseGate = Completer<void>();
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => posted.isNotEmpty);
    await controller.disconnect();
    responseGate!.complete();
    await until(() => !controller.sending);
    expect(controller.state.watchConnected, false);
    expect(controller.state.hasSavedMeasurement, false);
    expect(controller.state.canStartWork, false);
    await controller.connect();
    expect(controller.state.canStartWork, false);
  });

  test('근무 종료 뒤 늦은 저장 응답과 기존 측정값을 재사용하지 않는다', () async {
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    controller.state.startWork();
    responseGate = Completer<void>();
    watch.emit(watch.sample());
    await until(() => posted.length == 2);
    controller.state.endWork();
    controller.resetForNextWork();
    responseGate!.complete();
    await until(() => !controller.sending);
    expect(controller.state.watchConnected, true);
    expect(controller.state.hasSavedMeasurement, false);
    expect(controller.state.canStartWork, false);
  });

  test('저장 중 새 샘플은 큐에 넣거나 나중에 재전송하지 않는다', () async {
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    controller.state.startWork();
    responseGate = Completer<void>();
    watch.emit(watch.sample());
    await until(() => posted.length == 2);
    final skipped = watch.sample();
    watch.emit(skipped);
    responseGate!.complete();
    await until(() => !controller.sending);
    watch.emit(skipped);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(posted, hasLength(2));
  });

  test('근무·휴식 중 새 수신마다 저장하며 가상 타이머 전송은 없다', () async {
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => !controller.sending);
    controller.state.startWork();
    watch.emit(watch.sample(bpm: 88));
    await until(() => posted.length == 2 && !controller.sending);
    controller.state.startRest();
    watch.emit(watch.sample(bpm: 79));
    await until(() => posted.length == 3 && !controller.sending);
    expect(controller.state.latestBpm, 79);
    expect(watch.requestedMeasurements, 1);
  });

  test('무응답 시간 초과 시 새 측정을 다시 요청할 수 있다', () async {
    controller.dispose();
    controller = WatchHealthController(
      watch: watch,
      measurementTimeout: const Duration(milliseconds: 10),
    );
    watch.autoMeasure = false;
    await controller.connect();
    await controller.requestMeasurement();
    await until(() => !controller.waitingForMeasurement);
    expect(controller.message, contains('시간이 초과'));
    expect(controller.state.canStartWork, false);
  });
  test('브리지 명령 완료만으로 가짜 연결을 확정하지 않는다', () async {
    var connects = 0;
    final bridge = WatchBridgeClient(
      onConnect: () async {
        connects++;
      },
      onDisconnect: () async {},
      onRequestMeasurement: () async {},
    );
    await bridge.connect();
    expect(connects, 1);
    expect(bridge.connection, WatchConnection.disconnected);
    final samples = <String>[];
    final subscription = bridge.measurements.listen(
      (sample) => samples.add(sample.sampleId),
    );
    bridge.reportMeasurement(watch.sample(id: 'before-connect'));
    expect(samples, isEmpty);
    bridge.reportConnection(WatchConnection.connected);
    bridge.reportMeasurement(watch.sample(id: 'real-device-sample'));
    expect(samples, ['real-device-sample']);
    await subscription.cancel();
    bridge.dispose();
  });
  test('전송값 대신 서버에 실제 저장된 수치를 표시한다', () async {
    watch.autoMeasure = false;
    await controller.connect();
    await controller.requestMeasurement();
    final sample = watch.sample(temperature: 36.567);
    response = {
      'saved': true,
      'status': 'NORMAL',
      'measurement': {...sample.toJson(), 'skinTemperature': 36.57},
    };
    watch.emit(sample);
    await until(() => !controller.sending);
    expect(controller.state.latestTemperature, 36.57);
    expect(controller.state.canStartWork, true);
  });

  test('다른 측정 ID 응답은 저장 완료로 표시하지 않는다', () async {
    watch.autoMeasure = false;
    await controller.connect();
    await controller.requestMeasurement();
    final sample = watch.sample();
    response = {
      'saved': true,
      'status': 'NORMAL',
      'measurement': {...sample.toJson(), 'sampleId': 'other-sample'},
    };
    watch.emit(sample);
    await until(() => !controller.sending);
    expect(controller.state.hasSavedMeasurement, false);
    expect(controller.state.canStartWork, false);
  });
}
