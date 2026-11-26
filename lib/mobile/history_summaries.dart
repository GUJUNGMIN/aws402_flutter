// [인수인계] 서버가 집계한 기간별 근무·알림 이력 응답을 표시 모델로 변환한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

// 구정민 : 모바일 전용 근무 요약/날짜별 알림 API 응답 모델. UI가 DB 컬럼에 직접 의존하지 않도록 한다.
import 'health_status.dart';

class WorkSummary {
  final int workId;
  final String jobTitle;
  final String region;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final int? totalMinutes;
  final int? restMinutes;
  final int? workingMinutes;
  final int? stoppedMinutes;
  final int noticeCount;
  final int warningCount;
  final int dangerCount;
  final int emergencyCount;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const WorkSummary({
    required this.workId,
    required this.jobTitle,
    required this.region,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    required this.totalMinutes,
    required this.restMinutes,
    required this.workingMinutes,
    this.stoppedMinutes,
    required this.noticeCount,
    required this.warningCount,
    required this.dangerCount,
    this.emergencyCount = 0,
  });

  /// [인수인계] 서버 응답 JSON을 WorkSummary 모델로 변환한다. 날짜/누락 필드는 이 변환부와 서버 계약을 함께 확인한다.
  factory WorkSummary.fromJson(Map<String, dynamic> json) => WorkSummary(
    workId: (json['workId'] as num).toInt(),
    jobTitle: json['jobTitle']?.toString() ?? '일자리 정보 없음',
    region: json['region']?.toString() ?? '지역 정보 없음',
    startedAt: DateTime.parse(json['startedAt'].toString()),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'].toString()),
    status: json['status']?.toString() ?? 'INCOMPLETE',
    totalMinutes: (json['totalMinutes'] as num?)?.toInt(),
    restMinutes: (json['restMinutes'] as num?)?.toInt(),
    workingMinutes: (json['workingMinutes'] as num?)?.toInt(),
    stoppedMinutes: (json['stoppedMinutes'] as num?)?.toInt(),
    noticeCount: (json['noticeCount'] as num?)?.toInt() ?? 0,
    warningCount: (json['warningCount'] as num?)?.toInt() ?? 0,
    dangerCount: (json['dangerCount'] as num?)?.toInt() ?? 0,
    emergencyCount: (json['emergencyCount'] as num?)?.toInt() ?? 0,
  );

  bool get hasAlerts =>
      noticeCount + warningCount + dangerCount + emergencyCount > 0;
  bool get isComplete => status == 'COMPLETED';
}

class StatusEvent {
  final int alertId;
  final String status;
  final DateTime occurredAt;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const StatusEvent({
    required this.alertId,
    required this.status,
    required this.occurredAt,
  });

  /// [인수인계] 서버 응답 JSON을 StatusEvent 모델로 변환한다. 날짜/누락 필드는 이 변환부와 서버 계약을 함께 확인한다.
  factory StatusEvent.fromJson(Map<String, dynamic> json) => StatusEvent(
    alertId: (json['alertId'] as num).toInt(),
    status: HealthStatus.normalize(json['statusCode'] ?? json['status']),
    occurredAt: DateTime.parse(json['occurredAt'].toString()),
  );
}

class DailyStatusSummary {
  final DateTime date;
  final int noticeCount;
  final int warningCount;
  final int dangerCount;
  final int emergencyCount;
  final List<StatusEvent> events;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const DailyStatusSummary({
    required this.date,
    required this.noticeCount,
    required this.warningCount,
    required this.dangerCount,
    this.emergencyCount = 0,
    required this.events,
  });

  /// [인수인계] 서버 응답 JSON을 DailyStatusSummary 모델로 변환한다. 날짜/누락 필드는 이 변환부와 서버 계약을 함께 확인한다.
  factory DailyStatusSummary.fromJson(Map<String, dynamic> json) =>
      DailyStatusSummary(
        date: DateTime.parse(json['date'].toString()),
        noticeCount: (json['noticeCount'] as num?)?.toInt() ?? 0,
        warningCount: (json['warningCount'] as num?)?.toInt() ?? 0,
        dangerCount: (json['dangerCount'] as num?)?.toInt() ?? 0,
        emergencyCount: (json['emergencyCount'] as num?)?.toInt() ?? 0,
        // 정상 이외의 상태 이력을 표시하며 응급 코드 7005도 포함한다.
        events: (json['events'] as List<dynamic>? ?? const [])
            .map(
              (e) => StatusEvent.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .where(
              (e) => const {
                'NOTICE',
                'WARNING',
                'DANGER',
                'EMERGENCY',
              }.contains(e.status),
            )
            .toList(),
      );

  int get totalCount =>
      noticeCount + warningCount + dangerCount + emergencyCount;
}
