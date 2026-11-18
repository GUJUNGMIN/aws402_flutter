import 'package:flutter/material.dart';

import '../models/work_state.dart';

// 구정민 : MainWidget의 워치 연결 버튼에서 열리며, 기기 통신 없는 최초 건강 측정 화면을 확인한다.
class HealthCheckScreen extends StatefulWidget {
  final WorkState workState;
  const HealthCheckScreen({super.key, required this.workState});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  @override
  Widget build(BuildContext context) {
    final state = widget.workState;
    return Scaffold(
      appBar: AppBar(title: const Text('워치 연결 · 건강 측정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.watch, size: 72, color: Colors.blue),
            const SizedBox(height: 12),
            const Text('시뮬레이션 화면',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('실제 갤럭시 워치·서버에는 연결하지 않습니다.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // 구정민 : 수정 - 화면에서 워치 연결과 건강 측정만 확인한다.
            _statusTile('워치 연결', state.watchConnected ? '연결 완료 (테스트)' : '연결 전'),
            _statusTile('최초 건강 측정',
                state.initialHealthChecked ? '측정 완료 (가상값)' : '측정 전'),
            if (state.initialHealthChecked) ...[
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('심박수 72 bpm · 정상', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('피부온도 36.5℃ · 정상', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('산소포화도 95% · 정상', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('※ 가상 측정값이며 의료 판정 결과가 아닙니다.',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // 구정민 : 수정 - 워치 연결·해제 테스트 시 HomeScreen의 상태 점이 함께 변경된다.
            FilledButton.icon(
              onPressed: () => setState(() {
                if (state.watchConnected) {
                  state.disconnectWatchForDemo();
                } else {
                  state.connectWatchForDemo();
                }
              }),
              icon: Icon(state.watchConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected),
              label: Text(state.watchConnected ? '워치 연결 해제 테스트' : '워치 연결 테스트'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: state.watchConnected
                  ? () => setState(() { state.checkHealthForDemo(); })
                  : null,
              icon: const Icon(Icons.monitor_heart),
              label: const Text('건강 측정 테스트'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('메인으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTile(String label, String status) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
