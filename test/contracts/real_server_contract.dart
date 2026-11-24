import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:aws402_flutter/models/health_measurement.dart';
import 'package:aws402_flutter/watch/watch_bridge_client.dart';
import 'package:aws402_flutter/watch/watch_client.dart';
import 'package:aws402_flutter/watch/watch_health_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoGps extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
}

Future<void> _wait(WatchHealthController controller) async {
  for (var i = 0; i < 500 && controller.sending; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(controller.sending, false);
}

// 구정민 : 수정 - 워치만 모의하고 Flutter Dio → 실제 Spring Boot HTTP → 격리 H2/MySQL DB를 검증한다.
void main() {
  const baseUrl = String.fromEnvironment('WATCH_CONTRACT_BASE_URL');
  test(
    '실제 Flutter–Spring Boot 저장·판정·근무 계약',
    () async {
      SharedPreferences.setMockInitialValues({});
      final originalGps = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = _NoGps();
      final api = MobileApi(dio: Dio(BaseOptions(baseUrl: baseUrl)));
      await api.login('watch1', 'watch-pass');
      late WatchBridgeClient bridge;
      var sample = HealthMeasurement(
        sampleId: 'flutter-contract-initial',
        measuredAt: DateTime.now(),
        bpm: 85,
        temperature: 36.567,
        spo2: 98,
      );
      bridge = WatchBridgeClient(
        onConnect: () async =>
            bridge.reportConnection(WatchConnection.connected),
        onDisconnect: () async =>
            bridge.reportConnection(WatchConnection.disconnected),
        onRequestMeasurement: () async {
          sample = HealthMeasurement(
            sampleId: sample.sampleId,
            measuredAt: DateTime.now(),
            bpm: sample.bpm,
            temperature: sample.temperature,
            spo2: sample.spo2,
          );
          bridge.reportMeasurement(sample);
        },
      );
      final controller = WatchHealthController(watch: bridge, api: api);
      try {
        await controller.connect();
        await controller.requestMeasurement();
        await _wait(controller);
        expect(controller.state.canStartWork, true, reason: controller.message);
        expect(controller.state.latestTemperature, 36.57);
        final duplicate = await api.sendMeasurement(sample);
        expect(duplicate['duplicate'], true);
        expect(duplicate['source'], 'WATCH');
        expect(duplicate.containsKey('demo'), false);
        expect((await api.workEvent('START'))['phase'], 'WORKING');
        controller.state.startWork();
        expect((await api.workEvent('REST'))['phase'], 'RESTING');
        controller.state.startRest();
        sample = HealthMeasurement(
          sampleId: 'flutter-contract-periodic',
          measuredAt: DateTime.now(),
          bpm: 79,
          temperature: 36.5,
          spo2: 98,
        );
        bridge.reportMeasurement(sample);
        await _wait(controller);
        expect(controller.state.latestBpm, 79, reason: controller.message);
        expect((await api.workEvent('RESUME'))['phase'], 'WORKING');
        controller.state.resumeWork();
        expect((await api.workEvent('END'))['phase'], 'READY');
        controller.state.endWork();
        controller.resetForNextWork();
        expect(controller.state.canStartWork, false);
        await expectLater(
          api.workEvent('START'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'HTTP status',
              409,
            ),
          ),
        );
        final history = await api.history('health', DateTime.now());
        expect(history, hasLength(2));
        expect(history.first['sampleId'], isNull);
        expect(history.first['timestampKind'], 'SERVER_RECEIVED');
        expect(history.first['measuredAt'], history.first['receivedAt']);
        expect(history.first['bpm'], 79);
      } finally {
        controller.dispose();
        bridge.dispose();
        await api.clearSession();
        GeolocatorPlatform.instance = originalGps;
      }
    },
    skip: baseUrl.isEmpty
        ? '격리 계약 서버 주소를 WATCH_CONTRACT_BASE_URL로 지정하세요.'
        : false,
  );
}
