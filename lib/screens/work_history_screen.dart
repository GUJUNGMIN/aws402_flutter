// [인수인계] 기간별 근무 집계를 조회해 일자리·시간·상태 발생 횟수를 표시한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../mobile/history_summaries.dart';
import '../mobile/mobile_api.dart';
import '../models/work_state.dart';
import '../widgets/history_alert_counts.dart';
import '../widgets/history_range_filter.dart';

// 구정민 : 수정 - 최신 근무 시작일 순 카드 목록과 From~To 7일 기본 조회를 적용한다.
// 구정민 : 기존 화면 라우트 인수는 다른 Flutter 코드 호환을 위해 삭제하지 않는다.
class WorkHistoryScreen extends StatefulWidget {
  final List<WorkHistoryEntry> entries;
  final DateTime? currentStart;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const WorkHistoryScreen({
    super.key,
    required this.entries,
    this.currentStart,
  });

  @override
  /// [인수인계] 이 화면 인스턴스에 대응하는 State 객체를 만든다.
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  late DateTime _from;
  late DateTime _to;
  List<WorkSummary> _items = [];
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  @override
  /// [인수인계] 화면 최초 생성 시 필요한 구독·조회·타이머를 초기화한다. dispose와 함께 확인한다.
  void initState() {
    super.initState();
    final today = DateTime.now();
    _to = DateTime(today.year, today.month, today.day);
    _from = _to.subtract(const Duration(days: 7));
    _load();
  }

  /// [인수인계] 조회 조건으로 이력을 다시 읽는다. 늦게 온 이전 요청 결과가 현재 화면을 덮지 않게 한다.
  Future<void> _load() async {
    final int request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await MobileApi.instance.workSummaries(_from, _to);
      if (!mounted || request != _requestId) return;
      // 구정민 : 서버 정렬이 바뀌어도 UI에서는 근무 시작 시각 내림차순을 보장한다.
      rows.sort((a, b) {
        final byTime = b.startedAt.compareTo(a.startedAt);
        return byTime == 0 ? b.workId.compareTo(a.workId) : byTime;
      });
      setState(() {
        _items = rows;
      });
    } catch (error) {
      if (mounted && request == _requestId) {
        setState(() {
          _items = [];
          _error = MobileApi.errorMessage(error);
        });
      }
    } finally {
      if (mounted && request == _requestId) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// [인수인계] 경과 시간을 화면 표시 문자열로 바꾼다.
  String _elapsed(int? minutes) {
    if (minutes == null) return '확인 불가';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m분';
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  /// [인수인계] 한 근무 세션의 시간/상태 집계 카드를 구성한다.
  Widget _workCard(WorkSummary item) {
    final start = DateFormat('yyyy.MM.dd HH:mm').format(item.startedAt);
    final end = item.endedAt == null
        ? (item.status == 'ONGOING' ? '진행 중' : '종료 기록 없음')
        : DateFormat('yyyy.MM.dd HH:mm').format(item.endedAt!);
    final statusLabel = item.status == 'COMPLETED'
        ? '완료'
        : item.status == 'ONGOING'
        ? '진행 중'
        : '종료 누락';

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 24,
                  color: Color(0xFF2768B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.jobTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF51637E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 17,
                  color: Color(0xFF6D7786),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.region,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF6D7786),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$start ~\n$end',
                    style: const TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 3,
              children: [
                Text(
                  '총 ${_elapsed(item.totalMinutes)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '휴식 ${_elapsed(item.restMinutes)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '실근무 ${_elapsed(item.workingMinutes)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              '건강상태 특이사항',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            HistoryAlertCounts(
              notice: item.noticeCount,
              warning: item.warningCount,
              danger: item.dangerCount,
            ),
          ],
        ),
      ),
    );
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('나의 근무 이력')),
    body: SafeArea(
      child: Column(
        children: [
          HistoryRangeFilter(
            from: _from,
            to: _to,
            loading: _loading,
            onFromChanged: (v) => setState(() {
              _from = v;
            }),
            onToChanged: (v) => setState(() {
              _to = v;
            }),
            onSearch: _load,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '조회 결과 ${_items.length}건',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text(
                  '근무 시작 최신순',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6D7786)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : _items.isEmpty
                ? const Center(child: Text('조회 기간에 근무 이력이 없습니다.'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _workCard(_items[index]),
                  ),
          ),
        ],
      ),
    ),
  );
}
