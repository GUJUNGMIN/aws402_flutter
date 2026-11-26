// [인수인계] 근무 중 건강 카드와 근무/휴식 버튼을 조합한다. 측정값·판정의 원본은 전달받은 WorkState다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

import '../config/step2_feature_flags.dart';

import '../l10n/app_localizations.dart';
import '../mobile/home_dashboard.dart';
import 'weather_summary_widget.dart';
import 'health_metric_card.dart';

class WorkWidget extends StatelessWidget {
  final VoidCallback onButtonPressed;
  final VoidCallback onRestPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onHealthHistoryPressed;
  final VoidCallback onContactPressed;
  final DateTime? workStartedAt;
  final DateTime? restStartedAt;
  final bool isResting;
  final bool isStopped;
  final bool watchConnected;
  final VoidCallback? onWatchStatusPressed;

  // 구정민 : 수정 - 하드코딩된 측정 카드 대신 서버 저장 확인된 최근 워치 수치를 표시한다.
  final int? latestBpm;
  final double? latestTemperature;
  final int? latestSpo2;
  final bool latestFall;
  final String latestGrade;
  final String serverMessage;
  final WeatherSnapshot? weather;
  final bool weatherLoading;
  final bool weatherFailed;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const WorkWidget({
    super.key,
    required this.onButtonPressed,
    required this.onRestPressed,
    required this.onHistoryPressed,
    required this.onHealthHistoryPressed,
    required this.onContactPressed,
    this.workStartedAt,
    this.restStartedAt,
    this.isResting = false,
    this.isStopped = false,
    this.watchConnected = false,
    this.onWatchStatusPressed,
    this.latestBpm,
    this.latestTemperature,
    this.latestSpo2,
    this.latestFall = false,
    this.latestGrade = 'NORMAL',
    this.serverMessage = '서버 응답 대기',
    this.weather,
    this.weatherLoading = false,
    this.weatherFailed = false,
  });

  /// [인수인계] 공통 HealthMetricCard에 항목 이름·저장 수치·서버 판정 표시를 전달한다.
  Widget _healthCard({
    required String asset,
    required String title,
    required String value,
  }) {
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return HealthMetricCard(
      asset: asset,
      title: title,
      value: watchConnected ? value : '—',
      status: !watchConnected || latestBpm == null
          ? '미측정'
          : !Step2FeatureFlags.showEmergency &&
                Step2FeatureFlags.isEmergencyStatus(latestGrade)
          ? '현재 표시하지 않는 상태'
          : latestGrade,
      statusColor:
          watchConnected && latestBpm != null && latestGrade == 'NORMAL'
          ? const Color(0xFF098A45)
          : Colors.red,
    );
  }

  /// [인수인계] 저장된 기상 관측 요약과 안내를 표시한다.
  Widget _weatherBanner({required bool compact}) {
    // 구정민 : 수정 - 근무·휴식 화면 모두 상단 기온 아래에 관측값 4종을 표시한다.
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return WeatherSummaryWidget(
      weather: weather,
      loading: weatherLoading,
      failed: weatherFailed,
      compact: compact,
    );
  }

