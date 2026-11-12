import 'package:aws402_flutter/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';


void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // 앱 로딩중에 불러올 작업 작성
  String startRoute = await authenticationUser();
  await Future.delayed(const Duration(seconds: 3)); //임의로 3초 딜레이, 실 사용시에는 삭제
  FlutterNativeSplash.remove();
  runApp(MyApp(initialRoute: startRoute));
}

String initRoute = AppRoutes.home;

Future<String> authenticationUser () async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? userid = prefs.getString("userid");
  if(userid != null){
  //   서버통신으로 로그인
    return AppRoutes.home;
  }else{
    return AppRoutes.signin;
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      //  AppRoutes 클래스를 가져와서 라우팅 정보 설정
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}