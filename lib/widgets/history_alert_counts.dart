// [인수인계] 서버가 집계한 주의·경고·위험·응급 발생 건수를 공통 모양으로 표시한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

// 구정민 : 근무 카드와 날짜별 상태 카드의 주의/경고/위험/응급 발생 횟수 UI.
// 정상 측정은 특이사항 횟수에서 제외한다.
class HistoryAlertCounts extends StatelessWidget {
  final int notice;
  final int warning;
  final int danger;
  final int emergency;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HistoryAlertCounts({
    super.key,
    required this.notice,
    required this.warning,
    required this.danger,
    this.emergency = 0,
  });

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    if (notice + warning + danger + emergency == 0) {
      return const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF388E58), size: 17),
          SizedBox(width: 6),
          Text(
            '특이사항 없음',
            style: TextStyle(fontSize: 13, color: Color(0xFF388E58)),
          ),
        ],
      );
    }

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Row(
      children: [
        Expanded(
          child: _count(
            '주의',
            notice,
            const Color(0xFF936000),
            const Color(0xFFFFF6DF),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _count(
            '경고',
            warning,
            const Color(0xFFC45718),
            const Color(0xFFFFEEE2),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _count(
            '위험',
            danger,
            const Color(0xFFC92835),
            const Color(0xFFFFEBEE),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _count(
            '응급',
            emergency,
            const Color(0xFF8B1228),
            const Color(0xFFFFE3EB),
          ),
        ),
      ],
    );
  }

  /// [인수인계] 서버에서 받은 한 등급의 발생 건수를 표시한다.
  Widget _count(String title, int count, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count회',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
