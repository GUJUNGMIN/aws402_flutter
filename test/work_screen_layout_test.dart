import 'package:aws402_flutter/l10n/app_localizations.dart';
import 'package:aws402_flutter/router/app_routes.dart';
import 'package:aws402_flutter/widgets/work_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('일반 휴대폰 크기의 근무 화면은 스크롤 없이 주요 버튼을 표시한다', (tester) async {
    // 구정민 : 근무 화면이 360×640 논리 픽셀에서 넘치지 않고 주요 버튼이 노출되는지 확인한다.
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(
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
              showAlert: (_) {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('근무 중'), findsOneWidget);
    // 구정민 : 수정 - 날씨 예보와 건강 카드 4개를 유지하면서 스크롤이 생기지 않는지 확인한다.
    expect(find.text('오늘 날씨 (폭염주의보)'), findsOneWidget);
    expect(find.text('09시 99º'), findsOneWidget);
    expect(find.text('12시 34º'), findsOneWidget);
    expect(find.text('15시 35º'), findsOneWidget);
    expect(find.text('심박수'), findsOneWidget);
    expect(find.text('피부온도'), findsOneWidget);
    expect(find.text('산소포화도'), findsOneWidget);
    expect(find.text('낙상여부'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('휴식하기'), findsOneWidget);
    expect(find.text('근무종료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시작 전에는 워치·건강 미완료 안내가 나타나고 워치 상태는 빨강이다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    expect(find.text('해제'), findsOneWidget);
    await tester.tap(find.text('업무 시작하기'));
    await tester.pumpAndSettle();
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

    await tester.pumpWidget(MaterialApp(
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    expect(find.text('업무 시작하기'), findsOneWidget);
    await tester.tap(find.text('업무 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('업무 시작 전 확인'), findsOneWidget);
    await tester.tap(find.text('확인하러 가기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('워치 연결 테스트'));
    await tester.tap(find.text('워치 연결 테스트'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('건강 측정 테스트'));
    await tester.tap(find.text('건강 측정 테스트'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('메인으로 돌아가기'));
    await tester.tap(find.text('메인으로 돌아가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('업무 시작하기'));
    await tester.pumpAndSettle();
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
    await tester.pumpWidget(MaterialApp(
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('워치 연결·건강 측정 테스트'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('워치 연결 테스트'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('건강 측정 테스트'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('메인으로 돌아가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('업무 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('근무 중'), findsOneWidget);
    await tester.tap(find.text('근무종료'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('종료'));
    await tester.pumpAndSettle();
    expect(find.text('건강 측정 테스트'), findsOneWidget);
    expect(find.text('건강 미측정'), findsOneWidget);
    await tester.tap(find.text('업무 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('업무 시작 전 확인'), findsOneWidget);
    expect(find.textContaining('최초 건강 측정'), findsWidgets);
    await tester.tap(find.text('확인하러 가기'));
    await tester.pumpAndSettle();
    expect(find.text('워치 연결 해제 테스트'), findsOneWidget);
    expect(find.text('위치 확인 테스트'), findsNothing);
    await tester.tap(find.text('건강 측정 테스트'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('메인으로 돌아가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('업무 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('근무 중'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
