// 구정민 : HomeScreen에서 사용하는 임시 근무 상태 모델이며, 서버 연동 전 화면 흐름과 이력만 관리한다.
enum WorkPhase { ready, working, resting }

class WorkHistoryEntry {
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration restDuration;

  const WorkHistoryEntry({
    required this.startedAt,
    required this.endedAt,
    required this.restDuration,
  });

  Duration get workingDuration {
    final duration = endedAt.difference(startedAt) - restDuration;
    return duration.isNegative ? Duration.zero : duration;
  }
}

class HealthHistoryEntry {
  final DateTime occurredAt;
  final String grade;
  final String reason;
  String action;

  HealthHistoryEntry({
    required this.occurredAt,
    required this.grade,
    required this.reason,
    this.action = '확인 전',
  });
}

class WorkState {
  WorkPhase phase = WorkPhase.ready;
  bool watchConnected = false;
  bool initialHealthChecked = false;
  // 구정민 : 수정 - 근무 시작은 워치 연결과 이번 근무의 건강 측정 완료 시에만 허용한다.
  bool get canStartWork => phase == WorkPhase.ready &&
      watchConnected && initialHealthChecked;

  DateTime? startedAt;
  DateTime? restStartedAt;
  Duration _totalRest = Duration.zero;

  final List<WorkHistoryEntry> workHistory = [];
  final List<HealthHistoryEntry> healthHistory = [];

  bool get isWorking => phase == WorkPhase.working;
  bool get isResting => phase == WorkPhase.resting;

  void connectWatchForDemo() {
    watchConnected = true;
    initialHealthChecked = false;
  }

  // 구정민 : 최초 측정 화면에서 워치 연결 해제 상황을 테스트하며 측정 완료도 초기화한다.
  void disconnectWatchForDemo() {
    watchConnected = false;
    initialHealthChecked = false;
  }

  bool checkHealthForDemo() {
    if (!watchConnected) return false;
    initialHealthChecked = true;
    return true;
  }

  // 구정민 : HomeScreen의 근무 시작 버튼에서 호출하며, DB 없이 근무 시작 시각만 기록한다.
  bool startWork({DateTime? now}) {
    // 구정민 : 수정 - 화면을 우회해도 워치 연결·건강 측정 전에는 근무를 시작하지 않는다.
    if (!canStartWork) return false;
    startedAt = now ?? DateTime.now();
    restStartedAt = null;
    _totalRest = Duration.zero;
    phase = WorkPhase.working;
    return true;
  }

  // 구정민 : HomeScreen._startRest()가 호출하며 현재 근무를 휴식 상태로 변경한다.
  bool startRest({DateTime? now}) {
    if (phase != WorkPhase.working) return false;
    restStartedAt = now ?? DateTime.now();
    phase = WorkPhase.resting;
    return true;
  }

  // 구정민 : 휴식 화면 복귀 시 호출되어 휴식시간을 합산하고 근무 상태로 돌아간다.
  bool resumeWork({DateTime? now}) {
    if (phase != WorkPhase.resting || restStartedAt == null) return false;
    final duration = (now ?? DateTime.now()).difference(restStartedAt!);
    if (!duration.isNegative) _totalRest += duration;
    restStartedAt = null;
    phase = WorkPhase.working;
    return true;
  }

  // 구정민 : HomeScreen의 종료 확인 후 호출되며, 계산된 근무 기록은 WorkHistoryScreen에서 사용된다.
  bool endWork({DateTime? now}) {
    if (phase == WorkPhase.ready || startedAt == null) return false;
    final endedAt = now ?? DateTime.now();
    if (phase == WorkPhase.resting && restStartedAt != null) {
      final lastRest = endedAt.difference(restStartedAt!);
      if (!lastRest.isNegative) _totalRest += lastRest;
    }
    workHistory.insert(0, WorkHistoryEntry(
      startedAt: startedAt!,
      endedAt: endedAt,
      restDuration: _totalRest,
    ));
    phase = WorkPhase.ready;
    startedAt = null;
    restStartedAt = null;
    _totalRest = Duration.zero;
    // 구정민 : 수정 - 종료 시 워치 연결은 유지하고 건강 측정 완료만 초기화해 다음 근무 전 재측정하도록 한다.
    initialHealthChecked = false;
    return true;
  }

  // 구정민 : 주의·경고·위험 테스트 버튼을 누를 때 호출되며, HealthHistoryScreen에 표시된다.
  HealthHistoryEntry addHealthEvent(String grade, {DateTime? now}) {
    final entry = HealthHistoryEntry(
      occurredAt: now ?? DateTime.now(),
      grade: grade,
      reason: '화면 테스트 (실제 측정값 아님)',
    );
    healthHistory.insert(0, entry);
    return entry;
  }
}
