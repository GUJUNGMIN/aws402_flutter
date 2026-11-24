import 'package:aws402_flutter/mobile/home_dashboard.dart';
import 'package:aws402_flutter/widgets/weather_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 구정민 : 수정 - 기존 날씨 레이아웃 테스트를 삭제하지 않고 강수량·습도·풍향·풍속 4개 항목 검사로 변경한다.
void main() {
  WeatherSnapshot sampleWeather({bool regionMatched = false}) =>
      WeatherSnapshot(
        temperatureCelsius: 12.4,
        condition: '강수 없음',
        notice: '강풍 유의',
        rainfallMm: 0.0,
        humidityPercent: 65,
        windDirectionDegrees: 315,
        windSpeedMs: 14.2,
        stale: false,
        regionMatched: regionMatched,
        officialAdvisoryAvailable: false,
        baseDate: '20261119',
        baseTime: '1618',
        recentObservations: const [
          WeatherObservation(
            date: '20261119',
            time: '16:18',
            temperatureCelsius: 12.4,
          ),
        ],
      );

  testWidgets('근무 화면 날씨 패널은 4가지 관측값만 한 줄로 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              height: 56,
              child: WeatherSummaryWidget(
                weather: sampleWeather(),
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );

    for (final label in ['강수량', '습도', '풍향', '풍속']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final value in ['0.0mm', '65%', '북서풍', '14.2m/s']) {
      expect(find.text(value), findsOneWidget);
    }
    expect(find.text('12.4℃'), findsNothing);
    expect(find.text('관측 날씨 · 강풍 유의'), findsNothing);
    expect(find.text('16:18 12.4°'), findsNothing);
    expect(find.text('지역 미확인'), findsNothing);
    final x = [
      for (final label in ['강수량', '습도', '풍향', '풍속'])
        tester.getTopLeft(find.text(label)).dx,
    ];
    expect(x[0], lessThan(x[1]));
    expect(x[1], lessThan(x[2]));
    expect(x[2], lessThan(x[3]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('지역 확인 여부와 관계없이 수치 4개만 표시한다', (tester) async {
    for (final matched in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: 60,
              child: WeatherSummaryWidget(
                weather: sampleWeather(regionMatched: matched),
              ),
            ),
          ),
        ),
      );
      expect(find.text('지역 미확인'), findsNothing);
      expect(find.text('강수량'), findsOneWidget);
      expect(find.text('풍속'), findsOneWidget);
      expect(find.text('관측 날씨 · 강풍 유의'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('데이터 일부 누락과 긴 수치가 있어도 한 화면 안에서 표시한다', (tester) async {
    const weather = WeatherSnapshot(
      temperatureCelsius: 12.4,
      condition: '강수 없음',
      notice: '강풍 유의 · 외부 작업 시 주의',
      stale: false,
      rainfallMm: 0,
      humidityPercent: null,
      windDirectionDegrees: 360,
      windSpeedMs: 123.4,
      regionMatched: false,
      officialAdvisoryAvailable: false,
      baseDate: '20261119',
      baseTime: '1618',
      recentObservations: [],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 56,
              child: WeatherSummaryWidget(weather: weather, compact: true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('0.0mm'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('북풍'), findsOneWidget);
    expect(find.text('123.4m/s'), findsOneWidget);
    expect(find.textContaining('16:18'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날씨가 없거나 통신 실패한 경우의 안내는 계속 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 340, height: 62, child: WeatherSummaryWidget()),
        ),
      ),
    );
    expect(find.text('날씨 자료 없음'), findsOneWidget);
    expect(find.text('WEATHER 테이블에 관측값이 없습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            height: 62,
            child: WeatherSummaryWidget(failed: true),
          ),
        ),
      ),
    );
    expect(find.text('날씨 조회 실패'), findsOneWidget);
    expect(find.text('서버 연결 확인 필요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
