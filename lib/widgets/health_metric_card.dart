// [인수인계] 근무 전·중 공통 건강 항목을 표시한다. 아이콘/제목과 수치/상태 묶음을 중앙에 배치하며 판정은 계산하지 않는다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

// 구정민 : 수정 - 근무 전·중 공통 카드. 왼쪽 항목과 오른쪽 수치·판정을 나누어 글자를 크게 표시한다.
class HealthMetricCard extends StatelessWidget {
  final String asset;
  final String title;
  final String value;
  final String status;
  final Color statusColor;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HealthMetricCard({
    super.key,
    required this.asset,
    required this.title,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB2BAC4), width: 1.5),
      ),
      // 구정민 : 수정 - 항목과 결과를 한 묶음으로 중앙에 모으고 넓은 카드에서도 벌어지지 않게 한다.
      child: Center(
        child: ConstrainedBox(
          key: const ValueKey('health-card-content'),
          constraints: const BoxConstraints(maxWidth: 180),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(asset, width: 24, height: 24),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 15, height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 구정민 : 수정 - 카드 전체를 축소하지 않고 긴 수치만 가로 폭에 맞춘다.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2835),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
