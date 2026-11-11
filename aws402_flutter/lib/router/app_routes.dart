import 'package:flutter/material.dart';

import '../screens/home_screen.dart';

class AppRoutes {

  const AppRoutes._();
  static const String home = '/';


  //  main.dart 파일에서 참조하는 라우팅 정보
  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(title: '노인 일자리'),

  };
}

