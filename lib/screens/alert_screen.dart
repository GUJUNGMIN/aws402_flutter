import 'package:flutter/material.dart';

// 구정민 : 수정 - HomeScreen의 상태 테스트 버튼에서 열리는 공통 경보 화면이다.
// 등급별 색상·발생 원인·조치 버튼을 구분하고, 결과는 Navigator.pop()으로 HomeScreen에 반환한다.
class AlertScreen extends StatelessWidget {
  final String type;

  const AlertScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isNotice = type == 'notice';
    final isWarning = type == 'warning';
    final isDanger = type == 'danger';

    final Color accent = isNotice
        ? const Color(0xFFDA8700)
        : isWarning
            ? const Color(0xFFDD6312)
            : isDanger
                ? const Color(0xFFD62432)
                : const Color(0xFF9B1422);
    final Color background = isNotice
        ? const Color(0xFFFFF6DD)
        : isWarning
            ? const Color(0xFFFFF1E6)
            : isDanger
                ? const Color(0xFFFFEEF0)
                : const Color(0xFFFFE7EA);
    final IconData icon = isNotice
        ? Icons.warning_amber_rounded
        : isWarning
            ? Icons.notification_important_rounded
            : isDanger
                ? Icons.warning_rounded
                : Icons.sos_rounded;
    final String title = isNotice
        ? '주의!'
        : isWarning
            ? '경고!'
            : isDanger
                ? '위험 발생!'
                : '위급 상황!';
    final String cause = isNotice
        ? '심박수 118 bpm (기준 초과)'
        : isWarning
            ? '피부온도 38.9℃ (고온 예시)'
            : isDanger
                ? '낙상 감지 (쓰러짐 발생 예시)'
                : '낙상 후 움직임 없음 (예시)';
    final String guidance = isNotice
        ? '잠시 휴식하고 수분을 섭취하세요.'
        : isWarning
            ? '작업을 중단하고 담당자에게 알리세요.'
            : isDanger
                ? '담당자에게 즉시 도움을 요청하세요.'
                : '긴급 도움 요청이 필요한 상황입니다.';

    final String primaryLabel = isNotice
        ? '휴식 시작 (테스트)'
        : isWarning || isDanger
            ? '담당자에게 알림 (테스트)'
            : '긴급 SOS (테스트)';
    final String primaryResult = isNotice
        ? 'rest'
        : isWarning || isDanger
            ? 'notify'
            : 'sos';
    final String secondaryLabel = isNotice || isWarning
        ? '닫기'
        : isDanger
            ? '요청 취소 (괜찮아요)'
            : '119 긴급 신고 (테스트)';
    final String secondaryResult = type == 'emergency' ? 'call119' : 'ack';

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, limits) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: limits.maxHeight - 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(children: [
                      const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 27),
                      const SizedBox(width: 9),
                      const Expanded(child: Text('건강 안전 알림',
                          style: TextStyle(fontSize: 19, color: Colors.white,
                              fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('UI 테스트',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(children: [
                      Icon(icon, color: accent, size: 67),
                      const SizedBox(height: 3),
                      Text(title, style: TextStyle(fontSize: 34,
                          fontWeight: FontWeight.w900, color: accent)),
                    ]),
                  ),
                  // 구정민 : 수정 - 단색 배경 대신 색상 테두리의 원인 카드로 등급과 측정 예시를 강조한다.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: accent, width: 2),
                    ),
                    child: Column(children: [
                      Text('[발생 원인 이벤트 · 예시]',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                              color: accent)),
                      const SizedBox(height: 8),
                      Text(cause,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20,
                              fontWeight: FontWeight.bold, color: Color(0xFF222A36))),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(guidance,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w500, color: Color(0xFF444956))),
                  ),
                  Column(children: [
                    const Text('화면 테스트 전용 · 실제 판정/담당자 연락/119 신고 없음',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF616773))),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 55,
                      width: double.infinity,
                      child: FilledButton(
                        // 구정민 : 기존 결과 코드(rest/notify/sos)를 유지해 HomeScreen 조치 처리와 연결한다.
                        onPressed: () => Navigator.pop(context, primaryResult),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                        child: Text(primaryLabel,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton(
                        // 구정민 : 닫기·취소·119 테스트 결과를 HomeScreen으로 반환하며 실제 신고는 하지 않는다.
                        onPressed: () => Navigator.pop(context, secondaryResult),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: accent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                        child: Text(secondaryLabel,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
