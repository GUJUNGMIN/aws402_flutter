// [인수인계] 근무 상태·대시보드·워치 컨트롤러를 연결한다. 근무 이벤트의 서버 성공 후 화면과 상단바를 동기화한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'dart:async';

import 'package:aws402_flutter/router/app_routes.dart';
import 'package:aws402_flutter/screens/alert_screen.dart';
import 'package:aws402_flutter/service/notification_service.dart';
import 'package:aws402_flutter/widgets/main_widget.dart';
import 'package:aws402_flutter/widgets/person_in_charge_contact.dart';
import 'package:aws402_flutter/widgets/topbar_widget.dart';
import 'package:aws402_flutter/widgets/work_widget.dart';
import 'package:flutter/material.dart';

import '../config/step2_feature_flags.dart';
import '../mobile/mobile_api.dart';
import '../mobile/home_dashboard.dart';
import '../models/work_state.dart';
import '../models/health_measurement.dart';
import '../watch/watch_health_controller.dart';

class HomeScreen extends StatefulWidget {
  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HomeScreen({super.key});
  @override
  /// [인수인계] 이 화면 인스턴스에 대응하는 State 객체를 만든다.
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 구정민 : 수정 - 기존 근무 화면 디자인과 WorkState는 유지하고 서버 측 상태를 연동한다.
  final WorkState _work = WorkState();
  late final WatchHealthController _health;
  bool _changingWork = false;
  bool _signingOut = false;
  HomeDashboard? _dashboard;
  bool _dashboardLoading = true;
  bool _dashboardFailed = false;
  // 구정민 : 수정 - 오래된 홈 API 응답이 근무 전환 후의 정보를 덮어쓰지 않게 한다.
  int _dashboardFetchVersion = 0;

  @override
  /// [인수인계] 화면 최초 생성 시 필요한 구독·조회·타이머를 초기화한다. dispose와 함께 확인한다.
  void initState() {
    super.initState();
    _health = WatchHealthController(
      state: _work,
      onStatusChanged: (sample, grade) {
        if (!mounted) return;
        final type = switch (grade) {
          'NOTICE' => 'notice',
          'WARNING' => 'warning',
          'DANGER' => 'danger',
          'EMERGENCY' => 'emergency',
          _ => 'notice',
        };
        unawaited(_openAlert(type, measurement: sample));
      },
    );
    _health.addListener(_healthChanged);
    _restoreWorkStatus();
    _loadHomeDashboard();
    _initFcm();
  }

  @override
  /// [인수인계] 화면/객체가 사라질 때 등록한 구독·리스너·타이머를 정리한다.
  void dispose() {
    _health.removeListener(_healthChanged);
    _health.dispose();
    super.dispose();
  }

  Future<void> _initFcm() async {
    await NotificationService.initialize();
  }

