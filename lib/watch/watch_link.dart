// 워치 app-scenario 와의 실제 통신을 WatchBridgeClient(앱 데이터 경계)에 연결한다.
// - 연결: seniorsafe_watch 노드 이벤트 → reportConnection
// - 근무 전 건강 측정: REQ_PRECHECK → PRECHECK_RESULT → reportMeasurement
// - 근무 중: SUMMARY_MINUTE(1분 요약) → reportMeasurement (심박·SpO2·피부 온도가 모두 있을 때만)
// - 근무 세션: CMD_SUMMARY · CMD_SESSION (START / BREAK_START / BREAK_END / END / RESET)
// - 워치 등급·SOS·응답·상태 이벤트 → notices (화면 표시용). 경고 이상 알림은 네이티브 AlertNotifier 가 먼저 띄운다.
// 메시지 형식의 기준은 shared/protocol/PROTOCOL.md 이다. 서버 판정은 기존대로 서버 응답만 쓴다.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/health_measurement.dart';
import '../wear/protocol/envelope.dart';
import '../wear/protocol/msg_type.dart';
import '../wear/wear_channel.dart';
import 'watch_bridge_client.dart';
import 'watch_client.dart';

/// 화면에 보일 워치 소식. [urgent]면 바로 띄우고, 아니면 상태 문구로 보인다.
class WatchNotice {
  final String text;
  final bool urgent;

  const WatchNotice(this.text, {this.urgent = false});

  @override
  String toString() => text;
}

/// 워치 메시지를 [HealthMeasurement]로 바꾼 결과. 값이 하나라도 없으면 [measurement]는 null이고 [missing]에 이유가 있다.
/// 빠진 값을 다른 값으로 채우지 않는다 (NFR-05).
class WatchSampleResult {
  final HealthMeasurement? measurement;
  final List<String> missing;

  const WatchSampleResult(this.measurement, this.missing);

  bool get complete => measurement != null;
}

/// 워치 근무 세션 명령의 결과. [blocked]는 워치가 받아서 거부한 것(경고 이상에서 종료 등, FR-W-01),
/// [problem]만 있으면 전달하지 못한 것이다.
class WatchCommandResult {
  final String? problem;
  final bool blocked;

  const WatchCommandResult.ok() : problem = null, blocked = false;
  const WatchCommandResult.failed(String this.problem) : blocked = false;
  const WatchCommandResult.blocked(String this.problem) : blocked = true;

  bool get ok => problem == null;
}

class WatchLink {
  /// main.dart가 등록한다. 테스트처럼 등록되지 않았으면 null이며 워치 명령을 보내지 않는다.
  static WatchLink? instance;

  /// 근무 전 측정 항목. HRV는 서버로 보내지 않으므로 재지 않는다 (60초 절약).
  static const precheckItems = ['HR', 'SPO2', 'SKIN_TEMP'];

  /// 항목 하나를 기다리는 시간(초). 워치 PrecheckRunner 의 timeoutSec.
  static const precheckItemTimeoutSec = 60;

  /// 근무 중 1분 요약 간격(초).
  static const summaryIntervalSec = 60;

  /// 근무 중 Sensor SDK(SpO2·피부 온도) 측정 간격(초). phone/ 시나리오 앱의 기본값과 같다.
  /// 이 간격마다 1분 요약에 SpO2·피부 온도가 담기므로 서버 전송도 대략 이 간격이 된다.
  static const sdkIntervalSec = 300;

  final WearChannel _wear;
  final WatchBridgeClient _bridge;
  final _notices = StreamController<WatchNotice>.broadcast();
  StreamSubscription<WearEvent>? _subscription;

  List<WatchNode> nodes = const [];
  String? sessionId;
  String? sessionState;

  WatchLink(this._bridge, {WearChannel? channel})
    : _wear = channel ?? WearChannel();

  Stream<WatchNotice> get notices => _notices.stream;

  /// 네이티브 이벤트 구독을 시작한다. 구독하면 네이티브가 현재 노드 목록과 저장해 둔 메시지를 보낸다.
  void start() {
    _subscription ??= _wear.events.listen(
      _onEvent,
      onError: (Object e) {
        _setNodes(const []);
        _notify('워치 통신 채널 오류: $e', urgent: true);
      },
    );
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _notices.close();
  }

  // ------------------------------------------------------------ WatchBridgeClient 콜백

  /// 노드를 다시 조회한다. 워치가 없으면 이유를 담아 오류를 던진다.
  Future<void> connect() async {
    final List<WatchNode> found;
    try {
      found = await _wear.refreshNodes();
    } catch (e) {
      _setNodes(const []);
      throw StateError('워치 노드 조회 실패: $e');
    }
    _setNodes(found);
    if (found.isEmpty) {
      throw StateError('워치 앱을 찾지 못했습니다. 워치에서 앱을 실행하고 블루투스 연결을 확인해 주세요.');
    }
  }

