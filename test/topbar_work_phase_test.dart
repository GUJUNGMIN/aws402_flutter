import 'package:aws402_flutter/l10n/app_localizations.dart';
import 'package:aws402_flutter/mobile/home_dashboard.dart';
import 'package:aws402_flutter/models/work_state.dart';
import 'package:aws402_flutter/widgets/topbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 구정민 : 상단바는 배정 자체가 아닌 실제 근무 상태에서만 일자리명을 노출한다.
void main() {
  const dashboard = HomeDashboard(
    name: '모바일테스트',
    hasJob: true,
    jobTitle: 'STEP2 테스트 공원 정비',
  );

  Future<void> render(
    WidgetTester tester,
    WorkPhase phase, {
    HomeDashboard? data,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: TopbarWidget(dashboard: data ?? dashboard, workPhase: phase),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('근무 시작 전에는 배정이 있어도 이름 대신 근무 대기 중 표시', (tester) async {
    await render(tester, WorkPhase.ready);
    expect(find.text('근무 대기 중'), findsOneWidget);
    expect(find.text('STEP2 테스트 공원 정비'), findsNothing);
  });

  testWidgets('근무 중과 휴식 중에는 실제 진행 중인 일자리 표시', (tester) async {
    for (final phase in [WorkPhase.working, WorkPhase.resting]) {
      await render(tester, phase);
      expect(find.text('STEP2 테스트 공원 정비'), findsOneWidget);
      expect(find.text('근무 대기 중'), findsNothing);
    }
  });

  testWidgets('종료 후 상태가 ready이면 캐시된 일자리도 숨김', (tester) async {
    await render(tester, WorkPhase.working);
    await render(tester, WorkPhase.ready);
    expect(find.text('근무 대기 중'), findsOneWidget);
    expect(find.text('STEP2 테스트 공원 정비'), findsNothing);
  });

  testWidgets('서버 진행 일자리가 없다면 다른 배정의 이름을 추측하지 않음', (tester) async {
    await render(
      tester,
      WorkPhase.working,
      data: const HomeDashboard(name: '모바일테스트', hasJob: false),
    );
    expect(find.text('진행 중인 일자리 정보 없음'), findsOneWidget);
    expect(find.text('STEP2 테스트 공원 정비'), findsNothing);
  });
}
