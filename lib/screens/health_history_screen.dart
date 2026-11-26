// [인수인계] 기간별 상태 발생 집계와 날짜별 건강 저장값을 조회한다. 건강 이력 시간은 기존 DB의 서버 수신 시각이다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../mobile/history_summaries.dart';
import '../mobile/mobile_api.dart';
import '../models/work_state.dart';
import '../widgets/history_alert_counts.dart';
import '../widgets/history_range_filter.dart';

// 구정민 : 수정 - 상태 이력은 최근 7일 기본 조회, 날짜별 N/W/D 횟수, 행 아래 발생 시각 펼치기로 표시한다.
// 구정민 : 하단 건강 측정값 이력은 삭제하지 않고 선택 날짜의 기존 API로 조회한다.
class HealthHistoryScreen extends StatefulWidget {
  final List<HealthHistoryEntry> entries;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HealthHistoryScreen({super.key, required this.entries});
  @override
  /// [인수인계] 이 화면 인스턴스에 대응하는 State 객체를 만든다.
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  late DateTime _from;
  late DateTime _to;
  late DateTime _healthDay;
  List<DailyStatusSummary> _days = [];
  List<Map<String, dynamic>> _health = [];
  bool _loading = false;
  bool _healthLoading = false;
  bool _healthLoaded = false;
  String? _error;
  String? _healthError;
  int _requestId = 0;
  int _healthRequestId = 0;
  int _visibleHealthCount = 20;

  @override
  /// [인수인계] 화면 최초 생성 시 필요한 구독·조회·타이머를 초기화한다. dispose와 함께 확인한다.
  void initState() {
    super.initState();
    final today = DateTime.now();
    _to = DateTime(today.year, today.month, today.day);
    _from = _to.subtract(const Duration(days: 7));
    _healthDay = _to;
    _load();
  }

