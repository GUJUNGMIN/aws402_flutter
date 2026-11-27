// 원본: phone/lib/core/protocol/envelope.dart (2026-11-26 이식. 고치면 원본과 shared/protocol 도 함께 확인)
import 'dart:convert';

/// 워치↔폰 메시지 봉투. 기준: shared/protocol/PROTOCOL.md 2절.
/// payload 는 종류마다 다르므로 Map 으로 들고, 필요한 곳에서 [MsgType] 별 키로 읽는다.
class Envelope {
  const Envelope({
    this.v = 1,
    required this.msgId,
    required this.type,
    this.replyTo,
    this.sessionId,
    this.participantId,
    this.seq = 0,
    required this.createdAt,
    this.sentAt = 0,
    this.retry = 0,
    this.payload = const {},
  });

  final int v;
  final String msgId;
  final String type;
  final String? replyTo;
  final String? sessionId;
  final String? participantId;
  final int seq;
  final int createdAt;
  final int sentAt;
  final int retry;
  final Map<String, dynamic> payload;

  factory Envelope.fromJson(Map<String, dynamic> j) => Envelope(
        v: (j['v'] as num?)?.toInt() ?? 1,
        msgId: j['msgId'] as String,
        type: j['type'] as String,
        replyTo: j['replyTo'] as String?,
        sessionId: j['sessionId'] as String?,
        participantId: j['participantId'] as String?,
        seq: (j['seq'] as num?)?.toInt() ?? 0,
        createdAt: (j['createdAt'] as num).toInt(),
        sentAt: (j['sentAt'] as num?)?.toInt() ?? 0,
        retry: (j['retry'] as num?)?.toInt() ?? 0,
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  factory Envelope.decode(String text) => Envelope.fromJson(jsonDecode(text) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        'v': v,
        'msgId': msgId,
        'type': type,
        'replyTo': replyTo,
        'sessionId': sessionId,
        'participantId': participantId,
        'seq': seq,
        'createdAt': createdAt,
        'sentAt': sentAt,
        'retry': retry,
        'payload': payload,
      };

  String encode() => jsonEncode(toJson());
}

/// 생체 값 (워치 core/model 의 BioSample 과 같은 형식)
class BioSample {
  const BioSample({
    required this.type,
    required this.value,
    required this.unit,
    required this.accuracy,
    required this.source,
    required this.timestamp,
    this.statusCode,
    this.note,
  });

  final String type;
  final double value;
  final String unit;
  final String accuracy;
  final String source;
  final int timestamp;
  final int? statusCode;
  final String? note;

  factory BioSample.fromJson(Map<String, dynamic> j) => BioSample(
        type: j['type'] as String,
        value: (j['value'] as num).toDouble(),
        unit: j['unit'] as String? ?? '',
        accuracy: j['accuracy'] as String? ?? 'UNKNOWN',
        source: j['source'] as String? ?? '?',
        timestamp: (j['timestamp'] as num).toInt(),
        statusCode: (j['statusCode'] as num?)?.toInt(),
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'unit': unit,
        'accuracy': accuracy,
        'source': source,
        'timestamp': timestamp,
        'statusCode': statusCode,
        'note': note,
      };

  static List<BioSample> listFrom(Object? raw) =>
      (raw as List? ?? const []).map((e) => BioSample.fromJson((e as Map).cast<String, dynamic>())).toList();
}
