// [인수인계] 근무 대기 화면에서 안내와 저장된 최초 건강 측정 카드를 표시한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../mobile/home_dashboard.dart';
import 'weather_summary_widget.dart';
import 'health_metric_card.dart';
import '../utils/color_extension.dart';

class MainWidget extends StatelessWidget {
  final VoidCallback onButtonPressed;
  // 구정민 : 수정 - HomeScreen에서 받은 건강 측정·이력 화면 이동 콜백을 버튼에 연결한다.
  final VoidCallback onHealthCheckPressed;
  final VoidCallback onWorkHistoryPressed;
  final VoidCallback onHealthHistoryPressed;
  final VoidCallback? onContactPressed;
  final bool healthCheckCompleted;
  final bool watchConnected;
  // 구정민 : 수정 - 서버 저장 확인된 건강 결과를 근무 전에도 표시한다.
  final bool measurementSaved;
  final int? latestBpm;
  final double? latestTemperature;
  final int? latestSpo2;
  final String? latestGrade;
  final WeatherSnapshot? weather;
  final bool weatherLoading;
  final bool weatherFailed;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const MainWidget({
    super.key,
    required this.onButtonPressed,
    required this.onHealthCheckPressed,
    required this.onWorkHistoryPressed,
    required this.onHealthHistoryPressed,
    this.onContactPressed,
    required this.healthCheckCompleted,
    required this.watchConnected,
    this.measurementSaved = false,
    this.latestBpm,
    this.latestTemperature,
    this.latestSpo2,
    this.latestGrade,
    this.weather,
    this.weatherLoading = false,
    this.weatherFailed = false,
  });

  // 구정민 : 수정 - 근무 전에도 근무 화면과 같은 2+1 카드로 서버 저장 결과를 표시한다.
  /// [인수인계] 공통 HealthMetricCard에 항목 이름·저장 수치·서버 판정 표시를 전달한다.
  Widget _healthCard({
    required String key,
    required String asset,
    required String title,
    required String value,
  }) {
    final grade = switch (latestGrade) {
      'NORMAL' ||
      'NOTICE' ||
      'WARNING' ||
      'DANGER' ||
      'EMERGENCY' => latestGrade!,
      _ => '현재 표시하지 않는 상태',
    };

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return HealthMetricCard(
      key: ValueKey(key),
      asset: asset,
      title: title,
      value: value,
      status: grade,
      statusColor: latestGrade == 'NORMAL'
          ? const Color(0xFF098A45)
          : Colors.red,
    );
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double fontSize = double.tryParse(l10n.font_size) ?? 20.0;
    double fontSizeBig = double.tryParse(l10n.font_size_big) ?? 30.0;
    final showMeasurement =
        watchConnected &&
        measurementSaved &&
        latestBpm != null &&
        latestTemperature != null &&
        latestSpo2 != null &&
        latestGrade != null;
    // 구정민 : 수정 - 서버 판정을 사용하고 기존 응급·낙상 숨김 정책을 유지한다.
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Column(
      children: [
        // 구정민 : 수정 - DB에서 받은 날씨 관측·특이사항만 표시하며 기존 가상 예보를 제거한다.
        WeatherSummaryWidget(
          weather: weather,
          loading: weatherLoading,
          failed: weatherFailed,
        ),
        const SizedBox(height: 8),
        // 구정민 : 수정 - 위치 항목은 제거하고 워치 연결·건강 측정 상태만 날씨 아래에 표시한다.
        InkWell(
          onTap: onHealthCheckPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              border: Border.all(color: const Color(0xFFC5CFDB)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(Icons.watch, size: 19),
                const SizedBox(width: 5),
                const Text('워치 연결', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                CircleAvatar(
                  radius: 5,
                  backgroundColor: watchConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  watchConnected ? '연결' : '해제',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '건강 ${healthCheckCompleted ? '완료' : '미측정'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF394C65),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: showMeasurement
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Semantics(
                    label: '서버 저장 확인된 건강 측정',
                    child: Column(
                      key: const ValueKey('saved-health-results'),
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _healthCard(
                                  key: 'prework-bpm',
                                  asset: 'assets/images/icon_health_bpm.png',
                                  title: '심박수',
                                  value: '$latestBpm bpm',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _healthCard(
                                  key: 'prework-temperature',
                                  asset: 'assets/images/icon_health_temperature.png',
                                  title: '피부온도',
                                  value: '$latestTemperature ℃',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: _healthCard(
                            key: 'prework-spo2',
                            asset: 'assets/images/icon_health_spo2.png',
                            title: '산소포화도',
                            value: '$latestSpo2%',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    '오늘도 안전하게 근무하세요!',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        // 구정민 : 수정 - 건강 측정 및 두 이력 버튼을 추가하여 HomeScreen 콜백으로 연결한다.
        OutlinedButton.icon(
          onPressed: onHealthCheckPressed,
          icon: const Icon(Icons.watch),
          // 구정민 : 수정 - 이미 연결된 워치는 재연결 없이 다음 근무의 건강 측정만 진행한다.
          label: Text(
            healthCheckCompleted
                ? '워치·건강 측정 완료'
                : (watchConnected ? '건강 측정' : '워치 연결·건강 측정'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onWorkHistoryPressed,
                child: const Text('나의 근무 이력'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: onHealthHistoryPressed,
                child: const Text('나의 상태 이력'),
              ),
            ),
          ],
        ),
        const Text(
          '워치 건강 데이터 · 서버 연동',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: l10n.color_green.toColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
          ),
          onPressed: onButtonPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 40.0),
              Text(
                l10n.work_start,
                style: TextStyle(
                  fontSize: fontSizeBig,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.0),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: l10n.color_red.toColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
          ),
          onPressed: onContactPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_forwarded, size: 30.0),
              SizedBox(width: 5.0),
              Text(
                l10n.connect_pic,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