  /// [인수인계] 근무 화면 동작 버튼과 전달된 콜백을 연결한다.
  Widget _actionButton({
    required String label,
    required VoidCallback onPressed,
    required bool filled,
    Color? color,
    IconData? icon,
  }) {
    final background = color ?? const Color(0xFF2866E8);
    return SizedBox.expand(
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: background,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 22),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8A99AF)),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF315D97),
                  ),
                ),
              ),
            ),
    );
  }

  /// [인수인계] 화면 크기에 맞춰 근무 카드와 버튼 영역을 구성한다.
  Widget _buildBody(BuildContext context, double height) {
    final l10n = AppLocalizations.of(context)!;
    final compact = height < 550;
    final actionHeight = compact ? 46.0 : 51.0;
    final statusHeight = compact ? 32.0 : 36.0;
    final buttonGap = compact ? 5.0 : 7.0;
    // 구정민 : 수정 - 한 화면 배치를 유지하면서 4가지 관측값을 한 줄로 읽을 수 있는 높이를 확보한다.
    final weatherHeight = compact ? 56.0 : 60.0;

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Column(
      children: [
        // 구정민 : 수정 - 관측 날씨(4개 지표)를 먼저, 근무·휴식 상태는 그 아래에 표시한다.
        SizedBox(
          height: weatherHeight,
          child: _weatherBanner(compact: compact),
        ),
        SizedBox(height: buttonGap),
        SizedBox(
          height: statusHeight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isResting || isStopped
                  ? const Color(0xFFFFF0D7)
                  : const Color(0xFFE4F6EC),
              border: Border.all(
                color: isResting || isStopped
                    ? const Color(0xFFDE9D3F)
                    : const Color(0xFF49A577),
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Icon(
                  isStopped
                      ? Icons.pause_circle
                      : isResting
                      ? Icons.hotel
                      : Icons.check_circle,
                  color: isResting || isStopped
                      ? const Color(0xFFAE6400)
                      : const Color(0xFF15804A),
                  size: 21,
                ),
                const SizedBox(width: 7),
                Text(
                  isStopped
                      ? '작업 중지'
                      : isResting
                      ? '휴식 중'
                      : '근무 중',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isResting || isStopped
                        ? const Color(0xFF945500)
                        : const Color(0xFF12673B),
                  ),
                ),
                const Spacer(),
                // 구정민 : 근무 시작 시각부터의 경과 시간을 1분 간격으로 갱신한다.
                StreamBuilder<DateTime>(
                  stream: Stream<DateTime>.periodic(
                    const Duration(minutes: 1),
                    (_) => DateTime.now(),
                  ),
                  initialData: DateTime.now(),
                  builder: (context, snapshot) {
                    final start = isResting || isStopped
                        ? restStartedAt
                        : workStartedAt;
                    if (start == null) {
                      return const Text(
                        '임시 근무',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF355B48),
                        ),
                      );
                    }
                    final elapsed = (snapshot.data ?? DateTime.now())
                        .difference(start);
                    final minutes = elapsed.isNegative ? 0 : elapsed.inMinutes;
                    return Text(
                      '${isStopped
                          ? '중지'
                          : isResting
                          ? '휴식'
                          : '경과'} ${minutes ~/ 60}시간 ${minutes % 60}분',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF355B48),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: buttonGap),
        // 구정민 : 수정 - 워치 연결 상태를 근무·휴식 상태 아래에 표시한다.
        SizedBox(
          height: 27,
          child: InkWell(
            onTap: onWatchStatusPressed,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFCBD4E0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.watch, size: 18),
                  const SizedBox(width: 6),
                  const Text('워치 연결 상태', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
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
                  const Text(
                    '워치',
                    style: TextStyle(fontSize: 11, color: Color(0xFF687587)),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: buttonGap),
        // 구정민 : 수정 - 낙상 카드를 숨기면 산소포화도 카드가 남은 가로 폭을 사용한다.
        // 구정민 : 기존 낙상 카드 자체는 STEP 3 재활성화를 위해 그대로 보존한다.
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _healthCard(
                        asset: 'assets/images/icon_health_bpm.png',
                        title: l10n.bpm,
                        value: latestBpm == null ? '—' : '$latestBpm bpm',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _healthCard(
                        asset: 'assets/images/icon_health_temperature.png',
                        title: '피부온도',
                        value: latestTemperature == null
                            ? '—'
                            : '$latestTemperature ℃',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _healthCard(
                        asset: 'assets/images/icon_health_spo2.png',
                        title: l10n.spo2,
                        value: latestSpo2 == null ? '—' : '$latestSpo2%',
                      ),
                    ),
                    if (Step2FeatureFlags.showFall) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _healthCard(
                          asset: 'assets/images/icon_health_fall.png',
                          title: l10n.is_fall,
                          value: latestBpm == null
                              ? '—'
                              : (latestFall ? '감지' : '없음'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // 구정민 : 수정 - 서버 ACK와 실제 의료 감지가 아님을 한 화면에 표시한다.
        Text(
          serverMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF555C69)),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: compact ? 27 : 31,
          child: TextButton(
            onPressed: onHealthHistoryPressed,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('나의 상태 이력 보기', style: TextStyle(fontSize: 13)),
          ),
        ),
        SizedBox(
          height: actionHeight,
          child: Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: isResting || isStopped ? '근무 재개' : l10n.work_rest,
                  onPressed: onRestPressed,
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: l10n.work_end,
                  onPressed: onButtonPressed,
                  filled: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: actionHeight,
          child: Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: l10n.work_history,
                  onPressed: onHistoryPressed,
                  filled: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: l10n.connect_pic,
                  onPressed: onContactPressed,
                  filled: true,
                  color: const Color(0xFFD91C2B),
                  icon: Icons.phone_forwarded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaleLarge = MediaQuery.textScalerOf(context).scale(16) > 18;
        // 구정민 : 수정 - 일반 휴대폰은 스크롤 없이 표시하고, 매우 작은 화면·큰 접근성 글꼴에서만 스크롤을 허용한다.
        final minHeight = textScaleLarge ? 680.0 : 540.0;
        if (constraints.maxHeight < minHeight) {
          return SingleChildScrollView(
            child: SizedBox(
              height: minHeight,
              child: _buildBody(context, minHeight),
            ),
          );
        }
        return _buildBody(context, constraints.maxHeight);
      },
    );
  }
}