  /// Data Layer 연결은 시스템이 관리하므로 앱이 끊지 않는다.
  Future<void> disconnect() async {}

  /// 근무 전 건강 측정. 워치에서 심박·SpO2·피부 온도를 재고, 모두 있으면 측정 스트림으로 보낸다.
  /// 결과는 WatchHealthController가 받아 서버로 보낸다. 실패하면 이유를 담아 오류를 던진다.
  Future<void> requestMeasurement() async {
    // 지난 근무의 요약 화면이 남아 있으면 처음 화면으로 돌린다. 근무 중이면 워치가 거부하고, 아래 사전 검사도 BUSY로 끝난다.
    await _wear.request(MsgType.cmdSession, {'action': 'RESET'});
    final r = await _wear.request(MsgType.reqPrecheck, {
      'items': precheckItems,
      'timeoutSec': precheckItemTimeoutSec,
    });
    if (!r.ok || r.reply == null) {
      throw StateError('워치 측정 실패 (${r.error ?? '응답 없음'}: ${r.detail ?? ''})');
    }
    final result = fromPrecheck(r.reply!);
    if (!result.complete) {
      throw StateError('워치 측정값이 부족합니다: ${result.missing.join(' / ')}');
    }
    _bridge.reportMeasurement(result.measurement!);
  }

  // ------------------------------------------------------------ 근무 세션

  /// 근무 시작. 센서 측정 간격을 먼저 보내고 세션을 시작한다.
  /// 워치는 이어서 설정 대기(EX-08)·착용 확인·기저 심박 측정을 하고 1분 요약을 보내기 시작한다.
  Future<WatchCommandResult> startSession() async {
    final s = await _wear.request(MsgType.cmdSummary, {
      'on': true,
      'intervalSec': summaryIntervalSec,
      'sdkIntervalSec': sdkIntervalSec,
    });
    final summaryProblem = !s.ok
        ? '${s.error}: ${s.detail ?? ''}'
        : s.reply?.payload['error'] as String?;
    final result = await _session('START');
    if (!result.ok) return result;
    if (summaryProblem != null) {
      return WatchCommandResult.failed(
        '워치 근무는 시작했지만 센서 측정 설정을 보내지 못했습니다 ($summaryProblem)',
      );
    }
    return result;
  }

  Future<WatchCommandResult> startBreak() => _session('BREAK_START');

  Future<WatchCommandResult> endBreak() => _session('BREAK_END');

  /// 근무 종료. 워치가 거부하면(경고 이상 등, FR-W-01) blocked로 돌려준다.
  Future<WatchCommandResult> endSession() => _session('END');

  bool get connected => nodes.isNotEmpty;

  Future<WatchCommandResult> _session(String action) async {
    final r = await _wear.request(MsgType.cmdSession, {
      'action': action,
    }, sessionId: sessionId);
    if (!r.ok || r.reply == null) {
      return WatchCommandResult.failed(
        '워치에 전달하지 못했습니다 (${r.error ?? '응답 없음'}: ${r.detail ?? ''})',
      );
    }
    final p = r.reply!.payload;
    _applySessionState(p);
    if (p['blocked'] == true) {
      return WatchCommandResult.blocked(
        '워치가 거부했습니다: ${p['reason'] ?? '이유 없음'}',
      );
    }
    return const WatchCommandResult.ok();
  }

  void _applySessionState(Map<String, dynamic> p) {
    sessionState = p['state'] as String?;
    sessionId = p['sessionId'] as String? ?? sessionId;
    if (sessionState == 'IDLE') sessionId = null;
  }

  // ------------------------------------------------------------ 받기

  void _onEvent(WearEvent e) {
    switch (e) {
      case WearNodes(:final nodes):
        _setNodes(nodes);
      case WearMessage(:final envelope):
        _onMessage(envelope);
      case WearLog(:final dir, :final text):
        if (dir == '!') debugPrint('[워치] $text');
      default:
        break;
    }
  }

  void _onMessage(Envelope env) {
    switch (env.type) {
      case MsgType.summaryMinute:
        final result = fromSummary(env);
        if (result.complete) {
          _bridge.reportMeasurement(result.measurement!);
        } else {
          _notify(
            '워치 1분 요약 #${env.payload['index']}: 서버 전송 안 함 (${result.missing.join(' / ')})',
          );
        }
      case MsgType.sessionState:
        // 요청 없이 워치가 보낸 세션 변화 (근무 시작 완료, 워치에서 종료 등)
        _applySessionState(env.payload);
        debugPrint(
          '[워치] 세션 상태 ${env.payload['state']} ${env.payload['reason'] ?? ''}',
        );
      default:
        final text = describeEvent(env);
        if (text != null) _notify(text.text, urgent: text.urgent);
    }
  }

  void _setNodes(List<WatchNode> found) {
    nodes = found;
    debugPrint(
      '[워치] 노드 ${found.length}개 ${found.map((n) => n.name).join(', ')}',
    );
    _bridge.reportConnection(
      found.isEmpty ? WatchConnection.disconnected : WatchConnection.connected,
    );
  }

