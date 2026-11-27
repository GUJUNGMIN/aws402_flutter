// 원본: phone/lib/core/protocol/msg_type.dart (2026-11-26 이식. 고치면 원본과 shared/protocol 도 함께 확인)
/// 메시지 종류와 payload 키. 기준: shared/protocol/PROTOCOL.md 4절.
/// 워치(wear/core/model protocol/Payloads.kt)와 폰 네이티브(wear/Paths.kt)의 같은 목록과 맞춘다.
abstract final class MsgType {
  static const ack = 'ACK';
  static const ping = 'PING';
  static const pong = 'PONG';
  static const reqSdkStatus = 'REQ_SDK_STATUS';
  static const sdkStatus = 'SDK_STATUS';
  static const reqHrOnce = 'REQ_HR_ONCE';
  static const measureResult = 'MEASURE_RESULT';
  static const cmdStream = 'CMD_STREAM';
  static const streamState = 'STREAM_STATE';
  static const streamBio = 'STREAM_BIO';
  static const cmdSummary = 'CMD_SUMMARY';
  static const summaryState = 'SUMMARY_STATE';
  static const summaryMinute = 'SUMMARY_MINUTE';
  static const reqSpo2 = 'REQ_SPO2';
  static const reqSkinTemp = 'REQ_SKIN_TEMP';
  static const reqHrv = 'REQ_HRV';
  static const hrvResult = 'HRV_RESULT';
  static const reqHr0 = 'REQ_HR0';
  static const hr0Progress = 'HR0_PROGRESS';
  static const hr0Result = 'HR0_RESULT';
  static const configThreshold = 'CONFIG_THRESHOLD';
  static const configApplied = 'CONFIG_APPLIED';
  static const cmdSession = 'CMD_SESSION';
  static const sessionState = 'SESSION_STATE';
  static const cmdGrade = 'CMD_GRADE';
  static const gradeState = 'GRADE_STATE';
  static const reqSessionSummary = 'REQ_SESSION_SUMMARY';
  static const summarySession = 'SUMMARY_SESSION';
  static const reqBulk = 'REQ_BULK';
  static const bulkHr = 'BULK_HR';
  static const reqBurst = 'REQ_BURST';
  static const eventBurst = 'EVENT_BURST';
  static const eventSos = 'EVENT_SOS';
  static const eventResponse = 'EVENT_RESPONSE';
  static const eventStatus = 'EVENT_STATUS';
  static const error = 'ERROR';

  // 3단계 (PROTOCOL.md 7절)
  static const cmdScenario = 'CMD_SCENARIO';
  static const scenarioState = 'SCENARIO_STATE';
  static const cmdRelease = 'CMD_RELEASE';
  static const cmdEmergency = 'CMD_EMERGENCY';
  static const finalGrade = 'FINAL_GRADE';
  static const eventGrade = 'EVENT_GRADE';

  // 2단계 v2 (PROTOCOL.md 9절)
  static const reqPrecheck = 'REQ_PRECHECK';
  static const precheckResult = 'PRECHECK_RESULT';
  static const cmdResponse = 'CMD_RESPONSE';
  static const cmdRealert = 'CMD_REALERT';
  static const cmdSosCancel = 'CMD_SOS_CANCEL';

