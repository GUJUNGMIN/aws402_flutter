// [인수인계] 앱 시작 시 세션을 확인하고 첫 화면을 선택한다. 첫 프레임 후 위치 권한을 확인하며 워치 어댑터는 runApp 전에 등록한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:aws402_flutter/router/app_routes.dart';
import 'package:flutter/material.dart';

import 'mobile/mobile_api.dart';
import 'mobile/location_permission_service.dart';

import 'l10n/app_localizations.dart';

/// [인수인계] 초기화와 세션 확인을 마친 뒤 시작 화면으로 앱을 실행한다. 워치 어댑터는 runApp 이전에 등록한다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 앱 로딩중에 불러올 작업 작성
  String startRoute = await authenticationUser();
  // await Future.delayed(const Duration(seconds: 3)); //임의로 3초 딜레이, 실 사용시에는 삭제
  // 구정민 : 수정 - 워치 담당자는 runApp 전에 WatchClient.instance에 실제 WatchBridgeClient를 등록한다.
  // 구정민 : 수정 - 기본 연결 모듈은 미설정 상태이며 가상 연결·측정값을 생성하지 않는다.
  runApp(MyApp(initialRoute: startRoute));
}

String initRoute = AppRoutes.home;

// 구정민 : 수정 - 기존 단순 SharedPreferences 키 존재 검사 대신 실제 서버 세션 유효성을 확인한다.
/// [인수인계] 저장 토큰을 서버로 확인해 홈 또는 로그인 시작 경로를 결정한다.
Future<String> authenticationUser() async {
  final restored = await MobileApi.instance.restoreSession();
  return restored ? AppRoutes.home : AppRoutes.signin;
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const MyApp({super.key, required this.initialRoute});

  @override
  /// [인수인계] 이 화면 인스턴스에 대응하는 State 객체를 만든다.
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  /// [인수인계] 화면 최초 생성 시 필요한 구독·조회·타이머를 초기화한다. dispose와 함께 확인한다.
  void initState() {
    super.initState();
    // 구정민 : 수정 - 첫 화면 표시 후 위치 권한을 한 번 확인하며 화면 재빌드로 재요청하지 않는다.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await LocationPermissionService.requestOnAppStart();
    });
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return MaterialApp(
      title: '헬스가드',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.blue)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      //  AppRoutes 클래스를 가져와서 라우팅 정보 설정
      initialRoute: widget.initialRoute,
      routes: AppRoutes.routes,
      // 구정민 : 수정 - 휴식·위험 등 인수가 필요한 화면은 AppRoutes에서 직접 생성한다.
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
