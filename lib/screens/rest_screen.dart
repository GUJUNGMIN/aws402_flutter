import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 구정민 : HomeScreen의 휴식 버튼에서 열리며, 근무 재개 여부를 호출 화면에 반환한다.
class RestScreen extends StatelessWidget {
  final DateTime startedAt;

  const RestScreen({super.key, required this.startedAt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('휴식 중')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 구정민 : 수정 - 별도 휴식 화면에서도 근무 화면과 같은 휴식 중 상태를 명확히 표시한다.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D7),
                  border: Border.all(color: const Color(0xFFDE9D3F)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(children: [
                  Icon(Icons.hotel, color: Color(0xFFAE6400)),
                  SizedBox(width: 8),
                  Text('휴식 중', style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold,
                    color: Color(0xFF945500),
                  )),
                ]),
              ),
              const Spacer(),
              const Icon(Icons.chair_alt, color: Colors.blue, size: 88),
              const SizedBox(height: 24),
              const Text('휴식 중입니다',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('휴식 시작: ${DateFormat('HH:mm:ss').format(startedAt)}',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 14),
              const Text('현재 화면은 테스트 모드이며 서버에 저장되지 않습니다.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
