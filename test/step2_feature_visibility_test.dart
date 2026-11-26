import 'mobile_api_stub.dart';

import 'package:aws402_flutter/config/step2_feature_flags.dart';
import 'package:aws402_flutter/mobile/history_summaries.dart';
import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:aws402_flutter/models/work_state.dart';
import 'package:aws402_flutter/screens/health_history_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 구정민 : 기존 숨김 정책 테스트를 새 기간별 상태 이력 API 구조에 맞춰 보완한다.
void main() {
  test('응급은 활성화하고 기존 낙상 표시 설정은 유지한다', () {
    expect(Step2FeatureFlags.showEmergency, true);
    expect(Step2FeatureFlags.showFall, false);
    expect(Step2FeatureFlags.isEmergencyStatus('EMERGENCY'), true);
    expect(Step2FeatureFlags.isEmergencyStatus('E'), true);
    expect(Step2FeatureFlags.isEmergencyStatus('DANGER'), false);
  });

  test('응급 상세 이벤트와 숫자 상태 코드를 표시한다', () {
    final parsed = DailyStatusSummary.fromJson({
      'date': '2026-11-20',
      'noticeCount': 1,
      'warningCount': 0,
      'dangerCount': 0,
      'emergencyCount': 1,
      'events': [
        {'alertId': 1, 'status': 'NOTICE', 'occurredAt': '2026-11-20T11:11:11'},
        {'alertId': 2, 'status': '7005', 'occurredAt': '2026-11-20T11:12:12'},
        {'alertId': 3, 'status': 'FALL', 'occurredAt': '2026-11-20T11:13:13'},
      ],
    });
    expect(parsed.events.length, 2);
    expect(parsed.emergencyCount, 1);
    expect(parsed.events.last.status, 'EMERGENCY');
    expect(parsed.events.first.status, 'NOTICE');
  });

  testWidgets('기간별 이력에 응급 발생과 횟수가 표시된다', (tester) async {
    final now = DateTime.now();
    final day =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final records = options.path.endsWith('/status-summary')
              ? <Map<String, dynamic>>[
                  {
                    'date': day,
                    'noticeCount': 1,
                    'warningCount': 0,
                    'dangerCount': 0,
                    'emergencyCount': 1,
                    'events': [
                      {
                        'alertId': 1,
                        'status': 'NOTICE',
                        'occurredAt': '${day}T10:00:00',
                      },
                      {
                        'alertId': 2,
                        'status': '7005',
                        'occurredAt': '${day}T10:20:00',
                      },
                    ],
                  },
                ]
              : <Map<String, dynamic>>[];
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: records,
              statusCode: 200,
            ),
          );
        },
      ),
    );
    MobileApi.instance = MobileApi(dio: dio);

    await tester.pumpWidget(
      const MaterialApp(
        home: HealthHistoryScreen(entries: <HealthHistoryEntry>[]),
      ),
    );
    await settleMobileApi(tester);

    expect(find.textContaining('주의 · 경고 · 위험 · 응급 발생 횟수'), findsOneWidget);
    expect(find.text('응급'), findsNothing);
    expect(find.text('낙상'), findsNothing);
    // 구정민 : 수정 - 날짜 카드를 펼친 뒤 기존 상세 횟수와 숨김 정책을 확인한다.
    final dateCard = find.widgetWithText(
      ExpansionTile,
      day.replaceAll('-', '.'),
    );
    await tester.ensureVisible(dateCard);
    await tester.tap(dateCard);
    await settleMobileApi(tester);
    expect(find.text('1회'), findsNWidgets(2));
    expect(find.text('주의 발생'), findsOneWidget);
    expect(find.text('응급 발생'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