  void _notify(String text, {bool urgent = false}) {
    debugPrint('[워치] $text');
    if (!_notices.isClosed) _notices.add(WatchNotice(text, urgent: urgent));
  }

  // ------------------------------------------------------------ 변환 (테스트용으로 공개)

  /// PRECHECK_RESULT → HealthMeasurement. sampleId는 응답의 msgId, 측정 시각은 응답 생성 시각이다.
  static WatchSampleResult fromPrecheck(Envelope env) {
    final items = <String, Map<String, dynamic>>{
      for (final raw in (env.payload['items'] as List? ?? const []))
        if (raw is Map)
          (raw['item'] as String? ?? '?'): raw.cast<String, dynamic>(),
    };
    final missing = <String>[];
    double? value(String item, String label) {
      final i = items[item];
      if (i == null) {
        missing.add('$label 결과 없음');
        return null;
      }
      final v = (i['value'] as num?)?.toDouble();
      if (i['ok'] != true || v == null) {
        missing.add(
          '$label ${i['error'] ?? '실패'}${i['detail'] != null ? ' (${i['detail']})' : ''}',
        );
        return null;
      }
      return v;
    }

    if (env.payload['onBody'] == false) missing.add('워치 미착용');
    final hr = value('HR', '심박');
    final spo2 = value('SPO2', 'SpO2');
    final skin = value('SKIN_TEMP', '피부 온도');
    return _build(env, hr, spo2, skin, env.createdAt, missing);
  }

  /// SUMMARY_MINUTE → HealthMeasurement. 측정 시각은 구간 끝(toMs)이다.
  static WatchSampleResult fromSummary(Envelope env) {
    final p = env.payload;
    final missing = <String>[];
    double? value(String key, String label) {
      final v = (p[key] as num?)?.toDouble();
      if (v == null) missing.add('$label 없음');
      return v;
    }

    final hr = value('hrAvg', '심박');
    final spo2 = value('spo2', 'SpO2');
    final skin = value('skinTempC', '피부 온도');
    if (missing.isNotEmpty && p['note'] != null) {
      missing.add('워치: ${p['note']}');
    }
    final toMs = (p['toMs'] as num?)?.toInt() ?? env.createdAt;
    return _build(env, hr, spo2, skin, toMs, missing);
  }

  static WatchSampleResult _build(
    Envelope env,
    double? hr,
    double? spo2,
    double? skin,
    int measuredAtMs,
    List<String> missing,
  ) {
    if (missing.isNotEmpty || hr == null || spo2 == null || skin == null) {
      return WatchSampleResult(null, missing);
    }
    final m = HealthMeasurement(
      sampleId: env.msgId,
      measuredAt: DateTime.fromMillisecondsSinceEpoch(measuredAtMs),
      bpm: hr.round(),
      temperature: skin,
      spo2: spo2.round(),
    );
    if (!m.isValid) {
      return WatchSampleResult(null, [
        '측정값 범위 벗어남 (심박 ${m.bpm}, SpO2 ${m.spo2}, 피부 온도 ${m.temperature})',
      ]);
    }
    return WatchSampleResult(m, const []);
  }

  /// 화면에 알릴 워치 이벤트 문구. 알릴 것이 없으면 null.
  static WatchNotice? describeEvent(Envelope env) {
    final p = env.payload;
    const label = {
      'NORMAL': '정상',
      'NOTICE': '주의',
      'WARNING': '경고',
      'DANGER': '위험',
      'EMERGENCY': '위험(위급)',
      'UNMEASURABLE': '측정 불가',
    };
    String g(Object? v) => label[v] ?? '$v';
    switch (env.type) {
      case MsgType.eventGrade:
        final grade = p['grade'];
        return WatchNotice(
          '워치 판정: ${g(grade)}${p['reasonCode'] != null ? ' (${p['reasonCode']})' : ''}',
          urgent: grade != 'NORMAL',
        );
      case MsgType.eventSos:
        return WatchNotice(
          '워치 SOS: ${p['state']}${p['reasonCode'] != null ? ' (${p['reasonCode']})' : ''}',
          urgent: true,
        );
      case MsgType.eventResponse:
        return WatchNotice(
          '워치 응답: ${p['response'] == 'HELP' ? '도움 요청' : p['response']}',
          urgent: p['response'] == 'HELP',
        );
      case MsgType.eventStatus:
        return WatchNotice(
          '워치 상태: ${p['kind']}${p['value'] != null ? ' ${p['value']}' : ''}${p['note'] != null ? ' (${p['note']})' : ''}',
        );
      case MsgType.hr0Result:
        return WatchNotice(
          p['ok'] == false
              ? '워치 기저 심박 측정 실패: ${p['reason'] ?? '이유 없음'}'
              : '워치 기저 심박 측정 완료 (${p['hr0']} bpm)',
          urgent: p['ok'] == false,
        );
      default:
        return null;
    }
  }
}
