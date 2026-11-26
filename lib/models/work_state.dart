// [인수인계] 앱의 근무 단계와 서버 저장 확인된 측정값을 보관한다. 화면 메모리 상태와 DB 영구 기록은 구분한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

// 구정민 : 수정 - 서버 저장이 확인된 측정 결과와 근무 화면 상태를 관리한다.
import '../mobile/health_status.dart';

enum WorkPhase { ready, working, resting, stopped }

class WorkHistoryEntry {
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration restDuration;
  final Duration stoppedDuration;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const WorkHistoryEntry({
    required this.startedAt,
    required this.endedAt,
    required this.restDuration,
    this.stoppedDuration = Duration.zero,
  });

  /// [인수인계] 화면용 근무 구간에서 휴식을 빼고 음수 결과는 0으로 제한한다.
  Duration get workingDuration {
    final duration =
        endedAt.difference(startedAt) - restDuration - stoppedDuration;
    return duration.isNegative ? Duration.zero : duration;
  }
}

class HealthHistoryEntry {
  final DateTime occurredAt;
  final String grade;
  final String reason;
  String action;

  /// [인수인계] 필요한 의존성/콜백/초기값으로 HealthHistoryEntry 객체를 구성한다.
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
  // 구정민 : 수정 - 서버 저장 확인 여부는 근무 시작 조건과 별도로 관리한다.
  bool hasSavedMeasurement = false;
  // 구정민 : 서버가 응답한 건강 판정만 화면에 반영한다. 통신 실패 시 이전 경고 상태를 임의로 해제하지 않는다.
  int? latestBpm;
  double? latestTemperature;
  int? latestSpo2;
  bool latestFall = false;
  String latestGrade = 'NORMAL';
  bool serverConnected = false;
  String serverMessage = '서버 응답 대기';
  // 구정민 : 수정 - 근무 시작은 워치 연결과 이번 근무의 건강 측정 완료 시에만 허용한다.
  /// [인수인계] 대기 상태·워치 실제 연결·서버 NORMAL 최초 측정 조건이 모두 충족됐는지 반환한다.
  bool get canStartWork =>
      phase == WorkPhase.ready && watchConnected && initialHealthChecked;

  DateTime? startedAt;
  DateTime? restStartedAt;
  Duration _totalRest = Duration.zero;
  Duration _totalStopped = Duration.zero;

  final List<WorkHistoryEntry> workHistory = [];
  final List<HealthHistoryEntry> healthHistory = [];

  bool get isWorking => phase == WorkPhase.working;
  bool get isResting => phase == WorkPhase.resting;
  bool get isStopped => phase == WorkPhase.stopped;

  // 구정민 : 서버 저장 성공 후 호출되는 화면 동기화 함수. 건강 등급은 서버 응답만 사용한다.
  /// [인수인계] 검증된 저장 응답 수치와 등급을 반영한다. 연결 중 NORMAL일 때만 최초 측정 시작 조건을 만족시킨다.
  void applyServerMeasurement(
    int bpm,
    double temperature,
    int spo2,
    bool fallDetected,
    String grade,
  ) {
    // 저장 성공과 업무 시작 허용은 다르다. 비정상 판정도 표시하되 시작 조건은 충족시키지 않는다.
    grade = HealthStatus.normalize(grade);
    initialHealthChecked = watchConnected && grade == 'NORMAL';
    hasSavedMeasurement = true;
    latestBpm = bpm;
    latestTemperature = temperature;
    latestSpo2 = spo2;
    latestFall = fallDetected;
    latestGrade = grade;
    serverConnected = true;
    serverMessage = '서버 저장 완료 · $grade';
  }

  /// [인수인계] 통신 실패를 표시하되 이미 저장 확인된 이전 수치/판정을 정상으로 덮어쓰지 않는다.
  void markServerFailure() {
    serverConnected = false;
    serverMessage = '서버 통신 실패 · 다음 신규 측정 대기';
  }

  // 구정민 : 앱 재실행 시 서버에서 가져온 근무 상태를 복원한다. 워치 연결은 복원하지 않는다.
  /// [인수인계] 서버의 근무 단계만 복원한다. 앱의 경과 시간은 화면용이며 서버 이력과 별개다.
  void restorePhase(String serverPhase) {
    phase = switch (serverPhase) {
      'WORKING' || '8002' || '8004' || 'WS' || 'RR' => WorkPhase.working,
      'RESTING' || '8003' || 'RS' => WorkPhase.resting,
      'STOPPED' || '8006' => WorkPhase.stopped,
      _ => WorkPhase.ready,
    };
    if (phase != WorkPhase.ready) startedAt ??= DateTime.now();
    if (phase == WorkPhase.resting || phase == WorkPhase.stopped) {
      restStartedAt ??= DateTime.now();
    }
  }

