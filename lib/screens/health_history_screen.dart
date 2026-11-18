import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/work_state.dart';

// 구정민 : HomeScreen에서 열리며, 위험 테스트 버튼으로 발생한 이벤트 이력을 조회한다.
class HealthHistoryScreen extends StatelessWidget {
  final List<HealthHistoryEntry> entries;

  const HealthHistoryScreen({super.key, required this.entries});

  Color _color(String grade) {
    switch (grade) {
      case '주의': return Colors.amber.shade800;
      case '경고': return Colors.deepOrange;
      case '위험': return Colors.red;
      case '응급': return Colors.red.shade900;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy.MM.dd HH:mm:ss');
    return Scaffold(
      appBar: AppBar(title: const Text('나의 상태 이력')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('건강 상태 테스트 이력 · 실제 측정/DB 미연동',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(child: Text('발생한 상태 이력이 없습니다.')),
              ),
            for (final item in entries)
              Card(
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: _color(item.grade)),
                  title: Text('${item.grade} · ${formatter.format(item.occurredAt)}'),
                  subtitle: Text('${item.reason}\n조치: ${item.action}'),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
