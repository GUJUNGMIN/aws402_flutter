// 원본: phone/lib/core/wear/wear_channel.dart (2026-11-26 이식. 고치면 원본과 shared/protocol 도 함께 확인)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'protocol/envelope.dart';
import 'protocol/msg_type.dart';

/// 네이티브에서 올라오는 이벤트 (seniorsafe/wear_events)
sealed class WearEvent {
  const WearEvent(this.at);
  final int at;

  static WearEvent parse(Map<Object?, Object?> m) {
    final at = (m['at'] as num?)?.toInt() ?? (m['receivedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    switch (m['kind']) {
      case 'message':
        final raw = jsonDecode(m['json'] as String) as Map<String, dynamic>;
        return WearMessage(
          at: at,
          envelope: Envelope.fromJson(raw),
          path: m['path'] as String,
          transport: m['transport'] as String,
          bytes: (m['bytes'] as num).toInt(),
          fromStore: m['fromStore'] == true,
          channelMs: (raw['_channelMs'] as num?)?.toInt(),
        );
      case 'nodes':
        return WearNodes(at, [
          for (final n in (m['nodes'] as List))
            WatchNode((n as Map)['id'] as String, n['name'] as String, n['nearby'] == true),
        ]);
      case 'sent':
        return WearSent(at, m['msgId'] as String, m['type'] as String, (m['seq'] as num).toInt(),
            (m['attempt'] as num).toInt(), (m['bytes'] as num).toInt(), m['error'] as String?);
      case 'ack':
        return WearAck(at, m['ackOf'] as String, m['status'] as String, m['type'] as String?,
            (m['seq'] as num?)?.toInt(), (m['rttMs'] as num?)?.toInt(), m['known'] == true);
      case 'duplicate':
        return WearDuplicate(at, m['type'] as String, (m['seq'] as num).toInt(), m['msgId'] as String,
            (m['retry'] as num?)?.toInt() ?? 0);
      default:
        return WearLog(at, m['dir'] as String? ?? '?', m['text'] as String? ?? m.toString());
    }
  }
}

class WatchNode {
  const WatchNode(this.id, this.name, this.nearby);
  final String id;
  final String name;
  final bool nearby;
}

class WearMessage extends WearEvent {
  const WearMessage({
    required int at,
    required this.envelope,
    required this.path,
    required this.transport,
    required this.bytes,
    required this.fromStore,
    this.channelMs,
  }) : super(at);
  final Envelope envelope;
  final String path;
  final String transport;
  final int bytes;

  /// 앱이 꺼져 있을 때 네이티브 DB 에 저장됐다가 넘어온 것 (T2-05)
  final bool fromStore;

  /// 채널(대용량) 전송에 걸린 시간
  final int? channelMs;
}

class WearNodes extends WearEvent {
  const WearNodes(super.at, this.nodes);
  final List<WatchNode> nodes;
}

class WearSent extends WearEvent {
  const WearSent(super.at, this.msgId, this.type, this.seq, this.attempt, this.bytes, this.error);
  final String msgId;
  final String type;
  final int seq;
  final int attempt;
  final int bytes;
  final String? error;
}

class WearAck extends WearEvent {
  const WearAck(super.at, this.ackOf, this.status, this.type, this.seq, this.rttMs, this.known);
  final String ackOf;
  final String status;
  final String? type;
  final int? seq;
  final int? rttMs;
  final bool known;
}

class WearDuplicate extends WearEvent {
  const WearDuplicate(super.at, this.type, this.seq, this.msgId, this.retry);
  final String type;
  final int seq;
  final String msgId;
  final int retry;
}

class WearLog extends WearEvent {
  const WearLog(super.at, this.dir, this.text);
  final String dir;
  final String text;
}

/// 요청 결과 (seniorsafe/wear_cmd request)
class RequestResult {
  const RequestResult({
    required this.ok,
    required this.type,
    this.msgId,
    this.seq,
    this.createdAt,
    this.firstSentAt,
    this.ackAt,
    this.replyAt,
    this.reply,
    this.error,
    this.detail,
  });

  final bool ok;
  final String type;
  final String? msgId;
  final int? seq;
  final int? createdAt;
  final int? firstSentAt;
  final int? ackAt;
  final int? replyAt;
  final Envelope? reply;
  final String? error;
  final String? detail;

