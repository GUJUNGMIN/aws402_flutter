import 'package:aws402_flutter/mobile/home_dashboard.dart';
import 'package:aws402_flutter/widgets/weather_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 구정민 : 모바일 홈 API의 실제 응답 형식 및 비어 있는 WEATHER 응답을 검증한다.
void main() {
  test('로그인 사용자 이름·일자리와 관측값을 서버 JSON에서 읽는다', () {
    final data = HomeDashboard.fromJson({
      'name': '홍길동',
      'job': {'title': '공원 안전 점검', 'allocationIdx': 8},
      'weather': {
        'temperatureCelsius': 25.5,
        'condition': '강수 없음',
        'notice': '특이사항 없음 (관측 기준)',
        'rainfallMm': 0.4,
        'humidityPercent': 72,
        'windDirectionDegrees': 270,
        'windSpeedMs': 5.6,
        'stale': false,
        'regionMatched': false,
        'officialAdvisoryAvailable': false,
        'baseDate': '20261119',
        'baseTime': '0900',
        'recentObservations': [
          {'date': '20261119', 'time': '09:00', 'temperatureCelsius': 25.5},
        ],
      },
    });
    expect(data.name, '홍길동');
    expect(data.jobTitle, '공원 안전 점검');
    expect(data.weather!.temperatureText, '25.5℃');
    expect(data.weather!.rainfallText, '0.4mm');
    expect(data.weather!.humidityText, '72%');
    expect(data.weather!.windDirectionText, '서풍');
    expect(data.weather!.windSpeedText, '5.6m/s');
    expect(data.weather!.officialAdvisoryAvailable, false);
  });

  test('근무 배정과 날씨 데이터가 없으면 하드코딩된 값을 대신 사용하지 않는다', () {
    final data = HomeDashboard.fromJson({
      'name': '홍길동',
      'job': null,
      'weather': null,
    });
    expect(data.hasJob, false);
    expect(data.weather, isNull);
  });

  test('방위각 값이 없거나 범위 밖이면 풍향을 추측하지 않는다', () {
    const base = WeatherSnapshot(
      condition: '강수 없음',
      notice: '',
      stale: false,
      regionMatched: false,
      officialAdvisoryAvailable: false,
      baseDate: '',
      baseTime: '',
      recentObservations: [],
    );
    expect(base.windDirectionText, '—');
    expect(
      WeatherSnapshot.fromJson({
        'condition': '강수 없음',
        'windDirectionDegrees': 361,
        'notice': '',
        'stale': false,
        'baseDate': '',
        'baseTime': '',
      }).windDirectionText,
      '—',
    );
  });

  testWidgets('날씨 패널에 서버의 관측 4개 지표만 나오고 가짜 폭염특보는 없다', (tester) async {
    final data = HomeDashboard.fromJson({
      'name': '홍길동',
      'job': null,
      'weather': {
        'temperatureCelsius': 25.5,
        'condition': '비',
        'rainfallMm': 2.5,
        'humidityPercent': 81,
        'windDirectionDegrees': 90,
        'windSpeedMs': 3.2,
        'notice': '강수 유의 · 미끄럼 주의',
        'stale': false,
        'regionMatched': false,
        'officialAdvisoryAvailable': false,
        'baseDate': '20261119',
        'baseTime': '0900',
        'recentObservations': [
          {'date': '20261119', 'time': '09:00', 'temperatureCelsius': 25.5},
        ],
      },
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WeatherSummaryWidget(weather: data.weather)),
      ),
    );
    expect(find.text('2.5mm'), findsOneWidget);
    expect(find.text('81%'), findsOneWidget);
    expect(find.text('동풍'), findsOneWidget);
    expect(find.text('3.2m/s'), findsOneWidget);
    expect(find.text('25.5℃'), findsNothing);
    expect(find.textContaining('강수 유의'), findsNothing);
    expect(find.textContaining('99'), findsNothing);
    expect(find.textContaining('폭염주의보'), findsNothing);
  });
}
