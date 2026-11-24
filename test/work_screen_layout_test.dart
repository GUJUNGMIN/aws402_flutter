import 'mobile_api_stub.dart';

import 'package:aws402_flutter/l10n/app_localizations.dart';
import 'package:aws402_flutter/router/app_routes.dart';
import 'package:aws402_flutter/mobile/home_dashboard.dart';
import 'package:aws402_flutter/widgets/work_widget.dart';
import 'package:aws402_flutter/widgets/main_widget.dart';
import 'package:aws402_flutter/widgets/health_metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(configureMobileApiStub);
  testWidgets('일반 휴대폰 크기의 근무 화면은 스크롤 없이 주요 버튼을 표시한다', (tester) async {
    // 구정민 : 근무 화면이 360×640 논리 픽셀에서 넘치지 않고 주요 버튼이 노출되는지 확인한다.
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(color: Colors.blueGrey),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: WorkWidget(
                workStartedAt: DateTime(2026, 11, 18, 9),
                watchConnected: true,
                onButtonPressed: () {},
                onRestPressed: () {},
                onHistoryPressed: () {},
                onHealthHistoryPressed: () {},
                onContactPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await settleMobileApi(tester);

    expect(find.text('근무 중'), findsOneWidget);
    // 구정민 : 수정 - WEATHER 데이터가 없는 경우에도 가짜 특보 없이 한 화면에 표시한다.
    expect(find.text('날씨 자료 없음'), findsOneWidget);
    expect(find.text('WEATHER 테이블에 관측값이 없습니다'), findsOneWidget);
    expect(find.text('99℃'), findsNothing);
    expect(find.text('심박수'), findsOneWidget);
    expect(find.text('피부온도'), findsOneWidget);
    expect(find.text('산소포화도'), findsOneWidget);
    // 구정민 : 수정 - 낙상 카드와 응급 버튼은 화면에서 숨기며 기본 건강 카드만 유지한다.
    expect(find.text('낙상여부'), findsNothing);
    expect(find.text('응급'), findsNothing);
    expect(find.text('주의'), findsNothing);
    expect(find.text('경고'), findsNothing);
    expect(find.text('위험'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('휴식하기'), findsOneWidget);
    expect(find.text('근무종료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('근무 중·휴식 중 모두 날씨 4개 수치가 상태 바 위에 표시된다', (tester) async {
    // 구정민 : 수정 - 요청한 날씨↔근무 상태 표시 순서와 작은 화면의 overflow를 회귀 검사한다.
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const weather = WeatherSnapshot(
      temperatureCelsius: 12.4,
      condition: '강수 없음',
      notice: '강풍 유의',
      rainfallMm: 0,
      humidityPercent: 65,
      windDirectionDegrees: 315,
      windSpeedMs: 14.2,
      stale: false,
      regionMatched: false,
      officialAdvisoryAvailable: false,
      baseDate: '20261119',
      baseTime: '1618',
      recentObservations: [],
    );
    for (final resting in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: WorkWidget(
                  weather: weather,
                  isResting: resting,
                  watchConnected: true,
                  workStartedAt: DateTime(2026, 11, 19, 9),
                  onButtonPressed: () {},
                  onRestPressed: () {},
                  onHistoryPressed: () {},
                  onHealthHistoryPressed: () {},
                  onContactPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0.0mm'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('북서풍'), findsOneWidget);
      expect(find.text('14.2m/s'), findsOneWidget);
      expect(find.text('관측 날씨 · 강풍 유의'), findsNothing);
      final status = find.text(resting ? '휴식 중' : '근무 중');
      expect(
        tester.getTopLeft(find.text('강수량')).dy,
        lessThan(tester.getTopLeft(status).dy),
      );
      expect(
        tester.getTopLeft(status).dy,
        lessThan(tester.getTopLeft(find.text('워치 연결 상태')).dy),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('시작 전에는 워치·건강 미완료 안내가 나타나고 워치 상태는 빨강이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await settleMobileApi(tester);
    expect(find.text('해제'), findsOneWidget);
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.text('업무 시작 전 확인'), findsOneWidget);
    expect(find.textContaining('워치 연결'), findsWidgets);
    expect(find.textContaining('위치 확인'), findsNothing);
    expect(find.textContaining('최초 건강 측정'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('720×1280 에뮬레이터에서 업무 시작 후 카드 레이아웃 오류가 없다', (tester) async {
    // 구정민 : 수정 - 실제 메인 버튼을 눌러 WorkWidget으로 전환할 때 카드 높이 넘침을 검사한다.
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await settleMobileApi(tester);
    expect(find.text('업무 시작하기'), findsOneWidget);
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.text('업무 시작 전 확인'), findsOneWidget);
    await tester.tap(find.text('확인하러 가기'));
    await settleMobileApi(tester);
    // 구정민 : STEP 2에서는 위치 권한 승인 UI를 제공하되 근무 시작 전 필수 항목이 아니다.
    expect(find.text('GPS 위치 권한'), findsOneWidget);
    expect(find.textContaining('거부해도 건강 측정'), findsOneWidget);

    await tapMobileButton(tester, '워치 연결');
    // 구정민 : 수정 - 별도 서버·MySQL 확인 버튼 없이 건강 측정의 DB 저장 응답으로 연결 여부를 확인한다.
    expect(find.text('서버 · MySQL 연결 확인'), findsNothing);

    await tapMobileButton(tester, '건강 측정');
    expect(find.text('서버 저장 완료 · 서버 판정: NORMAL'), findsOneWidget);
    expect(find.text('서버 · MySQL 연결 확인'), findsNothing);

    await tapMobileButton(tester, '메인으로 돌아가기');
    // 구정민 : 수정 - 근무 시작 전에도 서버 저장된 최초 측정 결과가 표시된다.
    expect(find.text('오늘도 안전하게 근무하세요!'), findsNothing);
    expect(find.text('85 bpm'), findsOneWidget);
    expect(find.text('36.5 ℃'), findsOneWidget);
    expect(find.text('98%'), findsOneWidget);
    expect(find.text('NORMAL'), findsNWidgets(3));
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.byType(WorkWidget), findsOneWidget);
    expect(find.text('근무 중'), findsOneWidget);
    expect(find.text('워치 연결 상태'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('근무 종료 후 워치 연결은 유지하고 새 건강 측정 전 시작을 막는다', (tester) async {
    // 구정민 : 종료 후 건강 측정이 초기화되는지 실제 메인 버튼 흐름에서 검증한다.
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await settleMobileApi(tester);
    await tester.tap(find.text('워치 연결·건강 측정'));
    await settleMobileApi(tester);

    await tapMobileButton(tester, '워치 연결');

    await tapMobileButton(tester, '건강 측정');

    await tapMobileButton(tester, '메인으로 돌아가기');
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.text('근무 중'), findsOneWidget);
    await tester.tap(find.text('근무종료'));
    await settleMobileApi(tester);
    await tester.tap(find.text('종료'));
    await settleMobileApi(tester);
    expect(find.text('건강 측정'), findsOneWidget);
    expect(find.text('건강 미측정'), findsOneWidget);
    expect(find.text('오늘도 안전하게 근무하세요!'), findsOneWidget);
    expect(find.byKey(const ValueKey('saved-health-results')), findsNothing);
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.text('업무 시작 전 확인'), findsOneWidget);
    expect(find.textContaining('최초 건강 측정'), findsWidgets);
    await tester.tap(find.text('확인하러 가기'));
    await settleMobileApi(tester);
    // 구정민 : 수정 - 이전 서버 측정 카드 아래의 워치 버튼까지 목록을 펼쳐 확인한다.
    await tester.scrollUntilVisible(
      find.text('워치 연결 해제'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await settleMobileApi(tester);
    expect(find.text('워치 연결 해제'), findsOneWidget);
    expect(find.text('위치 확인 테스트'), findsNothing);

    await tapMobileButton(tester, '건강 측정');

    await tapMobileButton(tester, '메인으로 돌아가기');
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.text('근무 중'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  // 구정민 : 수정 - 저장 실패·비정상 판정·연결 해제를 메인 화면 왕복으로 회귀 검사한다.
  for (final scenario in [
    'unsaved',
    'failed',
    'NOTICE',
    'WARNING',
    'DANGER',
    'disconnect',
  ]) {
    testWidgets('최초 측정 결과 표시: $scenario', (tester) async {
      configureMobileApiStub(
        measurementSaved: scenario != 'unsaved',
        measurementFails: scenario == 'failed',
        measurementStatus: ['NOTICE', 'WARNING', 'DANGER'].contains(scenario)
            ? scenario
            : null,
      );
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await settleMobileApi(tester);
      expect(find.text('오늘도 안전하게 근무하세요!'), findsOneWidget);
      expect(find.byKey(const ValueKey('saved-health-results')), findsNothing);
      await tester.tap(find.text('워치 연결·건강 측정'));
      await settleMobileApi(tester);

      await tapMobileButton(tester, '워치 연결');

      await tapMobileButton(tester, '건강 측정');
      if (scenario == 'disconnect') {
        await tapMobileButton(tester, '워치 연결 해제');
        // 구정민 : 수정 - 재연결만으로 이전 측정 결과가 다시 표시되면 안 된다.

        await tapMobileButton(tester, '워치 연결');
      }

      await tapMobileButton(tester, '메인으로 돌아가기');
      if (['NOTICE', 'WARNING', 'DANGER'].contains(scenario)) {
        expect(find.text('85 bpm'), findsOneWidget);
        expect(find.text('36.5 ℃'), findsOneWidget);
        expect(find.text('98%'), findsOneWidget);
        expect(find.text(scenario), findsNWidgets(3));
        expect(find.text('오늘도 안전하게 근무하세요!'), findsNothing);
        expect(find.text('건강 미측정'), findsOneWidget);
      } else {
        expect(find.text('오늘도 안전하게 근무하세요!'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('saved-health-results')),
          findsNothing,
        );
        expect(find.text('85 bpm'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
  // 구정민 : 수정 - 작은 휴대폰에서도 근무 전 2+1 카드의 수치와 판정이 모두 보이는지 검사한다.
  for (final size in [
    const Size(335, 604),
    const Size(360, 640),
    const Size(412, 892),
  ]) {
    testWidgets('근무 전 건강 카드 배치 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(toolbarHeight: 80),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: MainWidget(
                  onButtonPressed: () {},
                  onHealthCheckPressed: () {},
                  onWorkHistoryPressed: () {},
                  onHealthHistoryPressed: () {},
                  healthCheckCompleted: true,
                  watchConnected: true,
                  measurementSaved: true,
                  latestBpm: 85,
                  latestTemperature: 36.5,
                  latestSpo2: 97,
                  latestGrade: 'NORMAL',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bpm = tester.getRect(find.byKey(const ValueKey('prework-bpm')));
      final temp = tester.getRect(
        find.byKey(const ValueKey('prework-temperature')),
      );
      final spo2 = tester.getRect(find.byKey(const ValueKey('prework-spo2')));
      expect(bpm.top, temp.top);
      expect(bpm.right, lessThan(temp.left));
      expect(spo2.top, greaterThan(bpm.bottom));
      expect(spo2.left, bpm.left);
      expect(spo2.right, temp.right);
      expect(find.text('NORMAL'), findsNWidgets(3));
      expect(find.byType(SingleChildScrollView), findsNothing);
      for (final text in ['85 bpm', '36.5 ℃', '97%', 'NORMAL']) {
        for (final element in find.text(text).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.top, greaterThanOrEqualTo(bpm.top));
          expect(rect.bottom, lessThanOrEqualTo(spo2.bottom));
          expect(rect.left, greaterThanOrEqualTo(bpm.left));
          expect(rect.right, lessThanOrEqualTo(temp.right));
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
  // 구정민 : 수정 - 근무 전·중·휴식 중 카드의 좌우 배치와 수치·판정의 표시 크기를 확인한다.
  for (final phase in ['ready', 'working', 'resting']) {
    testWidgets('건강 카드 좌우 배치와 글자 크기: $phase', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final body = phase == 'ready'
          ? MainWidget(
              onButtonPressed: () {},
              onHealthCheckPressed: () {},
              onWorkHistoryPressed: () {},
              onHealthHistoryPressed: () {},
              healthCheckCompleted: true,
              watchConnected: true,
              measurementSaved: true,
              latestBpm: 85,
              latestTemperature: 36.5,
              latestSpo2: 97,
              latestGrade: 'NORMAL',
            )
          : WorkWidget(
              onButtonPressed: () {},
              onRestPressed: () {},
              onHistoryPressed: () {},
              onHealthHistoryPressed: () {},
              onContactPressed: () {},

              isResting: phase == 'resting',
              watchConnected: true,
              latestBpm: 85,
              latestTemperature: 36.5,
              latestSpo2: 97,
              latestGrade: 'NORMAL',
            );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(toolbarHeight: 80),
            body: Padding(padding: const EdgeInsets.all(8), child: body),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HealthMetricCard), findsNWidgets(3));
      for (final card in find.byType(HealthMetricCard).evaluate()) {
        final scope = find.byWidget(card.widget);
        final metric = card.widget as HealthMetricCard;
        // 구정민 : 수정 - 좁은 카드와 넓은 카드 모두 내용 묶음이 카드 중앙에 놓이는지 확인한다.
        final content = find.descendant(
          of: scope,
          matching: find.byKey(const ValueKey('health-card-content')),
        );
        final cardRect = tester.getRect(scope);
        final contentRect = tester.getRect(content);
        expect(contentRect.center.dx, closeTo(cardRect.center.dx, 0.1));
        expect(contentRect.center.dy, closeTo(cardRect.center.dy, 0.1));
        expect(contentRect.width, lessThanOrEqualTo(180));
        final label = find.descendant(
          of: scope,
          matching: find.text(metric.title),
        );
        final value = find.descendant(
          of: scope,
          matching: find.text(metric.value),
        );
        final status = find.descendant(
          of: scope,
          matching: find.text('NORMAL'),
        );
        expect(
          tester.getRect(label).right,
          lessThan(tester.getRect(value).left),
        );
        expect(
          tester.getRect(value).bottom,
          lessThan(tester.getRect(status).top),
        );
        expect(tester.getSize(value).height, greaterThanOrEqualTo(20));
        expect(tester.getSize(status).height, greaterThanOrEqualTo(14));
      }
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
