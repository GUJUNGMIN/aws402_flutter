import 'mobile_api_stub.dart';

import 'package:aws402_flutter/l10n/app_localizations.dart';
import 'package:aws402_flutter/router/app_routes.dart';
import 'package:aws402_flutter/screens/alert_screen.dart';
import 'package:aws402_flutter/screens/rest_screen.dart';
import 'package:aws402_flutter/widgets/work_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(configureMobileApiStub);
  Future<void> openWorkScreen(WidgetTester tester) async {
    // 구정민 : 실제 AppRoutes 설정으로 홈의 근무 시작 버튼을 눌러 테스트한다.
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
    // 구정민 : 수정 - 업무 시작 전에 테스트용 워치 연결·건강 측정만 완료한다.
    await tester.tap(find.text('워치 연결·건강 측정'));
    await settleMobileApi(tester);

    await tapMobileButton(tester, '워치 연결');

    await tapMobileButton(tester, '건강 측정');

    await tapMobileButton(tester, '메인으로 돌아가기');
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.byType(WorkWidget), findsOneWidget);
  }

  testWidgets('경고 화면의 휴식하기는 휴식 저장 후 휴식 화면으로 이동한다', (tester) async {
    await openWorkScreen(tester);
    fakeWatch.emit(fakeWatch.sample(bpm: 119));
    await settleMobileApi(tester);
    await tester.ensureVisible(find.text('휴식하기'));
    await settleMobileApi(tester);
    expect(find.byType(AlertScreen), findsOneWidget);
    await tester.ensureVisible(find.text('휴식하기'));
    await tester.tap(find.text('휴식하기'));
    await settleMobileApi(tester);
    expect(find.byType(RestScreen), findsOneWidget);
    expect(find.text('휴식 중'), findsWidgets);
  });

  testWidgets('휴식 화면을 뒤로 닫으면 홈에 휴식 중으로 남고 근무 재개가 가능하다', (tester) async {
    // 구정민 : 휴식 시작 후 단순 뒤로가기로는 근무가 자동 재개되지 않는지 확인한다.
    await openWorkScreen(tester);
    // 구정민 : 수정 - 작은 화면에서 큰 건강 글자를 유지하므로 하단 동작 버튼까지 스크롤한다.
    await tester.ensureVisible(find.text('휴식하기'));
    await settleMobileApi(tester);
    await tester.tap(find.text('휴식하기'));
    await settleMobileApi(tester);
    expect(find.text('휴식 중'), findsWidgets);
    Navigator.of(tester.element(find.byType(RestScreen))).pop();
    await settleMobileApi(tester);
    expect(find.text('휴식 중'), findsOneWidget);
    expect(find.text('근무 재개'), findsOneWidget);
    // 구정민 : 수정 - 작은 화면에서 큰 건강 글자를 유지하므로 하단 동작 버튼까지 스크롤한다.
    await tester.ensureVisible(find.text('근무 재개'));
    await settleMobileApi(tester);
    await tester.tap(find.text('근무 재개'));
    await settleMobileApi(tester);
    expect(find.text('근무 중'), findsOneWidget);
  });

  testWidgets('워치 수신의 서버 판정으로만 알림 화면이 열린다', (tester) async {
    await openWorkScreen(tester);
    // 구정민 : 수정 - 응급/낙상은 접근 경로만 숨기고 기존 AlertScreen 라우트는 보존한다.
    expect(find.text('응급'), findsNothing);
    expect(find.text('낙상여부'), findsNothing);
    for (final entry in <String, String>{
      '주의': 'notice',
      '경고': 'warning',
      '위험': 'danger',
    }.entries) {
      expect(find.widgetWithText(ElevatedButton, entry.key), findsNothing);
      final bpm = {'notice': 95, 'warning': 110, 'danger': 130}[entry.value]!;
      fakeWatch.emit(fakeWatch.sample(bpm: bpm));
      await settleMobileApi(tester);
      expect(find.byType(AlertScreen), findsOneWidget);
      expect(
        tester.widget<AlertScreen>(find.byType(AlertScreen)).type,
        entry.value,
      );
      // 구정민 : 알림 화면을 닫은 뒤 같은 근무 화면에서 다음 버튼을 검증한다.
      Navigator.of(tester.element(find.byType(AlertScreen))).pop('ack');
      await settleMobileApi(tester);
      expect(find.byType(WorkWidget), findsOneWidget);
    }
  });

  testWidgets('휴식하기 → 휴식 화면 → 근무 재개로 돌아온다', (tester) async {
    await openWorkScreen(tester);
    final restButton = find.text('휴식하기');
    await tester.ensureVisible(restButton);
    await settleMobileApi(tester);
    await tester.tap(restButton);
    await settleMobileApi(tester);
    expect(find.byType(RestScreen), findsOneWidget);
    // 구정민 : 수정 - 작은 화면에서 큰 건강 글자를 유지하므로 하단 동작 버튼까지 스크롤한다.
    await tester.ensureVisible(find.text('근무 재개'));
    await settleMobileApi(tester);
    await tester.tap(find.text('근무 재개'));
    await settleMobileApi(tester);
    expect(find.byType(WorkWidget), findsOneWidget);
    expect(find.byType(RestScreen), findsNothing);
  });
}
