// [인수인계] 서버 판정 알림에서 휴식 또는 등록 담당자 연락처를 선택할 수 있다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

import '../widgets/person_in_charge_contact.dart';

// 구정민 : 수정 - 워치 측정의 서버 판정 결과로 열리는 공통 경보 화면이다.
// 등급별 색상과 조치를 구분한다. 휴식 결과는 HomeScreen에 반환하고 전화 연결은 이 화면에서 연다.
// 구정민 : 서버가 판정한 건강 수치를 기존 등급별 UI에 전달하는 명명 라우트 인수.
class AlertRouteArguments {
  final String type;
  final Map<String, dynamic>? measurement;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const AlertRouteArguments({required this.type, this.measurement});
}

class AlertScreen extends StatelessWidget {
  final String type;
  final Map<String, dynamic>? measurement;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const AlertScreen({super.key, required this.type, this.measurement});

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
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
    // 구정민 : 수정 - 고정된 잘못된 경고 원인 대신 서버에 저장한 워치 수치를 표시한다.
    final String cause = measurement == null
        ? '서버 측정 정보 없음'
        : measurement!['fallDetected'] == true
        ? '낙상 신호'
        : '심박수 ${measurement!['bpm']} bpm · 피부온도 '
              '${measurement!['skinTemperature']}℃ · 산소포화도 ${measurement!['spo2']}%';
    final String guidance = isNotice
        ? '잠시 휴식하고 수분을 섭취하세요.'
        : isWarning
        ? '작업을 중단하고 담당자에게 알리세요.'
        : isDanger
        ? '담당자에게 즉시 도움을 요청하세요.'
        : '긴급 도움 요청이 필요한 상황입니다.';

    final String primaryLabel = isNotice
        ? '휴식 시작'
        : isWarning || isDanger
        ? '담당자 연결'
        : '긴급 SOS 준비 중';
    const String secondaryResult = 'ack';

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, limits) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: limits.maxHeight - 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              '건강 안전 알림',
                              style: TextStyle(
                                fontSize: 19,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              measurement == null ? '측정 정보 없음' : '서버 판정',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Icon(icon, color: accent, size: 67),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 구정민 : 수정 - 단색 배경 대신 색상 테두리의 원인 카드로 등급과 측정 예시를 강조한다.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '[서버 저장된 측정값 · 서버 판정]',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cause,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222A36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        guidance,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF444956),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          measurement == null
                              ? '측정 정보가 없습니다.'
                              : '워치 측정값에 대한 서버 판정입니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF616773),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 55,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isWarning || isDanger
                                ? () => showPersonInChargeContact(context)
                                : isNotice && measurement != null
                                ? () => Navigator.pop(context, 'rest')
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: Text(
                              primaryLabel,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (isWarning || isDanger) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => showPersonInChargeContact(
                                context,
                                emergencyPreview: true,
                              ),
                              icon: const Icon(Icons.phone_outlined),
                              label: const Text(
                                '119',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                backgroundColor: Colors.white,
                                side: BorderSide(color: accent, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '테스트 연결 · 담당자 번호 사용',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF616773),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton(
                            // 알림 화면을 닫고 이전 화면으로 돌아간다.
                            onPressed: () =>
                                Navigator.pop(context, secondaryResult),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: accent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: Text(
                              '닫기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
