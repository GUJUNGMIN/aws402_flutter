import 'package:aws402_flutter/router/app_routes.dart';
import 'package:aws402_flutter/widgets/main_widget.dart';
import 'package:aws402_flutter/widgets/topbar_widget.dart';
import 'package:aws402_flutter/widgets/work_widget.dart';
import 'package:flutter/material.dart';

import '../models/work_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 구정민 : 수정 - 기존 _isWork 단일 플래그 대신 근무·휴식·이력을 WorkState로 관리한다.
  final WorkState _work = WorkState();

  // 구정민 : 수정 - MainWidget의 시작 버튼에서 호출되며 워치·건강 측정 미완료 시 안내창을 표시한다.
  Future<void> _startWork() async {
    if (_work.canStartWork) {
      setState(() { _work.startWork(); });
      return;
    }

    final missing = <String>[
      if (!_work.watchConnected) '워치 연결',
      if (!_work.initialHealthChecked) '최초 건강 측정',
    ];
    final goToCheck = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('업무 시작 전 확인'),
        content: Text('업무를 시작하려면 다음 항목을 완료해 주세요.\n\n'
            '${missing.map((item) => '• $item').join('\n')}\n\n'
            '현재는 화면 테스트이며 실제 워치·건강 측정은 하지 않습니다.'),
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
    if (!mounted) return;
    if (goToCheck == true) await _openHealthCheck();
  }

  // 구정민 : 수정 - WorkWidget 종료 버튼에서 확인 후 WorkState에 임시 근무 이력을 남긴다.
  Future<void> _endWork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('근무 종료'),
        content: const Text('근무를 종료하시겠습니까?\n현재 기록은 앱 실행 중에만 저장됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('종료')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    // 구정민 : 수정 - 근무 종료 후 워치 연결은 유지하고, 다음 근무를 위한 건강 측정은 새로 받는다.
    setState(() { _work.endWork(); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_work.watchConnected
          ? '근무가 종료되었습니다. 워치 연결은 유지되며 다음 근무 전 건강 측정이 필요합니다.'
          : '근무가 종료되었습니다. 다음 근무 전 워치 재연결과 건강 측정이 필요합니다.'),
    ));
  }

  // 구정민 : 수정 - WorkWidget 휴식 버튼에서 AppRoutes.rest를 열고 복귀 시 근무를 재개한다.
  Future<void> _startRest() async {
    // 구정민 : 수정 - 휴식 화면을 뒤로 닫으면 휴식 상태를 유지하고, 근무 재개 시에만 복귀한다.
    if (_work.isResting) {
      setState(() { _work.resumeWork(); });
      return;
    }
    if (!_work.startRest()) return;
    final started = _work.restStartedAt!;
    setState(() {});
    final resumed = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.rest,
      arguments: started,
    );
    if (!mounted) return;
    if (resumed == true) {
      setState(() { _work.resumeWork(); });
    }
  }

  // 구정민 : 수정 - MainWidget의 워치 버튼에서 AppRoutes.healthCheck로 가상 측정 화면을 연다.
  Future<void> _openHealthCheck() async {
    await Navigator.pushNamed<void>(
      context,
      AppRoutes.healthCheck,
      arguments: _work,
    );
    if (mounted) setState(() {});
  }

  // 구정민 : 수정 - WorkWidget/MainWidget의 이력 버튼에서 AppRoutes.workHistory를 호출한다.
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

  // 구정민 : 수정 - 건강 상태 이력 목록을 AppRoutes.healthHistory로 전달해 표시한다.
  void _openHealthHistory() {
    Navigator.pushNamed<void>(
      context,
      AppRoutes.healthHistory,
      arguments: List<HealthHistoryEntry>.of(_work.healthHistory),
    );
  }

  void _showDemoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message (화면 테스트: 실제 전송되지 않음)')),
    );
  }

  // 구정민 : 수정 - WorkWidget의 상태 테스트 버튼에서 호출하며 AlertScreen 조치 결과를 이력에 남긴다.
  Future<void> _testAlert(String type) async {
    const labels = {
      'notice': '주의',
      'warning': '경고',
      'danger': '위험',
      'emergency': '응급',
    };
    final event = _work.addHealthEvent(labels[type] ?? '주의');
    // 구정민 : 수정 - 상태 테스트 등급을 AppRoutes.alert에 전달하고 조치 결과를 되돌려 받는다.
    final result = await Navigator.pushNamed<String>(
      context,
      AppRoutes.alert,
      arguments: type,
    );
    if (!mounted) return;

    // 구정민 : 수정 - 알림/119/SOS 버튼은 실제 통신 없이 테스트 결과만 기록한다.
    switch (result) {
      case 'rest':
        event.action = '휴식 시작 (테스트)';
        await _startRest();
        return;
      case 'notify':
        event.action = '담당자 알림 버튼 확인 (미전송)';
        _showDemoMessage('담당자 알림');
        break;
      case 'sos':
        event.action = 'SOS 버튼 확인 (미전송)';
        _showDemoMessage('SOS');
        break;
      case 'call119':
        event.action = '119 신고 버튼 확인 (미연결)';
        _showDemoMessage('119 신고');
        break;
      case 'ack':
        event.action = '사용자 확인 (위험 해제 아님)';
        break;
      default:
        event.action = '화면 닫기';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: TopbarWidget(),
      ),
      // 구정민 : 수정 - 하단 시스템 내비게이션 영역을 피하면서 근무 화면 전체 높이를 확보한다.
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          // 구정민 : 수정 - 기존 대기 화면과 근무 화면을 유지하며 추가한 상태·레이아웃을 연결한다.
          child: _work.phase == WorkPhase.ready
              ? MainWidget(
                  onButtonPressed: _startWork,
                  onHealthCheckPressed: _openHealthCheck,
                  onWorkHistoryPressed: _openWorkHistory,
                  onHealthHistoryPressed: _openHealthHistory,
                  healthCheckCompleted: _work.initialHealthChecked,
                  watchConnected: _work.watchConnected,
                )
              : WorkWidget(
                  workStartedAt: _work.startedAt,
                  restStartedAt: _work.restStartedAt,
                  isResting: _work.isResting,
                  watchConnected: _work.watchConnected,
                  onWatchStatusPressed: _openHealthCheck,
                  onButtonPressed: _endWork,
                  onRestPressed: _startRest,
                  onHistoryPressed: _openWorkHistory,
                  onHealthHistoryPressed: _openHealthHistory,
                  onContactPressed: () => _showDemoMessage('담당자 연결'),
                  showAlert: _testAlert,
                ),
        ),
      ),
    );
  }
}