  /// 요청 생성 → 응답 수신 (ms)
  int? get elapsedMs => (replyAt != null && createdAt != null) ? replyAt! - createdAt! : null;

  factory RequestResult.fromMap(String type, Map<Object?, Object?> m) {
    final replyJson = m['reply'] as String?;
    final reply = replyJson == null ? null : Envelope.decode(replyJson);
    int? i(String k) => (m[k] as num?)?.toInt();
    var ok = m['ok'] == true;
    var error = m['error'] as String?;
    var detail = m['detail'] as String?;
    if (reply?.type == MsgType.error) {
      ok = false;
      error = reply!.payload['error'] as String?;
      detail = reply.payload['detail'] as String?;
    }
    return RequestResult(
      ok: ok,
      type: type,
      msgId: m['msgId'] as String?,
      seq: i('seq'),
      createdAt: i('createdAt'),
      firstSentAt: i('firstSentAt'),
      ackAt: i('ackAt'),
      replyAt: i('replyAt'),
      reply: reply,
      error: error,
      detail: detail,
    );
  }
}

/// 워치 통신 서비스. 화면은 이 클래스를 거쳐서만 채널을 부른다 (phone/CLAUDE.md).
class WearChannel {
  WearChannel({MethodChannel? cmd, EventChannel? events})
      : _cmd = cmd ?? const MethodChannel('seniorsafe/wear_cmd'),
        _events = events ?? const EventChannel('seniorsafe/wear_events');

  final MethodChannel _cmd;
  final EventChannel _events;
  Stream<WearEvent>? _stream;

  /// 네이티브 이벤트. 처음 구독할 때 네이티브가 저장해 둔(아직 못 넘긴) 메시지를 순서대로 보낸다.
  Stream<WearEvent> get events => _stream ??= _events
      .receiveBroadcastStream()
      .map((e) => WearEvent.parse((e as Map).cast<Object?, Object?>()))
      .asBroadcastStream();

  /// 요청을 보내고 최종 응답(또는 ERROR)이나 타임아웃까지 기다린다.
  Future<RequestResult> request(String type, Map<String, dynamic> payload, {Duration? timeout, String? sessionId}) async {
    final t = timeout ?? MsgType.timeoutOf(type, payload);
    try {
      final m = await _cmd.invokeMethod<Map<Object?, Object?>>('request', {
        'type': type,
        'payload': jsonEncode(payload),
        'timeoutMs': t.inMilliseconds,
        'finalTypes': MsgType.finalTypesOf(type),
        'sessionId': sessionId,
      });
      return RequestResult.fromMap(type, m ?? const {});
    } on PlatformException catch (e) {
      return RequestResult(ok: false, type: type, error: 'PLATFORM', detail: '${e.code} ${e.message}');
    }
  }

  /// 응답을 기다리지 않고 보낸다 (3단계 FINAL_GRADE 처럼 ACK 만 있는 메시지). 큐에 넣는 데까지만 확인한다.
  /// ACK 와 재전송은 네이티브가 맡는다.
  Future<RequestResult> send(String type, Map<String, dynamic> payload, {String? sessionId}) async {
    try {
      final m = await _cmd.invokeMethod<Map<Object?, Object?>>('send', {
        'type': type,
        'payload': jsonEncode(payload),
        'sessionId': sessionId,
      });
      return RequestResult.fromMap(type, m ?? const {});
    } on PlatformException catch (e) {
      return RequestResult(ok: false, type: type, error: 'PLATFORM', detail: '${e.code} ${e.message}');
    }
  }

  Future<List<WatchNode>> refreshNodes() async {
    final m = await _cmd.invokeMethod<Map<Object?, Object?>>('refreshNodes');
    return (WearEvent.parse(m!.cast<Object?, Object?>()) as WearNodes).nodes;
  }

  Future<Map<Object?, Object?>> queue() async => await _cmd.invokeMethod<Map<Object?, Object?>>('queue') ?? const {};

  Future<Map<Object?, Object?>> clearQueue() async =>
      await _cmd.invokeMethod<Map<Object?, Object?>>('clearQueue') ?? const {};
}
