import 'package:aws402_flutter/screens/signin_screen.dart';
import 'package:flutter/material.dart';

import '../models/work_state.dart';
import '../screens/alert_screen.dart';
import '../screens/health_check_screen.dart';
import '../screens/health_history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/rest_screen.dart';
import '../screens/work_history_screen.dart';

// 구정민 : HomeScreen에서 근무 이력 화면을 열 때 완료 기록과 진행 중인 근무를 함께 전달한다.
class WorkHistoryRouteArguments {
  final List<WorkHistoryEntry> entries;
  final DateTime? currentStart;

  const WorkHistoryRouteArguments({
    required this.entries,
    this.currentStart,
  });
}

class AppRoutes {
  const AppRoutes._();

  static const String home = '/home';
  static const String signin = '/signin';
  static const String rest = '/rest';
  static const String healthCheck = '/health-check';
  static const String workHistory = '/work-history';
  static const String healthHistory = '/health-history';
  static const String alert = '/alert';

  // 구정민 : 수정 - 인수가 필요 없는 시작 화면만 기존 routes에 남긴다.
  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    signin: (context) => const SigninScreen(),
  };

  // 구정민 : 수정 - Navigator.pushNamed()의 인수를 RouteSettings에서 직접 검증한다.
  // HomeScreen의 휴식·상태 버튼이 호출하며, 결과 타입별 화면을 생성한다.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case rest:
        final startedAt = _argument<DateTime>(settings);
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => RestScreen(startedAt: startedAt),
        );
      case healthCheck:
        final state = _argument<WorkState>(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => HealthCheckScreen(workState: state),
        );
      case workHistory:
        final args = _argument<WorkHistoryRouteArguments>(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => WorkHistoryScreen(
            entries: args.entries,
            currentStart: args.currentStart,
          ),
        );
      case healthHistory:
        final entries = _argument<List<HealthHistoryEntry>>(settings);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => HealthHistoryScreen(entries: entries),
        );
      case alert:
        final type = _argument<String>(settings);
        return MaterialPageRoute<String>(
          settings: settings,
          builder: (_) => AlertScreen(type: type),
        );
      default:
        return null;
    }
  }

  // 구정민 : 경로별 필수 전달값이 누락되면 오류 발생 위치를 명확히 표시한다.
  static T _argument<T>(RouteSettings settings) {
    final value = settings.arguments;
    if (value is T) return value;
    throw ArgumentError('Route ${settings.name} requires arguments of type $T.');
  }
}
