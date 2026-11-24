// [인수인계] 홈 기상 관측값의 요약을 표시한다. 표시 자체에서 외부 기상 API를 호출하지 않는다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

import '../mobile/home_dashboard.dart';

// 구정민 : 수정 - 기온·강수형태는 상단바만 표시한다. 이 패널은 DB의 4개 관측 수치만 보여준다.
// 구정민 : Home 준비 화면과 Work 근무·휴식 화면이 동일한 날씨 정보를 공유한다.
class WeatherSummaryWidget extends StatelessWidget {
  final WeatherSnapshot? weather;
  final bool loading;
  final bool failed;
  final bool compact;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const WeatherSummaryWidget({
    super.key,
    this.weather,
    this.loading = false,
    this.failed = false,
    this.compact = false,
  });

  /// [인수인계] 기상 항목의 이름과 표시 수치를 배치한다.
  Widget _metric(String title, String value) {
    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF81510B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 19,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAD5D00),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    final data = weather;

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E7),
        border: Border.all(color: const Color(0xFFE8A43B), width: 1.3),
        borderRadius: BorderRadius.circular(9),
      ),
      child: data == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loading
                      ? '날씨 불러오는 중'
                      : failed
                      ? '날씨 조회 실패'
                      : '날씨 자료 없음',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFAD5D00),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loading
                      ? '서버 응답 대기'
                      : failed
                      ? '서버 연결 확인 필요'
                      : 'WEATHER 테이블에 관측값이 없습니다',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF555E68),
                  ),
                ),
              ],
            )
          // 구정민 : 수정 - 기존의 중복 기온·관측 시각·지역 미확인·강풍 유의 안내를 출력하지 않는다.
          : Row(
              children: [
                _metric('강수량', data.rainfallText),
                _metric('습도', data.humidityText),
                _metric('풍향', data.windDirectionText),
                _metric('풍속', data.windSpeedText),
              ],
            ),
    );
  }
}
