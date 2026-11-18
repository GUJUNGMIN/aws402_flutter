import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aws402_flutter/main.dart';
import 'package:aws402_flutter/router/app_routes.dart';

void main() {
  // 구정민 : 수정 - 기본 카운터 테스트를 현재 로그인 UI 입력 검증 테스트로 교체했다.
  testWidgets('로그인 화면에서 빈 계정은 홈으로 이동하지 않는다', (tester) async {
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.signin));
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('아이디와 비밀번호를 입력해 주세요.'), findsOneWidget);
  });
}