  // 구정민 : 앱 재실행 시 기존 서버의 근무/휴식 여부를 조회한다. 워치 연결 여부는 새로 확인한다.
  /// [인수인계] 서버에서 근무 단계를 복원하며 워치 실제 연결은 새로 확인한다.
  Future<void> _restoreWorkStatus() async {
    if (!MobileApi.instance.isAuthenticated) return;
    try {
      final status = await MobileApi.instance.workStatus();
      if (!mounted) return;
      setState(() {
        _work.restorePhase(status['phase'].toString());
      });
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  // 구정민 : 수정 - 로그인 직후 또는 세션 복구 시 홈 필드를 모바일 서버에서 별도 조회한다.
  // 구정민 : 실패 시 예전 가짜 정보를 대신 표시하지 않고 재접속 상태를 알려준다.
  /// [인수인계] 홈 정보를 조회한다. 요청 버전을 비교해 근무 전환 전의 늦은 응답을 무시한다.
  Future<void> _loadHomeDashboard() async {
    final version = ++_dashboardFetchVersion;
    if (!MobileApi.instance.isAuthenticated) {
      if (mounted) {
        setState(() {
          _dashboardLoading = false;
        });
      }
      return;
    }
    // 구정민 : 수정 - 시작/종료 직후에는 예전 일자리명을 재사용하지 않고 서버 조회를 기다린다.
    if (mounted) {
      setState(() {
        _dashboardLoading = true;
        _dashboardFailed = false;
      });
    }
    try {
      final dashboard = await MobileApi.instance.homeDashboard();
      if (!mounted || version != _dashboardFetchVersion) return;
      setState(() {
        _dashboard = dashboard;
        _dashboardLoading = false;
        _dashboardFailed = false;
      });
    } catch (error) {
      if (!mounted || version != _dashboardFetchVersion) return;
      setState(() {
        _dashboardLoading = false;
        _dashboardFailed = true;
      });
      _showError(error);
    }
  }

  /// [인수인계] 오류를 공통 API 문구로 변환해 표시한다.
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(MobileApi.errorMessage(error))));
  }

  /// [인수인계] 현재 홈에 짧은 작업 결과 안내를 표시한다.
  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// [인수인계] 공유 건강 상태 변경을 setState로 화면에 반영한다.
  void _healthChanged() {
    if (mounted) setState(() {});
  }

  // 구정민 : 수정 - 워치 연결·최초 서버 건강 측정이 완료된 뒤 서버에서 근무 시작 저장을 확인한다.
  /// [인수인계] 측정/전송 완료와 시작 조건을 검사한 뒤 START 저장 성공에 맞춰 근무 화면·상단바를 갱신한다.
  Future<void> _startWork() async {
    if (_health.busy) {
      _message('건강 측정과 서버 저장이 끝난 뒤 시작해 주세요.');
      return;
    }
    if (!_work.canStartWork) {
      final missing = <String>[
        if (!_work.watchConnected) '워치 연결',
        if (!_work.initialHealthChecked) '최초 건강 측정',
      ];
      final goToCheck = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('업무 시작 전 확인'),
          content: Text(
            '업무를 시작하려면 다음 항목을 완료해 주세요.\n\n'
            '${missing.map((item) => '• $item').join('\n')}\n\n'
            '워치 측정값의 서버 저장과 정상 판정이 필요합니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('확인하러 가기'),
            ),
          ],
        ),
      );
      if (mounted && goToCheck == true) await _openHealthCheck();
      return;
    }
    if (_changingWork || _signingOut) return;
    _changingWork = true;
    try {
      await MobileApi.instance.workEvent('START');
      if (!mounted) return;
      setState(() {
        // 구정민 : 수정 - 저장 응답 사이에 측정 상태가 변해도 서버가 확정한 근무 상태와 일치시킨다.
        _work.restorePhase('WORKING');
      });
      // 구정민 : 수정 - 서버에서 근무 시작을 저장한 뒤 실제 진행 일자리명을 다시 조회한다.
      await _loadHomeDashboard();
      if (!mounted) return;
      _message('근무 시작이 서버 DB에 기록되었습니다.');
    } catch (error) {
      _showError(error);
    } finally {
      _changingWork = false;
    }
  }

  // 구정민 : 수정 - 서버에서 END 저장 성공한 경우에만 근무를 종료한다.
  // 구정민 : 수정 - 종료 후 워치 연결은 유지하고 다음 근무 전 새 측정을 요구한다.
  /// [인수인계] 종료 확인 후 END 저장에 성공해야 화면을 종료하고 다음 근무의 새 측정을 요구한다.
  Future<void> _endWork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('근무 종료'),
        content: const Text('근무 종료를 서버에 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('종료'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _changingWork || _signingOut) return;
    _changingWork = true;
    try {
      await MobileApi.instance.workEvent('END');
      if (!mounted) return;
      setState(() {
        _work.endWork();
      });
      _health.resetForNextWork();
      // 구정민 : 수정 - 근무 종료 즉시 상단바를 대기 상태로 바꾸고 서버 홈 정보를 갱신한다.
      await _loadHomeDashboard();
      if (!mounted) return;
      _message(
        _work.watchConnected
            ? '종료 저장 완료. 워치 연결은 유지되고 다음 근무 전 재측정이 필요합니다.'
            : '종료 저장 완료. 다음 근무 전 워치 재연결과 재측정이 필요합니다.',
      );
    } catch (error) {
      _showError(error);
    } finally {
      _changingWork = false;
    }
  }

  // 구정민 : 수정 - 휴식·재개 역시 WORK_LIST에 먼저 기록한 뒤 화면 상태를 갱신한다.
  /// [인수인계] REST/RESUME을 먼저 서버에 기록한 뒤 화면과 휴식 시각을 변경한다.
  Future<void> _startRest() async {
    if (_changingWork || _signingOut) return;
    _changingWork = true;
    try {
      if (_work.isResting || _work.isStopped) {
        await MobileApi.instance.workEvent('RESUME');
        if (mounted) {
          setState(() {
            _work.resumeWork();
          });
        }
        return;
      }
      if (!_work.isWorking) return;
      await MobileApi.instance.workEvent('REST');
      if (!mounted) return;
      setState(() {
        _work.startRest();
      });
      final resumed = await Navigator.pushNamed<bool>(
        context,
        AppRoutes.rest,
        arguments: _work.restStartedAt!,
      );
      if (!mounted || resumed != true) return;
      await MobileApi.instance.workEvent('RESUME');
      if (mounted) {
        setState(() {
          _work.resumeWork();
        });
      }
    } catch (error) {
      _showError(error);
    } finally {
      _changingWork = false;
    }
  }

  /// [인수인계] 홈과 같은 건강 컨트롤러를 측정 화면에 전달해 상태가 이중 생성되지 않게 한다.
  Future<void> _openHealthCheck() async {
    await Navigator.pushNamed<void>(
      context,
      AppRoutes.healthCheck,
      arguments: _health,
    );
    if (mounted) setState(() {});
  }

  // 구정민 : 이력 화면은 기존 라우트를 유지하되 실제 목록은 서버 DB에서 날짜별 조회한다.
  /// [인수인계] 서버 근무 이력 조회 화면을 연다.
  void _openWorkHistory() {
    Navigator.pushNamed<void>(
      context,
      AppRoutes.workHistory,
      arguments: WorkHistoryRouteArguments(
        entries: List<WorkHistoryEntry>.of(_work.workHistory),
        currentStart: _work.startedAt,
      ),
    );
  }

  /// [인수인계] 서버 상태/건강 이력 조회 화면을 연다.
  void _openHealthHistory() {
    Navigator.pushNamed<void>(
      context,
      AppRoutes.healthHistory,
      arguments: List<HealthHistoryEntry>.of(_work.healthHistory),
    );
  }

  /// 프로필에서 로그아웃을 확인하고 서버 응답 후 로그인 화면으로 이동한다.
  Future<void> _logout() async {
    if (_signingOut || _changingWork) return;
    _signingOut = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('이 기기의 로그인 세션을 종료할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await MobileApi.instance.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signin,
        (_) => false,
      );
    } catch (error) {
      _showError(error);
    } finally {
      _signingOut = false;
    }
  }

  /// 응급 SOS 미연결 상태를 안내한다.
  void _showContactUnavailable(String action) =>
      _message('$action 기능은 아직 연결되지 않았습니다.');

  /// [인수인계] 서버의 상태 변경 판정에 해당하는 알림 화면을 연다.
  Future<void> _openAlert(String type, {HealthMeasurement? measurement}) async {
    // 서버가 응급으로 판정한 측정도 동일한 알림 경로로 표시한다.
    if (!Step2FeatureFlags.showEmergency && type == 'emergency') return;
    // 이전 작업 완료 안내가 경고·긴급 조치 버튼을 가리지 않도록 정리한다.
    ScaffoldMessenger.of(context).clearSnackBars();
    final result = await Navigator.pushNamed<String>(
      context,
      AppRoutes.alert,
      arguments: AlertRouteArguments(
        type: type,
        measurement: measurement?.toJson(),
      ),
    );
    if (!mounted) return;
    // 휴식은 근무 상태를 관리하는 홈에서 처리한다.
    switch (result) {
      case 'rest':
        if (_work.isWorking) await _startRest();
        break;
      case 'sos':
        _showContactUnavailable('SOS');
        break;
      default:
        break;
    }
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: TopbarWidget(
          onProfilePressed: _logout,
          dashboard: _dashboard,
          loading: _dashboardLoading,
          failed: _dashboardFailed,
          workPhase: _work.phase,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _work.phase == WorkPhase.ready
              ? MainWidget(
                  onButtonPressed: _startWork,
                  onHealthCheckPressed: _openHealthCheck,
                  onContactPressed: () => showPersonInChargeContact(context),
                  onWorkHistoryPressed: _openWorkHistory,
                  onHealthHistoryPressed: _openHealthHistory,
                  healthCheckCompleted: _work.initialHealthChecked,
                  // 구정민 : 수정 - 근무 시작 전에도 서버 저장 확인된 건강 결과를 전달한다.
                  measurementSaved: _work.hasSavedMeasurement,
                  latestBpm: _work.latestBpm,
                  latestTemperature: _work.latestTemperature,
                  latestSpo2: _work.latestSpo2,
                  latestGrade: _work.latestGrade,
                  watchConnected: _work.watchConnected,
                  weather: _dashboard?.weather,
                  weatherLoading: _dashboardLoading,
                  weatherFailed: _dashboardFailed,
                )
              : WorkWidget(
                  workStartedAt: _work.startedAt,
                  restStartedAt: _work.restStartedAt,
                  isResting: _work.isResting,
                  isStopped: _work.isStopped,
                  watchConnected: _work.watchConnected,
                  onWatchStatusPressed: _openHealthCheck,
                  onButtonPressed: _endWork,
                  onRestPressed: _startRest,
                  onHistoryPressed: _openWorkHistory,
                  onHealthHistoryPressed: _openHealthHistory,
                  onContactPressed: () => showPersonInChargeContact(context),
                  weather: _dashboard?.weather,
                  weatherLoading: _dashboardLoading,
                  weatherFailed: _dashboardFailed,
                  latestBpm: _work.latestBpm,
                  latestTemperature: _work.latestTemperature,
                  latestSpo2: _work.latestSpo2,
                  latestFall: _work.latestFall,
                  latestGrade: _work.latestGrade,
                  serverMessage: _work.serverMessage,
                ),
        ),
      ),
    );
  }
}