  // 구정민 : 수정 - 실제 어댑터 연결 이벤트로만 연결 상태를 변경한다.
  /// [인수인계] 실제 연결 이벤트를 반영하고 해제되면 최초 측정 결과를 초기화한다.
  void updateWatchConnection(bool connected) {
    watchConnected = connected;
    if (!connected) resetInitialMeasurement();
  }

  /// [인수인계] 서버의 기존 HEALTH 기록은 지우지 않고 앱의 이번 측정 표시/시작 허용만 초기화한다.
  void resetInitialMeasurement() {
    initialHealthChecked = false;
    hasSavedMeasurement = false;
    latestBpm = null;
    latestTemperature = null;
    latestSpo2 = null;
    latestFall = false;
    latestGrade = 'NORMAL';
    serverConnected = false;
    serverMessage = '새 건강 측정 대기';
  }

  // 구정민 : 서버 근무 저장과 별도로 화면의 시작 조건·시각을 관리한다.
  /// [인수인계] 화면 상태에서 연결·정상 최초 측정 조건을 검사한다. WORK_LIST 저장은 호출부 API에서 별도로 수행한다.
  bool startWork({DateTime? now}) {
    // 구정민 : 수정 - 화면을 우회해도 워치 연결·건강 측정 전에는 근무를 시작하지 않는다.
    if (!canStartWork) return false;
    startedAt = now ?? DateTime.now();
    restStartedAt = null;
    _totalRest = Duration.zero;
    _totalStopped = Duration.zero;
    phase = WorkPhase.working;
    return true;
  }

  // 구정민 : HomeScreen._startRest()가 호출하며 현재 근무를 휴식 상태로 변경한다.
  /// [인수인계] 근무 중에만 화면의 휴식 시작 시각을 설정한다.
  bool startRest({DateTime? now}) {
    if (phase != WorkPhase.working) return false;
    restStartedAt = now ?? DateTime.now();
    phase = WorkPhase.resting;
    return true;
  }

  // 구정민 : 휴식 화면 복귀 시 호출되어 휴식시간을 합산하고 근무 상태로 돌아간다.
  /// [인수인계] 휴식 시간을 화면용 합계에 더하고 근무 상태로 되돌린다.
  bool resumeWork({DateTime? now}) {
    if ((phase != WorkPhase.resting && phase != WorkPhase.stopped) ||
        restStartedAt == null) {
      return false;
    }
    final duration = (now ?? DateTime.now()).difference(restStartedAt!);
    if (!duration.isNegative) {
      if (isStopped) {
        _totalStopped += duration;
      } else {
        _totalRest += duration;
      }
    }
    restStartedAt = null;
    phase = WorkPhase.working;
    return true;
  }

  // 구정민 : HomeScreen의 종료 확인 후 호출되며, 계산된 근무 기록은 WorkHistoryScreen에서 사용된다.
  /// [인수인계] 화면용 근무 기록을 만들고 다음 근무의 최초 측정 상태를 초기화한다.
  bool endWork({DateTime? now}) {
    if (phase == WorkPhase.ready || startedAt == null) return false;
    final endedAt = now ?? DateTime.now();
    if ((phase == WorkPhase.resting || phase == WorkPhase.stopped) &&
        restStartedAt != null) {
      final lastRest = endedAt.difference(restStartedAt!);
      if (!lastRest.isNegative) {
        if (isStopped) {
          _totalStopped += lastRest;
        } else {
          _totalRest += lastRest;
        }
      }
    }
    workHistory.insert(
      0,
      WorkHistoryEntry(
        startedAt: startedAt!,
        endedAt: endedAt,
        restDuration: _totalRest,
        stoppedDuration: _totalStopped,
      ),
    );
    phase = WorkPhase.ready;
    startedAt = null;
    restStartedAt = null;
    _totalRest = Duration.zero;
    _totalStopped = Duration.zero;
    // 구정민 : 수정 - 종료 시 워치 연결은 유지하고 건강 측정 완료만 초기화해 다음 근무 전 재측정하도록 한다.
    resetInitialMeasurement();
    return true;
  }
}
