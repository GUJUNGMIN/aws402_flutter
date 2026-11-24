import 'fake_watch_client.dart';

import 'package:aws402_flutter/watch/watch_client.dart';

export 'fake_watch_client.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:dio/dio.dart';

// 구정민 : 테스트 중 실제 DB/네트워크를 사용하지 않고 REST 응답을 모의하여 UI 흐름을 검증한다.
// 구정민 : GPS는 플러그인 테스트 환경에서 미승인(null)으로 처리되어도 건강 데이터가 전송된다.
void configureMobileApiStub({
  bool measurementSaved = true,
  String? measurementStatus,
  bool measurementFails = false,
  FakeWatchClient? watch,
  List<Map<String, dynamic>>? requests,
}) {
  final client = watch ?? FakeWatchClient();
  WatchClient.instance = client;
  addTearDown(client.close);
  var lastStatus = 'NORMAL';
  // 구정민 : 수정 - 실제 서버와 동일하게 근무 이벤트별 단계와 상단 일자리 표시를 변경한다.
  var workPhase = 'READY';
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;
        requests?.add({'path': path, 'body': options.data});
        dynamic payload;
        if (path == '/api/mobile/ping') {
          payload = {'status': 'READY'};
        } else if (path == '/api/mobile/db-check') {
          payload = {'status': 'CONNECTED'};
        } else if (path == '/api/mobile/home') {
          payload = {
            'userIdx': 1,
            'name': '모바일테스트',
            'job': workPhase == 'READY'
                ? null
                : {'title': '시범 환경 정비', 'allocationIdx': 1},
            'workPhase': workPhase,
            'weather': {
              'temperatureCelsius': 24.5,
              'condition': '강수 없음',
              'notice': '특이사항 없음 (관측 기준)',
              'stale': false,
              'regionMatched': false,
              'officialAdvisoryAvailable': false,
              'baseDate': '20261119',
              'baseTime': '1000',
              'recentObservations': [
                {
                  'date': '20261119',
                  'time': '10:00',
                  'temperatureCelsius': 24.5,
                },
              ],
            },
          };
        } else if (path == '/api/mobile/measurements') {
          // 구정민 : 수정 - 저장 미확인과 통신 실패 응답을 회귀 검사한다.
          if (measurementFails) {
            handler.reject(
              DioException(requestOptions: options, message: '측정 저장 실패'),
            );
            return;
          }
          final values = Map<String, dynamic>.from(options.data as Map);
          final bpm = (values['bpm'] as num).toInt();
          final temp = (values['skinTemperature'] as num).toDouble();
          final spo2 = (values['spo2'] as num).toInt();
          final next = values['fallDetected'] == true
              ? 'EMERGENCY'
              : bpm >= 130 || temp >= 38.5 || spo2 <= 89
              ? 'DANGER'
              : bpm >= 110 || temp >= 38.0 || spo2 <= 93
              ? 'WARNING'
              : bpm >= 95 || temp >= 37.5 || spo2 <= 95
              ? 'NOTICE'
              : 'NORMAL';
          payload = {
            'measurement': {
              'sampleId': values['sampleId'],
              'measuredAt': values['measuredAt'],
              'bpm': bpm,
              'skinTemperature': temp,
              'spo2': spo2,
            },
            'saved': measurementSaved,
            'status': measurementStatus ?? next,
            'previousStatus': lastStatus,
            'statusChanged': next != lastStatus,
          };
          lastStatus = next;
        } else if (path == '/api/mobile/work/events') {
          final action = (options.data as Map)['event']?.toString();
          workPhase = switch (action) {
            'START' || 'RESUME' => 'WORKING',
            'REST' => 'RESTING',
            'END' => 'READY',
            _ => workPhase,
          };
          payload = {'saved': true, 'phase': workPhase};
        } else if (path == '/api/mobile/work/status') {
          payload = {'phase': workPhase, 'hasAllocation': true};
        } else if (path == '/api/mobile/history/work-summary' ||
            path == '/api/mobile/history/status-summary') {
          // 구정민 : 수정 - 날짜 범위 API도 실제 MySQL 대신 빈 정상 응답으로 회귀 테스트한다.
          payload = <Map<String, dynamic>>[];
        } else if (path.startsWith('/api/mobile/history/')) {
          payload = <Map<String, dynamic>>[];
        } else {
          handler.reject(
            DioException(
              requestOptions: options,
              message: '모의 서버에 없는 API: $path',
            ),
          );
          return;
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: payload,
            statusCode: 200,
          ),
        );
      },
    ),
  );
  MobileApi.instance = MobileApi(dio: dio);
}

// 구정민 : 수정 - Dio의 비동기 인터셉터가 끝난 뒤 화면을 검사한다.
Future<void> settleMobileApi(WidgetTester tester) async {
  // 구정민 : 수정 - 요청→응답→후속 요청이 서로 다른 이벤트 루프에서 실행되는 경우도 기다린다.
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

// 구정민 : 수정 - 스크롤 영역의 버튼 전체를 표시한 뒤 누른다.
Future<void> tapMobileButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(
    label == '메인으로 돌아가기' ? OutlinedButton : FilledButton,
    label,
  );
  await tester.scrollUntilVisible(
    button,
    100,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  // 구정민 : 수정 - 이전 근무 종료 알림이 하단 버튼 터치를 가리지 않게 한다.
  ScaffoldMessenger.of(tester.element(button)).removeCurrentSnackBar();
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(button);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await settleMobileApi(tester);
}

FakeWatchClient get fakeWatch => WatchClient.instance as FakeWatchClient;
