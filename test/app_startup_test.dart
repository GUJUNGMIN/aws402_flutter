import 'package:geolocator/geolocator.dart';
import 'package:aws402_flutter/watch/watch_client.dart';

import 'mobile_api_stub.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aws402_flutter/main.dart';
import 'package:aws402_flutter/router/app_routes.dart';

void main() {
  late GeolocatorPlatform originalLocation;
  late _StartupLocation location;
  setUp(() {
    originalLocation = GeolocatorPlatform.instance;
    location = _StartupLocation();
    GeolocatorPlatform.instance = location;
  });
  tearDown(() {
    GeolocatorPlatform.instance = originalLocation;
  });

  // 구정민 : 수정 - 기본 카운터 테스트를 현재 로그인 UI 입력 검증 테스트로 교체했다.
  testWidgets('로그인 화면에서 빈 계정은 홈으로 이동하지 않는다', (tester) async {
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.signin));
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('아이디와 비밀번호를 입력해 주세요.'), findsOneWidget);
  });
  for (final permission in [
    LocationPermission.denied,
    LocationPermission.whileInUse,
    LocationPermission.always,
    LocationPermission.deniedForever,
  ]) {
    testWidgets('앱 시작 위치 권한 확인: $permission', (tester) async {
      location.permission = permission;
      await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.signin));
      await settleMobileApi(tester);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(
        location.requests,
        permission == LocationPermission.denied ? 1 : 0,
      );
      await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.signin));
      await settleMobileApi(tester);
      expect(
        location.requests,
        permission == LocationPermission.denied ? 1 : 0,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('앱 시작 권한 확인 실패에도 로그인 화면을 표시한다', (tester) async {
    location.failCheck = true;
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.signin));
    await settleMobileApi(tester);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(location.requests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('앱 시작 위치 권한 거부 후에도 건강 저장과 근무 시작이 가능하다', (tester) async {
    configureMobileApiStub();
    location.requestResult = LocationPermission.denied;
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.home));
    await settleMobileApi(tester);
    expect(location.requests, 1);
    await tester.tap(find.text('워치 연결·건강 측정'));
    await settleMobileApi(tester);
    await tapMobileButton(tester, '워치 연결');
    await tapMobileButton(tester, '건강 측정');
    await tapMobileButton(tester, '메인으로 돌아가기');
    expect(find.text('85 bpm'), findsOneWidget);
    expect(find.text('NORMAL'), findsNWidgets(3));
    await tester.tap(find.text('업무 시작하기'));
    await settleMobileApi(tester);
    expect(find.text('근무 중'), findsOneWidget);
    expect(location.requests, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('워치 모듈 미설정 시 가짜 연결/측정과 전송을 하지 않는다', (tester) async {
    final requests = <Map<String, dynamic>>[];
    configureMobileApiStub(requests: requests);
    WatchClient.instance = UnavailableWatchClient();
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.home));
    await settleMobileApi(tester);
    await tester.tap(find.text('워치 연결·건강 측정'));
    await settleMobileApi(tester);
    await tapMobileButton(tester, '워치 연결');
    expect(find.textContaining('연결 모듈이 아직 연결되지'), findsOneWidget);
    expect(find.text('연결 전'), findsOneWidget);
    final measure = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '건강 측정'),
    );
    expect(measure.onPressed, isNull);
    expect(
      requests.where((r) => r['path'] == '/api/mobile/measurements'),
      isEmpty,
    );
  });
}

// 구정민 : 수정 - 실제 OS 권한창 대신 권한 상태·사용자 응답·요청 횟수를 검증한다.
class _StartupLocation extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requestResult = LocationPermission.whileInUse;
  int requests = 0;
  bool failCheck = false;

  @override
  Future<LocationPermission> checkPermission() async {
    if (failCheck) throw StateError('권한 확인 실패');
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    permission = requestResult;
    return permission;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;
}
