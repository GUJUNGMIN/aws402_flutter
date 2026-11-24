// [인수인계] 서버가 조회한 사용자·일자리·기상 JSON을 표시용 모델로 변환한다. 기상 센서값과 워치 피부온도를 혼동하지 않는다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

// 구정민 : 서버 /api/mobile/home 응답 모델. 기존 UI와 네트워크 JSON 형식을 분리한다.
class HomeDashboard {
  final String name;
  final String? jobTitle;
  final bool hasJob;
  final WeatherSnapshot? weather;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HomeDashboard({
    required this.name,
    this.jobTitle,
    required this.hasJob,
    this.weather,
  });

  /// [인수인계] 서버 응답 JSON을 HomeDashboard 모델로 변환한다. 날짜/누락 필드는 이 변환부와 서버 계약을 함께 확인한다.
  factory HomeDashboard.fromJson(Map<String, dynamic> json) {
    final job = json['job'];

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return HomeDashboard(
      name: json['name']?.toString() ?? '',
      jobTitle: job is Map ? job['title']?.toString() : null,
      hasJob: job is Map,
      weather: json['weather'] is Map
          ? WeatherSnapshot.fromJson(
              Map<String, dynamic>.from(json['weather'] as Map),
            )
          : null,
    );
  }
}

class WeatherSnapshot {
  final double? temperatureCelsius;
  final String condition;
  // 구정민 : 수정 - 서버 WEATHER의 강수량·습도·풍향·풍속을 홈/근무 공통 모델로 수신한다.
  final double? rainfallMm;
  final double? humidityPercent;
  final int? windDirectionDegrees;
  final double? windSpeedMs;
  final String notice;
  final bool stale;
  final bool regionMatched;
  final bool officialAdvisoryAvailable;
  final String baseDate;
  final String baseTime;
  final List<WeatherObservation> recentObservations;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const WeatherSnapshot({
    this.temperatureCelsius,
    required this.condition,
    this.rainfallMm,
    this.humidityPercent,
    this.windDirectionDegrees,
    this.windSpeedMs,
    required this.notice,
    required this.stale,
    required this.regionMatched,
    required this.officialAdvisoryAvailable,
    required this.baseDate,
    required this.baseTime,
    required this.recentObservations,
  });

  /// [인수인계] 서버 응답 JSON을 WeatherSnapshot 모델로 변환한다. 날짜/누락 필드는 이 변환부와 서버 계약을 함께 확인한다.
  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) =>
      WeatherSnapshot(
        temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
        condition: json['condition']?.toString() ?? '정보 없음',
        rainfallMm: (json['rainfallMm'] as num?)?.toDouble(),
        humidityPercent: (json['humidityPercent'] as num?)?.toDouble(),
        windDirectionDegrees: (json['windDirectionDegrees'] as num?)?.toInt(),
        windSpeedMs: (json['windSpeedMs'] as num?)?.toDouble(),
        notice: json['notice']?.toString() ?? '정보 없음',
        stale: json['stale'] == true,
        regionMatched: json['regionMatched'] == true,
        officialAdvisoryAvailable: json['officialAdvisoryAvailable'] == true,
        baseDate: json['baseDate']?.toString() ?? '',
        baseTime: json['baseTime']?.toString() ?? '',
        recentObservations:
            (json['recentObservations'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map(
                  (raw) => WeatherObservation.fromJson(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList(),
      );

  String get temperatureText => temperatureCelsius == null
      ? '—℃'
      : '${temperatureCelsius!.toStringAsFixed(1)}℃';

  // 구정민 : 풍향 원본 각도를 8방위 풍향으로 표현한다. 기록이 없으면 숫자를 추정하지 않는다.
  String get rainfallText =>
      rainfallMm == null ? '—' : '${rainfallMm!.toStringAsFixed(1)}mm';
  String get humidityText =>
      humidityPercent == null ? '—' : '${humidityPercent!.round()}%';
  String get windSpeedText =>
      windSpeedMs == null ? '—' : '${windSpeedMs!.toStringAsFixed(1)}m/s';
  String get windDirectionText {
    final degrees = windDirectionDegrees;
    if (degrees == null || degrees < 0 || degrees > 360) return '—';
    const directions = ['북풍', '북동풍', '동풍', '남동풍', '남풍', '남서풍', '서풍', '북서풍'];
    return directions[((degrees % 360 + 22.5) / 45).floor() % 8];
  }
}

class WeatherObservation {
  final String date;
  final String time;
  final double temperatureCelsius;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const WeatherObservation({
    required this.date,
    required this.time,
    required this.temperatureCelsius,
  });

  /// [인수인계] 서버 응답 JSON을 WeatherObservation 모델로 변환한다. 날짜/누락 필드는 이 변환부와 서버 계약을 함께 확인한다.
  factory WeatherObservation.fromJson(Map<String, dynamic> json) =>
      WeatherObservation(
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        temperatureCelsius: (json['temperatureCelsius'] as num).toDouble(),
      );
  String get displayText => '$time ${temperatureCelsius.toStringAsFixed(1)}°';
}
