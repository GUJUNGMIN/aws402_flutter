import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/work_state.dart';

// 구정민 : HomeScreen에서 열리며, WorkState에 임시 저장한 일자별 근무 기록을 표시한다.
class WorkHistoryScreen extends StatelessWidget {
  final List<WorkHistoryEntry> entries;
  final DateTime? currentStart;

  const WorkHistoryScreen({
    super.key,
    required this.entries,
    this.currentStart,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final timeFormat = DateFormat('HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('나의 근무 이력')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('앱 실행 중 임시 기록 · DB 미연동',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            if (currentStart != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.work_history, color: Colors.blue),
                  title: Text(dateFormat.format(currentStart!)),
                  subtitle: Text('근무 진행 중 · 시작 ${timeFormat.format(currentStart!)}'),
                  trailing: const Text('진행 중'),
                ),
              ),
            if (entries.isEmpty && currentStart == null)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(child: Text('등록된 근무 이력이 없습니다.')),
              ),
            for (final item in entries)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(dateFormat.format(item.startedAt)),
                  subtitle: Text(
                    '공원 환경 정비 (테스트)\n'
                    '${timeFormat.format(item.startedAt)} ~ ${timeFormat.format(item.endedAt)}\n'
                    '휴식 ${item.restDuration.inMinutes}분 · 실근무 ${item.workingDuration.inMinutes}분',
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
