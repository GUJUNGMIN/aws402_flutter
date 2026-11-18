import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class WorkWidget extends StatelessWidget {
  final VoidCallback onButtonPressed;
  final VoidCallback onRestPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onHealthHistoryPressed;
  final VoidCallback onContactPressed;
  final void Function(String type) showAlert;
  final DateTime? workStartedAt;
  final DateTime? restStartedAt;
  final bool isResting;
  final bool watchConnected;
  final VoidCallback? onWatchStatusPressed;

  const WorkWidget({
    super.key,
    required this.onButtonPressed,
    required this.onRestPressed,
    required this.onHistoryPressed,
    required this.onHealthHistoryPressed,
    required this.onContactPressed,
    required this.showAlert,
    this.workStartedAt,
    this.restStartedAt,
    this.isResting = false,
    this.watchConnected = false,
    this.onWatchStatusPressed,
  });

  Widget _healthCard({
    required String asset,
    required String title,
    required String value,
    required bool compact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB2BAC4), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      // 구정민 : 수정 - 업무 시작 후 카드 높이가 작아져도 아이콘·측정값·상태가 넘치지 않도록 전체를 축소한다.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(asset, width: compact ? 23 : 28, height: compact ? 23 : 28),
            const SizedBox(height: 2),
            Text(title, maxLines: 1, softWrap: false,
                style: TextStyle(fontSize: compact ? 14 : 16)),
            const SizedBox(height: 1),
            Text(watchConnected ? value : '—', maxLines: 1, softWrap: false,
                style: TextStyle(fontSize: compact ? 21 : 24,
                    fontWeight: FontWeight.bold, color: const Color(0xFF1D2835))),
            Text(watchConnected ? '정상' : '미측정', style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: watchConnected ? const Color(0xFF098A45) : Colors.red,
            )),
          ],
        ),
      ),
    );
  }

  Widget _weatherBanner({required bool compact}) {
    // 구정민 : 수정 - 기존 근무 화면의 시간대별 날씨 예보를 유지하고 카드 높이를 줄인다.
    final labelSize = compact ? 13.0 : 14.0;
    final hourlySize = compact ? 12.0 : 13.0;
    const orange = Color(0xFFD17800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5DA),
        border: Border.all(color: const Color(0xFFE8A43B), width: 1.3),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Expanded(child: Text('오늘 날씨 (폭염주의보)',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: labelSize,
                    fontWeight: FontWeight.bold, color: orange))),
            Text('99℃', style: TextStyle(fontSize: labelSize + 2,
                fontWeight: FontWeight.bold, color: orange)),
          ]),
          const SizedBox(height: 3),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8A43B)),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('09시 99º', style: TextStyle(fontSize: hourlySize,
                fontWeight: FontWeight.w600)),
            Text('12시 34º', style: TextStyle(fontSize: hourlySize,
                fontWeight: FontWeight.w700, color: orange)),
            Text('15시 35º', style: TextStyle(fontSize: hourlySize,
                fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 5)],
                  Text(label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ]),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8A99AF)),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
              child: FittedBox(fit: BoxFit.scaleDown,
                child: Text(label, style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold,
                  color: Color(0xFF315D97),
                )),
              ),
            ),
    );
  }

  Widget _buildBody(BuildContext context, double height) {
    final l10n = AppLocalizations.of(context)!;
    final compact = height < 550;
    final actionHeight = compact ? 46.0 : 51.0;
    final statusHeight = compact ? 32.0 : 36.0;
    final buttonGap = compact ? 5.0 : 7.0;
    final weatherHeight = compact ? 62.0 : 68.0;

    return Column(
      children: [
        // 구정민 : 수정 - 근무 상태를 첫 줄에 표시하고, 별도 스크롤 없이 건강 카드·조치 버튼을 배치한다.
        SizedBox(
          height: statusHeight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isResting ? const Color(0xFFFFF0D7) : const Color(0xFFE4F6EC),
              border: Border.all(color: isResting ? const Color(0xFFDE9D3F) : const Color(0xFF49A577)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(children: [
              Icon(isResting ? Icons.hotel : Icons.check_circle,
                  color: isResting ? const Color(0xFFAE6400) : const Color(0xFF15804A), size: 21),
              const SizedBox(width: 7),
              Text(isResting ? '휴식 중' : '근무 중', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isResting ? const Color(0xFF945500) : const Color(0xFF12673B))),
              const Spacer(),
              // 구정민 : 근무 시작 시각부터의 경과 시간을 1분 간격으로 갱신한다.
              StreamBuilder<DateTime>(
                stream: Stream<DateTime>.periodic(
                    const Duration(minutes: 1), (_) => DateTime.now()),
                initialData: DateTime.now(),
                builder: (context, snapshot) {
                  final start = isResting ? restStartedAt : workStartedAt;
                  if (start == null) {
                    return const Text('임시 근무',
                        style: TextStyle(fontSize: 13, color: Color(0xFF355B48)));
                  }
                  final elapsed = (snapshot.data ?? DateTime.now()).difference(start);
                  final minutes = elapsed.isNegative ? 0 : elapsed.inMinutes;
                  return Text('${isResting ? '휴식' : '경과'} ${minutes ~/ 60}시간 ${minutes % 60}분',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF355B48)));
                },
              ),
            ]),
          ),
        ),
        SizedBox(height: buttonGap),
        SizedBox(height: weatherHeight, child: _weatherBanner(compact: compact)),
        SizedBox(height: buttonGap),
        // 구정민 : 수정 - 워치 연결 상태를 날씨 바로 아래에 색상 점으로 표시한다.
        SizedBox(height: 27, child: InkWell(
          onTap: onWatchStatusPressed,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFCBD4E0)),
            ),
            child: Row(children: [
              const Icon(Icons.watch, size: 18),
              const SizedBox(width: 6),
              const Text('워치 연결 상태', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              CircleAvatar(radius: 5, backgroundColor:
                  watchConnected ? Colors.green : Colors.red),
              const SizedBox(width: 5),
              Text(watchConnected ? '연결' : '해제',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text('테스트', style: TextStyle(fontSize: 11, color: Color(0xFF687587))),
            ]),
          ),
        )),
        SizedBox(height: buttonGap),
        // 구정민 : 수정 - 예보 상자를 유지하면서 건강 카드 4개의 크기를 자동 조절해 한 화면에 배치한다.
        Expanded(child: Column(children: [
          Expanded(child: Row(children: [
            Expanded(child: _healthCard(
              asset: 'assets/images/icon_health_bpm.png', title: l10n.bpm,
              value: '72 bpm', compact: compact,
            )),
            const SizedBox(width: 6),
            Expanded(child: _healthCard(
              asset: 'assets/images/icon_health_temperature.png', title: '피부온도',
              value: '36.5 ℃', compact: compact,
            )),
          ])),
          const SizedBox(height: 6),
          Expanded(child: Row(children: [
            Expanded(child: _healthCard(
              asset: 'assets/images/icon_health_spo2.png', title: l10n.spo2,
              value: '95%', compact: compact,
            )),
            const SizedBox(width: 6),
            Expanded(child: _healthCard(
              asset: 'assets/images/icon_health_fall.png', title: l10n.is_fall,
              value: '없음', compact: compact,
            )),
          ])),
        ])),
        const SizedBox(height: 5),
        const Text('건강 상태 화면 테스트 (실제 감지 아님)',
            style: TextStyle(fontSize: 11, color: Color(0xFF555C69))),
        const SizedBox(height: 2),
        SizedBox(height: 34, child: Row(children: [
          for (final item in const [
            ('주의', 'notice'), ('경고', 'warning'),
            ('위험', 'danger'), ('응급', 'emergency'),
          ]) ...[
            Expanded(child: ElevatedButton(
              onPressed: () => showAlert(item.$2),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F7FD),
                foregroundColor: const Color(0xFF315D97),
                elevation: 0,
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Color(0xFFB7C3D7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(item.$1, style: const TextStyle(fontSize: 14)),
            )),
            if (item.$2 != 'emergency') const SizedBox(width: 5),
          ],
        ])),
        SizedBox(height: compact ? 27 : 31,
          child: TextButton(
            onPressed: onHealthHistoryPressed,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('나의 상태 이력 보기', style: TextStyle(fontSize: 13)),
          ),
        ),
        SizedBox(height: actionHeight, child: Row(children: [
          Expanded(child: _actionButton(
            label: isResting ? '근무 재개' : l10n.work_rest,
            onPressed: onRestPressed, filled: true,
          )),
          const SizedBox(width: 8),
          Expanded(child: _actionButton(
            label: l10n.work_end, onPressed: onButtonPressed, filled: false,
          )),
        ])),
        const SizedBox(height: 7),
        SizedBox(height: actionHeight, child: Row(children: [
          Expanded(child: _actionButton(
            label: l10n.work_history, onPressed: onHistoryPressed, filled: false,
          )),
          const SizedBox(width: 8),
          Expanded(child: _actionButton(
            label: l10n.connect_pic, onPressed: onContactPressed,
            filled: true, color: const Color(0xFFD91C2B), icon: Icons.phone_forwarded,
          )),
        ])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final textScaleLarge = MediaQuery.textScalerOf(context).scale(16) > 18;
      // 구정민 : 수정 - 일반 휴대폰은 스크롤 없이 표시하고, 매우 작은 화면·큰 접근성 글꼴에서만 스크롤을 허용한다.
      final minHeight = textScaleLarge ? 600.0 : 485.0;
      if (constraints.maxHeight < minHeight) {
        return SingleChildScrollView(
          child: SizedBox(height: minHeight,
              child: _buildBody(context, minHeight)),
        );
      }
      return _buildBody(context, constraints.maxHeight);
    });
  }
}
