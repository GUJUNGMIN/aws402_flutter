// [인수인계] HomeDashboard와 근무 상태를 받아 사용자·진행 일자리·기상을 표시한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../mobile/home_dashboard.dart';
import '../mobile/mobile_api.dart';
import '../models/work_state.dart';
import '../utils/color_extension.dart';
import '../utils/toast.dart';

class TopbarWidget extends StatelessWidget {
  final HomeDashboard? dashboard;
  final bool loading;
  final bool failed;
  final WorkPhase workPhase;
  final VoidCallback? onProfilePressed;

  // 구정민 : 수정 - 근무 상태는 HomeScreen에서 전달받아 배정 정보의 조기 노출을 막는다.
  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const TopbarWidget({
    super.key,
    this.dashboard,
    this.loading = false,
    this.failed = false,
    this.workPhase = WorkPhase.ready,
    this.onProfilePressed,
  });

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double fontSize = double.tryParse(l10n.font_size) ?? 20.0;
    double fontSizeSub = double.tryParse(l10n.font_size_sub) ?? 15.0;
    // 구정민 : 수정 - 기존 이름/일자리/99도 날씨를 서버 응답 값으로만 표시한다.
    final name = dashboard?.name.isNotEmpty == true
        ? dashboard!.name
        : MobileApi.instance.displayName;
    // 구정민 : 수정 - 근무 전·종료 후에는 DB에 배정이 존재해도 일자리명을 표시하지 않는다.
    // 구정민 : 근무·휴식 중에는 서버가 WORK_LIST로 확인한 실제 진행 일자리만 표시한다.
    final onShift = workPhase != WorkPhase.ready;
    final job = !onShift
        ? '근무 대기 중'
        : loading
        ? '근무 일자리 확인 중'
        : failed
        ? '근무 일자리 조회 실패'
        : dashboard?.hasJob == true
        ? (dashboard!.jobTitle ?? '일자리 정보 없음')
        : '진행 중인 일자리 정보 없음';
    final weather = dashboard?.weather;
    final temp = weather?.temperatureText ?? '—℃';
    // 구정민 : 수정 - 기온 아래에는 강수형태만 표기한다. 자체 강풍 안내·관측 문구는 이곳에 표시하지 않는다.
    final condition = weather == null
        ? (loading ? '불러오는 중' : (failed ? '조회 실패' : '날씨 없음'))
        : weather.condition;

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Container(
      decoration: BoxDecoration(color: l10n.color_appbar.toColor()),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap:
                      onProfilePressed ??
                      () {
                        Toast.showToast(context, '내 정보 화면');
                      },
                  child: Row(
                    children: [
                      // 구정민 : 수정 - 외부 프로필 이미지를 유지하고 403 등 로딩 실패 시에만 기본 아이콘을 표시한다.
                      ClipOval(
                        child: Image.network(
                          'https://i.namu.wiki/i/rcKQd_FcumdnxIyIPYkZo1B2IA2MZmfnc_HlpQUGksSQFjXiF-mAFjjxEcNk3AGKRwkz3Fho8TgEM-doCb8vMtZmM2neQAb6kRAc127qSGPU4EMaAEN7wlxm3sJZFoMN1hdeUozx8nugzdOA2xt-QQ.webp',
                          width: 60.0,
                          height: 60.0,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 60.0,
                                height: 60.0,
                                color: Colors.white24,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 34.0,
                                ),
                              ),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${name.isEmpty ? '사용자' : name} ${l10n.sir}',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              job,
                              style: TextStyle(
                                fontSize: fontSizeSub,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 128.0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: l10n.color_orange.toColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    const Icon(Icons.thermostat, color: Colors.white, size: 35),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 구정민 : 수정 - 상단바 기온·상태를 키우고 좁은 화면에서는 자동 축소한다.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              temp,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            condition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
