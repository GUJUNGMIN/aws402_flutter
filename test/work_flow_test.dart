import 'package:flutter_test/flutter_test.dart';
import 'package:aws402_flutter/models/work_state.dart';

void saveNormal(WorkState state) =>
    state.applyServerMeasurement(85, 36.5, 98, false, 'NORMAL');

void main() {
  test('웹 근무 코드 복원과 중지 시간은 휴식 시간과 구분한다', () {
    for (final entry in <String, WorkPhase>{
      '8001': WorkPhase.ready,
      '8002': WorkPhase.working,
      '8003': WorkPhase.resting,
      '8004': WorkPhase.working,
      '8005': WorkPhase.ready,
      '8006': WorkPhase.stopped,
    }.entries) {
      expect((WorkState()..restorePhase(entry.key)).phase, entry.value);
    }
    final start = DateTime(2026, 11, 26, 9);
    final state = WorkState()..restorePhase('8006');
    state.startedAt = start;
    state.restStartedAt = start.add(const Duration(minutes: 30));
    expect(state.resumeWork(now: start.add(const Duration(minutes: 45))), true);
    expect(state.endWork(now: start.add(const Duration(hours: 1))), true);
    expect(
      state.workHistory.single.stoppedDuration,
      const Duration(minutes: 15),
    );
    expect(state.workHistory.single.restDuration, Duration.zero);
    expect(
      state.workHistory.single.workingDuration,
      const Duration(minutes: 45),
    );
  });

  test('근무 시작 → 휴식 → 재개 → 종료 이력을 기록한다', () {
    final state = WorkState();
    final start = DateTime(2026, 11, 23, 9);
    state.updateWatchConnection(true);
    saveNormal(state);
    expect(state.startWork(now: start), true);
    expect(state.startRest(now: start.add(const Duration(minutes: 30))), true);
    expect(state.resumeWork(now: start.add(const Duration(minutes: 40))), true);
    expect(state.endWork(now: start.add(const Duration(hours: 2))), true);
    expect(state.workHistory.single.restDuration, const Duration(minutes: 10));
    expect(
      state.workHistory.single.workingDuration,
      const Duration(minutes: 110),
    );
    expect(state.phase, WorkPhase.ready);
    expect(state.initialHealthChecked, false);
    expect(state.latestBpm, isNull);
  });
  test('실제 연결과 서버 정상 판정이 모두 있어야 시작한다', () {
    final state = WorkState();
    expect(state.startWork(), false);
    state.updateWatchConnection(true);
    expect(state.startWork(), false);
    state.applyServerMeasurement(95, 37.5, 95, false, 'NOTICE');
    expect(state.startWork(), false);
    saveNormal(state);
    expect(state.startWork(), true);
    state.updateWatchConnection(false);
    expect(state.initialHealthChecked, false);
    expect(state.hasSavedMeasurement, false);
  });
  test('근무 종료 후 워치는 유지하고 새 저장 정상 판정이 필요하다', () {
    final state = WorkState()..updateWatchConnection(true);
    saveNormal(state);
    expect(state.startWork(), true);
    expect(state.endWork(), true);
    expect(state.watchConnected, true);
    expect(state.canStartWork, false);
    saveNormal(state);
    expect(state.startWork(), true);
  });
  test('연결 해제 후 재연결만으로 측정 완료가 복구되지 않는다', () {
    final state = WorkState()..updateWatchConnection(true);
    saveNormal(state);
    state.updateWatchConnection(false);
    state.updateWatchConnection(true);
    expect(state.canStartWork, false);
    expect(state.latestBpm, isNull);
    saveNormal(state);
    expect(state.canStartWork, true);
  });
  test('서버 이력 화면용 기록의 확인 상태를 유지한다', () {
    final state = WorkState();
    final event = HealthHistoryEntry(
      occurredAt: DateTime.now(),
      grade: 'WARNING',
      reason: '서버 판정',
    );
    state.healthHistory.add(event);
    event.action = '확인';
    expect(state.healthHistory.single.action, '확인');
  });
  test('연결되지 않은 상태의 정상값으로 시작할 수 없다', () {
    final state = WorkState();
    saveNormal(state);
    expect(state.initialHealthChecked, false);
    expect(state.canStartWork, false);
  });
}
