// [인수인계] 이력 조회 기간 입력과 검색 콜백을 제공한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 구정민 : '나의 근무 이력'과 '나의 상태 이력'에 공통으로 사용하는 From~To 날짜 조회 UI.
class HistoryRangeFilter extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final ValueChanged<DateTime> onFromChanged;
  final ValueChanged<DateTime> onToChanged;
  final VoidCallback onSearch;
  final bool loading;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HistoryRangeFilter({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSearch,
    this.loading = false,
  });

  /// [인수인계] 허용 범위 안에서 조회 날짜를 선택해 부모 화면 콜백에 전달한다.
  Future<void> _pick(BuildContext context, bool startDate) async {
    // 구정민 : 서버와 동일하게 최대 366일(양 끝 포함) 범위만 선택할 수 있도록 제한한다.
    final earliest = to.subtract(const Duration(days: 365));
    final firstFrom = earliest.isAfter(DateTime(2020))
        ? earliest
        : DateTime(2020);
    final latest = from.add(const Duration(days: 365));
    final lastTo = latest.isBefore(DateTime.now()) ? latest : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ? from : to,
      firstDate: startDate ? firstFrom : from,
      lastDate: startDate ? to : lastTo,
      helpText: startDate ? '시작일(From) 선택' : '종료일(To) 선택',
    );
    if (picked == null) return;
    if (startDate) {
      onFromChanged(picked);
    } else {
      onToChanged(picked);
    }
  }

  /// [인수인계] 현재 조회 기간의 안내 문구를 구성한다.
  String _periodHint() {
    final today = DateTime.now();
    final isDefault =
        DateUtils.isSameDay(to, today) &&
        DateUtils.isSameDay(from, today.subtract(const Duration(days: 7)));
    return isDefault ? '기본 조회 기간 · 오늘부터 7일 전까지' : '선택 기간 · 최대 366일';
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _dateField(context, 'From', from, true)),
            const Padding(
              padding: EdgeInsets.only(top: 21, left: 5, right: 5),
              child: Text('~', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: _dateField(context, 'To', to, false)),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                _periodHint(),
                style: const TextStyle(fontSize: 11, color: Color(0xFF707987)),
              ),
            ),
            FilledButton.icon(
              onPressed: loading ? null : onSearch,
              icon: const Icon(Icons.search, size: 17),
              label: const Text('조회'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                minimumSize: const Size(78, 36),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// [인수인계] 조회 날짜 선택 입력을 구성한다.
  Widget _dateField(
    BuildContext context,
    String label,
    DateTime value,
    bool isFrom,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF596579)),
      ),
      const SizedBox(height: 4),
      OutlinedButton(
        onPressed: loading ? null : () => _pick(context, isFrom),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
          minimumSize: const Size(0, 40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                DateFormat('yyyy.MM.dd').format(value),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