  /// [인수인계] 조회 조건으로 이력을 다시 읽는다. 늦게 온 이전 요청 결과가 현재 화면을 덮지 않게 한다.
  Future<void> _load() async {
    final int request = ++_requestId;
    // 구정민 : 기간이 바뀌면 이전에 진행 중인 날짜별 측정 요청 결과를 무효화한다.
    ++_healthRequestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await MobileApi.instance.statusSummaries(_from, _to);
      if (!mounted || request != _requestId) return;
      values.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _days = values;
        // 구정민 : 기간 변경 시 기존 건강 측정 날짜가 범위를 벗어나면 To로 맞춘다.
        if (_healthDay.isBefore(_from) || _healthDay.isAfter(_to)) {
          _healthDay = _to;
        }
        _health.clear();
        _healthLoaded = false;
        _visibleHealthCount = 20;
      });
    } catch (error) {
      if (mounted && request == _requestId) {
        setState(() {
          _days = [];
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

  // 구정민 : 상태 상세 이벤트는 이미 기간 API로 수신했으므로 날짜 터치 시 추가 통신 없이 펼친다.
  /// [인수인계] 서버 상태 코드를 표시용 한글 문구로 변환한다.
  String _statusName(String code) => switch (code) {
    'NOTICE' => '주의',
    'WARNING' => '경고',
    'DANGER' => '위험',
    'EMERGENCY' => '응급',
    _ => '상태',
  };

  /// [인수인계] 이미 결정된 서버 등급에 대응하는 표시 색상을 선택한다.
  Color _statusColor(String code) => switch (code) {
    'NOTICE' => const Color(0xFFAD7B00),
    'WARNING' => const Color(0xFFC45718),
    'DANGER' => const Color(0xFFC92835),
    'EMERGENCY' => const Color(0xFF8B1228),
    _ => Colors.grey,
  };

  /// [인수인계] 하루의 상태 발생 횟수와 펼칠 수 있는 발생 시각 목록을 구성한다.
  Widget _dayCard(DailyStatusSummary day) {
    final dateLabel = DateFormat('yyyy.MM.dd').format(day.date);
    final contents = <Widget>[
      const SizedBox(height: 5),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: HistoryAlertCounts(
          notice: day.noticeCount,
          warning: day.warningCount,
          danger: day.dangerCount,
          emergency: day.emergencyCount,
        ),
      ),
    ];
    if (day.totalCount == 0) {
      return Card(
        key: ValueKey('status-day-$dateLabel'),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 19,
                    color: Color(0xFF2768B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ...contents,
            ],
          ),
        ),
      );
    }

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ExpansionTile(
        key: ValueKey('status-day-$dateLabel'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        title: Text(
          dateLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        leading: const Icon(
          Icons.calendar_today_outlined,
          color: Color(0xFF2768B8),
        ),
        subtitle: Text(
          '총 ${day.totalCount}회 · 눌러서 발생 시간 확인',
          style: const TextStyle(fontSize: 11.5),
        ),
        children: [
          HistoryAlertCounts(
            notice: day.noticeCount,
            warning: day.warningCount,
            danger: day.dangerCount,
            emergency: day.emergencyCount,
          ),
          const Divider(height: 22),
          for (final event in day.events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: _statusColor(event.status),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${_statusName(event.status)} 발생',
                      style: TextStyle(
                        color: _statusColor(event.status),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm:ss').format(event.occurredAt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// [인수인계] 선택 날짜의 건강 저장 이력을 조회하고 로딩·오류·더보기 상태를 갱신한다.
  Future<void> _loadHealth() async {
    final int request = ++_healthRequestId;
    setState(() {
      _healthLoading = true;
      _healthError = null;
    });
    try {
      final values = await MobileApi.instance.history('health', _healthDay);
      if (!mounted || request != _healthRequestId) return;
      setState(() {
        _health = values;
        _healthLoaded = true;
        _visibleHealthCount = 20;
      });
    } catch (error) {
      if (mounted && request == _healthRequestId) {
        setState(() {
          _health = [];
          _healthLoaded = true;
          _healthError = MobileApi.errorMessage(error);
        });
      }
    } finally {
      if (mounted && request == _healthRequestId) {
        setState(() {
          _healthLoading = false;
        });
      }
    }
  }

  /// [인수인계] 건강 이력 조회일을 선택하고 해당 날짜의 저장값을 다시 읽는다.
  Future<void> _pickHealthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _healthDay,
      firstDate: _from,
      lastDate: _to,
      helpText: '건강 측정값 조회일 선택',
    );
    if (date == null || !mounted) return;
    setState(() {
      _healthDay = date;
      _healthLoaded = false;
      _visibleHealthCount = 20;
    });

    /// [인수인계] 선택 날짜의 건강 저장 이력을 조회하고 로딩·오류·더보기 상태를 갱신한다.
    await _loadHealth();
  }

  /// [인수인계] 날짜별 건강 이력과 수신 기준 시각을 화면에 표시한다.
  Widget _measurements() => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: ExpansionTile(
      title: const Text(
        '건강 측정값 이력',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        '심박수 · 피부온도 · 산소포화도 (날짜별 조회)',
        style: TextStyle(fontSize: 12),
      ),
      onExpansionChanged: (opened) {
        if (opened && !_healthLoaded) _loadHealth();
      },
      childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickHealthDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(DateFormat('yyyy.MM.dd').format(_healthDay)),
              ),
            ),
            IconButton(
              onPressed: _healthLoading ? null : _loadHealth,
              tooltip: '측정값 새로고침',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const Text(
          '서버 저장 측정값 · 시간은 서버 수신 기준',
          style: TextStyle(fontSize: 11, color: Color(0xFF6D7786)),
        ),
        if (_healthLoading)
          const Padding(
            padding: EdgeInsets.all(14),
            child: CircularProgressIndicator(),
          ),
        if (!_healthLoading && _healthError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_healthError!),
          ),
        if (!_healthLoading &&
            _healthLoaded &&
            _healthError == null &&
            _health.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('해당 날짜의 측정값이 없습니다.'),
          ),
        if (!_healthLoading && _healthError == null)
          for (final item in _health.take(_visibleHealthCount))
            ListTile(
              dense: true,
              leading: const Icon(Icons.monitor_heart, color: Colors.blue),
              title: Text(
                '심박 ${item['bpm']} · 피부온도 ${item['skinTemperature']}℃ · SpO₂ ${item['spo2']}%',
                style: const TextStyle(fontSize: 12.5),
              ),
              subtitle: Text(
                DateTime.tryParse('${item['measuredAt']}') == null
                    ? '${item['measuredAt']}'
                    : DateFormat('yyyy.MM.dd HH:mm:ss').format(
                        DateTime.parse('${item['measuredAt']}').toLocal(),
                      ),
                style: const TextStyle(fontSize: 11),
              ),
            ),
        if (!_healthLoading && _health.length > _visibleHealthCount)
          TextButton(
            onPressed: () => setState(() {
              _visibleHealthCount += 20;
            }),
            child: Text('더보기 (${_health.length - _visibleHealthCount}건 남음)'),
          ),
      ],
    ),
  );

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('나의 상태 이력')),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(
              children: [
                Text(
                  '일자별 주의 · 경고 · 위험 · 응급 발생 횟수',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                : ListView(
                    children: [
                      for (final day in _days) _dayCard(day),
                      _measurements(),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Text(
                          '알림 횟수는 상태 변경으로 저장된 발생 건수입니다. 1분 측정 횟수와 다릅니다.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6D7786),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}
