import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:aws402_flutter/models/work_state.dart';
import 'package:aws402_flutter/screens/health_history_screen.dart';
import 'package:aws402_flutter/screens/work_history_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

// 구정민 : STEP 2 기간별 근무 카드 및 상태 이력 펼치기 UI의 서버 응답 연동을 검증한다.
void main() {
  String date(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  testWidgets('근무 이력은 최근 7일 검색 조건과 시작 시각 최신순 카드를 표시한다', (tester) async {
    final today = DateTime.now();
    final end = date(today);
    final yesterday = date(today.subtract(const Duration(days: 1)));
    final expectedFrom = date(today.subtract(const Duration(days: 7)));
    Map<String, dynamic>? requestRange;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestRange = options.queryParameters;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'workId': 1,
                  'jobTitle': '오래된 일자리',
                  'region': '경남 김해',
                  'startedAt': '${yesterday}T09:00:00',
                  'endedAt': '${yesterday}T17:00:00',
                  'status': 'COMPLETED',
                  'totalMinutes': 480,
                  'restMinutes': 60,
                  'workingMinutes': 420,
                  'noticeCount': 0,
                  'warningCount': 0,
                  'dangerCount': 0,
                },
                {
                  'workId': 2,
                  'jobTitle': '최신 일자리',
                  'region': '경남 부산',
                  'startedAt': '${end}T08:00:00',
                  'endedAt': '${end}T16:00:00',
                  'status': 'COMPLETED',
                  'totalMinutes': 480,
                  'restMinutes': 60,
                  'workingMinutes': 420,
                  'noticeCount': 2,
                  'warningCount': 1,
                  'dangerCount': 0,
                },
              ],
            ),
          );
        },
      ),
    );
    MobileApi.instance = MobileApi(dio: dio);

    await tester.pumpWidget(
      const MaterialApp(home: WorkHistoryScreen(entries: <WorkHistoryEntry>[])),
    );
    await tester.pumpAndSettle();

    expect(requestRange?['from'], expectedFrom);
    expect(requestRange?['to'], end);
    expect(find.text('조회 결과 2건'), findsOneWidget);
    final first = tester.getTopLeft(find.text('최신 일자리'));
    final second = tester.getTopLeft(find.text('오래된 일자리'));
    expect(first.dy, lessThan(second.dy));
    expect(find.text('2회'), findsOneWidget);
    expect(find.text('특이사항 없음'), findsOneWidget);
    expect(find.text('정상'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜 행을 펼치면 별도 페이지 이동 없이 해당 날짜의 알림 발생 시각을 보여준다', (tester) async {
    final day = date(DateTime.now());
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'date': day,
                  'noticeCount': 1,
                  'warningCount': 1,
                  'dangerCount': 0,
                  'events': [
                    {
                      'alertId': 2,
                      'status': 'WARNING',
                      'occurredAt': '${day}T11:55:34',
                    },
                    {
                      'alertId': 1,
                      'status': 'NOTICE',
                      'occurredAt': '${day}T11:55:41',
                    },
                  ],
                },
              ],
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
    await tester.pumpAndSettle();
    expect(find.text('11:55:34'), findsNothing);
    await tester.tap(
      find.text(DateFormat('yyyy.MM.dd').format(DateTime.now())).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('11:55:34'), findsOneWidget);
    expect(find.text('11:55:41'), findsOneWidget);
    expect(find.text('경고 발생'), findsOneWidget);
    expect(find.byType(HealthHistoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
