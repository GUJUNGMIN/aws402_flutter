// [인수인계] 같은 측정 묶음의 ID·실제 측정 시각·심박·피부온도·산소포화도를 표현한다. 정상값을 만들어 누락을 채우지 않는다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

// 구정민 : 수정 - 워치의 완전한 측정 묶음과 서버에 저장된 응답을 표현한다.
class HealthMeasurement {
  final String sampleId;
  final DateTime measuredAt;
  final int bpm;
  final double temperature;
  final int spo2;
  final bool fallDetected;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HealthMeasurement({
    required this.sampleId,
    required this.measuredAt,
    required this.bpm,
    required this.temperature,
    required this.spo2,
    this.fallDetected = false,
  });

  // 구정민 : 수정 - 화면에는 전송값이 아니라 서버가 실제 저장한 수치를 반영한다.
  /// [인수인계] 저장 응답의 ID·실제 측정 시각·세 수치를 파싱한다. 요청값을 그대로 저장 성공값으로 재사용하지 않는다.
  factory HealthMeasurement.fromServerJson(Map<String, dynamic> data) {
    final sampleId = data['sampleId'];
    final measuredAt = data['measuredAt'];
    final bpm = data['bpm'];
    final temperature = data['skinTemperature'];
    final spo2 = data['spo2'];
    if (sampleId is! String ||
        measuredAt is! String ||
        bpm is! num ||
        temperature is! num ||
        spo2 is! num ||
        !bpm.isFinite ||
        !spo2.isFinite ||
        bpm != bpm.toInt() ||
        spo2 != spo2.toInt()) {
      throw const FormatException('서버 측정 데이터 형식을 확인해 주세요.');
    }
    final value = HealthMeasurement(
      sampleId: sampleId,
      measuredAt: DateTime.parse(measuredAt),
      bpm: bpm.toInt(),
      temperature: temperature.toDouble(),
      spo2: spo2.toInt(),
    );
    if (!value.isValid) throw const FormatException('서버 측정값이 유효하지 않습니다.');
    return value;
  }

  // 구정민 : 수정 - 전송 형식 검사이며 정상/주의/경고/위험 판정은 서버 DB 기준을 사용한다.
  /// [인수인계] 전송에 필요한 ID/유한 수치/센서 범위가 유효한지 검사한다. 건강 정상 판정을 뜻하지 않는다.
  bool get isValid =>
      RegExp(r'^[A-Za-z0-9._:-]{1,128}$').hasMatch(sampleId) &&
      bpm >= 25 &&
      bpm <= 250 &&
      temperature.isFinite &&
      temperature >= 0 &&
      temperature <= 99 &&
      spo2 >= 0 &&
      spo2 <= 100;

  // 구정민 : 수정 - 걸음 수는 수집하지 않고 중복/신선도 검증용 ID와 실제 시각을 전송한다.
  /// [인수인계] 워치 측정 묶음을 UTC 시각과 센서 필드로 직렬화한다. steps/강제 판정은 포함하지 않는다.
  Map<String, dynamic> toJson() => {
    'sampleId': sampleId,
    'measuredAt': measuredAt.toUtc().toIso8601String(),
    'bpm': bpm,
    'skinTemperature': temperature,
    'spo2': spo2,
    'fallDetected': fallDetected,
  };
}