  /// type → payload 키 목록 (PROTOCOL.md 4절 표와 같음). 샘플 테스트가 이 목록과 samples 를 대조한다.
  static const Map<String, List<String>> payloadKeys = {
    ack: ['ackOf', 'ackSeq', 'status', 'detail'],
    ping: [],
    pong: ['model', 'appVersion', 'sdkInt', 'batteryPercent', 'charging', 'onBody', 'onBodyNote', 'queueLength'],
    reqSdkStatus: [],
    sdkStatus: ['samsung', 'healthServices'],
    reqHrOnce: ['source', 'timeoutSec'],
    measureResult: ['request', 'samples', 'durationMs', 'note'],
    cmdStream: ['types', 'hz', 'on'],
    streamState: ['on', 'types', 'error'],
    streamBio: ['batchIndex', 'samples'],
    cmdSummary: ['on', 'intervalSec', 'sdkIntervalSec'],
    summaryState: ['on', 'intervalSec', 'error'],
    summaryMinute: [
      'index', 'fromMs', 'toMs', 'hrAvg', 'hrMin', 'hrMax', 'hrCount', 'steps', 'batteryPercent', 'onBody', 'note', //
      'grade', 'activity', 'skinTempC', 'spo2', 'rmssd', 'moving'
    ],
    reqSpo2: ['timeoutSec'],
    reqSkinTemp: ['timeoutSec'],
    reqHrv: ['collectSec'],
    hrvResult: ['rmssd1m', 'sdnn1m', 'count1m', 'rmssd5m', 'sdnn5m', 'count5m', 'source', 'note'],
    reqHr0: ['minutes'],
    hr0Progress: ['elapsedSec', 'totalSec', 'validCount', 'movingSkipped'],
    hr0Result: ['ok', 'hr0', 'validCount', 'movingSkipped', 'reason'],
    configThreshold: ['configVersion', 'hr0', 'weatherLevel', 'values', 'feelsLikeC'],
    configApplied: ['configVersion', 'storedAt', 'applied', 'ignored', 'problems'],
    cmdSession: ['action'],
    sessionState: [
      'state', 'sessionId', 'startedAt', 'breakStartedAt', 'configVersion', 'configSource', 'blocked', 'reason' //
    ],
    cmdGrade: ['grade'],
    gradeState: ['grade', 'previous', 'vibrated', 'note'],
    reqSessionSummary: [],
    summarySession: [
      'sessionId', 'startedAt', 'endedAt', 'maxHr', 'avgHr', 'gradeSeconds', 'warningCount', 'sosCount', //
      'minuteSummaries', 'note', 'hr0Used', 'baselineCandidate', 'sosCancelledCount', 'gaps'
    ],
    reqBulk: ['minutes', 'allowSynthetic'],
    bulkHr: ['minutes', 'synthetic', 'samples', 'note'],
    reqBurst: ['count', 'intervalMs'],
    eventBurst: ['burstId', 'index', 'count'],
    eventSos: ['state', 'trigger', 'countdownSec', 'elapsedSec', 'reasonCode'],
    eventResponse: ['response', 'grade', 'suppressUntil'],
    eventStatus: ['kind', 'value', 'simulated', 'note'],
    error: ['request', 'error', 'detail'],
    cmdScenario: ['action', 'scenarioId', 'inputMode', 'speed', 'virtualStartMs', 'steps'],
    scenarioState: ['scenarioId', 'state', 'inputMode', 'speed', 'stepIndex', 'stepCount', 'virtualNowMs', 'error'],
    cmdRelease: ['alertId', 'toGrade', 'by', 'note'],
    cmdEmergency: ['trigger', 'note'],
    finalGrade: ['grade', 'watchGrade', 'weatherLevel', 'reasonCode', 'decidedAt'],
    eventGrade: [
      'grade', 'previous', 'reasonCode', 'alert', 'realert', 'hr1m', 'hr5m', 'hr0', 'activity', 'weatherLevel', //
      'decidedAt'
    ],
    reqPrecheck: ['items', 'timeoutSec', 'hrvCollectSec'],
    precheckResult: ['items', 'onBody', 'durationMs'],
    cmdResponse: ['response', 'grade'],
    cmdRealert: ['grade'],
    cmdSosCancel: ['note'],
  };

  /// PRECHECK_RESULT.items[] 한 항목의 키 (PROTOCOL.md 9절)
  static const precheckItemKeys = ['item', 'ok', 'value', 'unit', 'source', 'error', 'detail', 'durationMs'];

  /// 대본 한 줄(ScriptStep)의 키 (PROTOCOL.md 7.1절)
  static const scriptStepKeys = ['at', 'hr', 'steps', 'onBody', 'moving', 'fall', 'sos', 'respond', 'battery', 'link', 'crash'];

  /// 요청 → 최종 응답 종류와 기본 타임아웃 (PROTOCOL.md 3.1·6절)
  static List<String> finalTypesOf(String request) => switch (request) {
        ping => [pong],
        reqSdkStatus => [sdkStatus],
        reqHrOnce || reqSpo2 || reqSkinTemp => [measureResult],
        cmdStream => [streamState],
        cmdSummary => [summaryState],
        reqHrv => [hrvResult],
        reqHr0 => [hr0Result],
        configThreshold => [configApplied],
        cmdSession => [sessionState],
        cmdGrade => [gradeState],
        reqSessionSummary => [summarySession],
        reqBulk => [bulkHr],
        reqBurst => [eventBurst],
        cmdScenario => [scenarioState],
        cmdRelease || cmdEmergency || cmdResponse || cmdRealert || cmdSosCancel => [gradeState],
        reqPrecheck => [precheckResult],
        _ => throw ArgumentError('응답을 기다릴 수 없는 요청: $request'),
      };

  static Duration timeoutOf(String request, Map<String, dynamic> p) {
    int sec(String k, int d) => (p[k] as num?)?.toInt() ?? d;
    return switch (request) {
      reqHrOnce || reqSkinTemp || reqSpo2 => Duration(seconds: sec('timeoutSec', 30) + 10),
      reqHrv => Duration(seconds: sec('collectSec', 60) + 15),
      reqHr0 => Duration(seconds: sec('minutes', 3) * 60 + 30),
      reqBulk => const Duration(seconds: 60),
      // 항목마다 timeoutSec, HRV 는 hrvCollectSec. 측정 사이 준비 시간으로 30초를 더한다.
      reqPrecheck => Duration(
          seconds: ((p['items'] as List?)?.where((i) => i != 'HRV').length ?? 3) * sec('timeoutSec', 60) +
              (((p['items'] as List?)?.contains('HRV') ?? true) ? sec('hrvCollectSec', 60) : 0) +
              30),
      _ => const Duration(seconds: 10),
    };
  }
}

/// 등급 (CLAUDE.md 규칙 3). 화면 표기는 [gradeLabel].
const grades = ['NORMAL', 'NOTICE', 'WARNING', 'DANGER', 'EMERGENCY', 'UNMEASURABLE'];
const gradeLabel = {
  'NORMAL': '정상',
  'NOTICE': '주의',
  'WARNING': '경고',
  'DANGER': '위험',
  'EMERGENCY': '위험(위급)',
  'UNMEASURABLE': '측정 불가',
};
