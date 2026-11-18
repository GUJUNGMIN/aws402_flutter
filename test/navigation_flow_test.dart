import 'package:aws402_flutter/l10n/app_localizations.dart';
import 'package:aws402_flutter/router/app_routes.dart';
import 'package:aws402_flutter/screens/alert_screen.dart';
import 'package:aws402_flutter/screens/rest_screen.dart';
import 'package:aws402_flutter/widgets/work_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openWorkScreen(WidgetTester tester) async {
    // 구정민 : 실제 AppRoutes 설정으로 홈의 근무 시작 버튼을 눌러 테스트한다.
    await tester.pumpWidget(MaterialApp(
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    // 구정민 : 수정 - 업무 시작 전에 테스트용 워치 연결·건강 측정만 완료한다.
    await tester.tap(find.text('워치 연결·건강 측정 테스트'));
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
  }

  testWidgets('휴식 화면을 뒤로 닫으면 홈에 휴식 중으로 남고 근무 재개가 가능하다', (tester) async {
    // 구정민 : 휴식 시작 후 단순 뒤로가기로는 근무가 자동 재개되지 않는지 확인한다.
    await openWorkScreen(tester);
    await tester.tap(find.text('휴식하기'));
    await tester.pumpAndSettle();
    expect(find.text('휴식 중'), findsWidgets);
    Navigator.of(tester.element(find.byType(RestScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('휴식 중'), findsOneWidget);
    expect(find.text('근무 재개'), findsOneWidget);
    await tester.tap(find.text('근무 재개'));
    await tester.pumpAndSettle();
    expect(find.text('근무 중'), findsOneWidget);
  });

  testWidgets('주의·경고·위험·응급 버튼은 각각 알림 화면으로 이동한다', (tester) async {
    await openWorkScreen(tester);
    for (final entry in <String, String>{
      '주의': 'notice',
      '경고': 'warning',
      '위험': 'danger',
      '응급': 'emergency',
    }.entries) {
      final button = find.widgetWithText(ElevatedButton, entry.key);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(AlertScreen), findsOneWidget);
      expect(tester.widget<AlertScreen>(find.byType(AlertScreen)).type, entry.value);
      // 구정민 : 알림 화면을 닫은 뒤 같은 근무 화면에서 다음 버튼을 검증한다.
      Navigator.of(tester.element(find.byType(AlertScreen))).pop('ack');
      await tester.pumpAndSettle();
      expect(find.byType(WorkWidget), findsOneWidget);
    }
  });

  testWidgets('휴식하기 → 휴식 화면 → 근무 재개로 돌아온다', (tester) async {
    await openWorkScreen(tester);
    final restButton = find.text('휴식하기');
    await tester.ensureVisible(restButton);
    await tester.pumpAndSettle();
    await tester.tap(restButton);
    await tester.pumpAndSettle();
    expect(find.byType(RestScreen), findsOneWidget);
    await tester.tap(find.text('근무 재개'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkWidget), findsOneWidget);
    expect(find.byType(RestScreen), findsNothing);
  });
}
