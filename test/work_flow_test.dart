import 'package:flutter_test/flutter_test.dart';
import 'package:aws402_flutter/models/work_state.dart';

void main() {
  test('근무 시작 → 휴식 → 재개 → 종료의 임시 이력을 기록한다', () {
    final state = WorkState();
    final start = DateTime(2026, 11, 18, 9);
    state.connectWatchForDemo();
    state.checkHealthForDemo();
    expect(state.startWork(now: start), isTrue);
    expect(state.startRest(now: start.add(const Duration(minutes: 30))), isTrue);
    expect(state.resumeWork(now: start.add(const Duration(minutes: 40))), isTrue);
    expect(state.endWork(now: start.add(const Duration(hours: 2))), isTrue);
    expect(state.workHistory, hasLength(1));
    expect(state.workHistory.first.restDuration, const Duration(minutes: 10));
    expect(state.workHistory.first.workingDuration, const Duration(minutes: 110));
    expect(state.phase, WorkPhase.ready);
    expect(state.initialHealthChecked, isFalse);
  });

  test('워치 연결·최초 건강 측정이 완료되어야 근무 시작 가능하다', () {
    // 구정민 : 위치 확인 없이도 워치·건강 측정만 완료하면 근무를 시작할 수 있다.
    final state = WorkState();
    expect(state.startWork(), isFalse);
    state.connectWatchForDemo();
    expect(state.startWork(), isFalse);
    state.checkHealthForDemo();
    expect(state.startWork(), isTrue);
    state.disconnectWatchForDemo();
    expect(state.watchConnected, isFalse);
    expect(state.initialHealthChecked, isFalse);
  });

  test('근무 종료 후 워치는 유지하고 다음 근무 전 건강 측정은 다시 한다', () {
    final state = WorkState();
    state.connectWatchForDemo();
    expect(state.checkHealthForDemo(), isTrue);
    expect(state.startWork(), isTrue);
    expect(state.endWork(), isTrue);
    // 구정민 : 종료 후 워치 연결은 유지되지만 재측정 전에는 새 근무를 시작할 수 없다.
    expect(state.watchConnected, isTrue);
    expect(state.initialHealthChecked, isFalse);
    expect(state.canStartWork, isFalse);
    expect(state.checkHealthForDemo(), isTrue);
    expect(state.startWork(), isTrue);
  });

  test('워치 연결이 끊겼으면 재연결·건강 재측정 후 다음 근무를 시작한다', () {
    final state = WorkState();
    state.connectWatchForDemo();
    state.checkHealthForDemo();
    expect(state.startWork(), isTrue);
    state.disconnectWatchForDemo();
    expect(state.endWork(), isTrue);
    expect(state.canStartWork, isFalse);
    state.connectWatchForDemo();
    expect(state.canStartWork, isFalse);
    state.checkHealthForDemo();
    expect(state.startWork(), isTrue);
  });

  test('위험 이벤트와 확인 상태를 앱 메모리에 보관한다', () {
    final state = WorkState();
    final event = state.addHealthEvent('위험');
    event.action = '테스트 알림 확인';
    expect(state.healthHistory.first.grade, '위험');
    expect(state.healthHistory.first.action, '테스트 알림 확인');
  });

  test('워치 테스트는 연결 후에만 측정할 수 있다', () {
    final state = WorkState();
    expect(state.checkHealthForDemo(), isFalse);
    state.connectWatchForDemo();
    expect(state.checkHealthForDemo(), isTrue);
    expect(state.initialHealthChecked, isTrue);
  });
}
