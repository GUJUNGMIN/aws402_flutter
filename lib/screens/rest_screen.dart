// [인수인계] 휴식 중 화면과 경과 표시를 담당한다. 재개 의사를 홈에 반환하고 서버 이벤트 처리 흐름과 연결한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 구정민 : HomeScreen의 휴식 버튼에서 열리며, 근무 재개 여부를 호출 화면에 반환한다.
class RestScreen extends StatelessWidget {
  final DateTime startedAt;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const RestScreen({super.key, required this.startedAt});

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Scaffold(
      appBar: AppBar(title: const Text('휴식 중')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 구정민 : 수정 - 별도 휴식 화면에서도 근무 화면과 같은 휴식 중 상태를 명확히 표시한다.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D7),
                  border: Border.all(color: const Color(0xFFDE9D3F)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hotel, color: Color(0xFFAE6400)),
                    SizedBox(width: 8),
                    Text(
                      '휴식 중',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF945500),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.chair_alt, color: Colors.blue, size: 88),
              const SizedBox(height: 24),
              const Text(
                '휴식 중입니다',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '휴식 시작: ${DateFormat('HH:mm:ss').format(startedAt)}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 14),
              const Text(
                '휴식 및 재개 이벤트는 서버에 저장됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  // 구정민 : true를 반환하면 HomeScreen이 휴식시간을 합산하고 근무 화면으로 복귀한다.
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('근무 재개', style: TextStyle(fontSize: 22)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
