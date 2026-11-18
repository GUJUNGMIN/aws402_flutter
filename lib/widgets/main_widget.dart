import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/color_extension.dart';
import '../utils/toast.dart';

class MainWidget extends StatelessWidget{
  final VoidCallback onButtonPressed;
  // 구정민 : 수정 - HomeScreen에서 받은 건강 측정·이력 화면 이동 콜백을 버튼에 연결한다.
  final VoidCallback onHealthCheckPressed;
  final VoidCallback onWorkHistoryPressed;
  final VoidCallback onHealthHistoryPressed;
  final bool healthCheckCompleted;
  final bool watchConnected;

  const MainWidget({
    super.key,
    required this.onButtonPressed,
    required this.onHealthCheckPressed,
    required this.onWorkHistoryPressed,
    required this.onHealthHistoryPressed,
    required this.healthCheckCompleted,
    required this.watchConnected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double fontSize = double.tryParse(l10n.font_size) ?? 20.0;
    double fontSizeSub = double.tryParse(l10n.font_size_sub) ?? 15.0;
    double fontSizeBig = double.tryParse(l10n.font_size_big) ?? 30.0;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                  color: l10n.color_orange.toColor(),
                  width: 2.0
              ),
              color: l10n.color_yellow_light.toColor()
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '오늘 날씨 (폭염주의보)',
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: l10n.color_orange.toColor()
                    ),
                  ),
                  Spacer(),
                  Text(
                    '99℃',
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: l10n.color_orange.toColor()
                    ),
                  )
                ],
              ),
              Divider(
                color: l10n.color_orange.toColor(),
                thickness: 1.0,
              ),
              Row(
                children: [
                  Text(
                    '09시 99º',
                    style: TextStyle(
                      fontSize: fontSizeSub,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '12시 34º',
                    style: TextStyle(
                        fontSize: fontSizeSub,
                        fontWeight: FontWeight.bold,
                        color: l10n.color_orange.toColor()
                    ),
                  ),
                  Spacer(),
                  Text(
                    '15시 35º',
                    style: TextStyle(
                      fontSize: fontSizeSub,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],

              ),

            ],
          ),
        ),
        const SizedBox(height: 8),
        // 구정민 : 수정 - 위치 항목은 제거하고 워치 연결·건강 측정 상태만 날씨 아래에 표시한다.
        InkWell(
          onTap: onHealthCheckPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              border: Border.all(color: const Color(0xFFC5CFDB)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(children: [
              const Icon(Icons.watch, size: 19),
              const SizedBox(width: 5),
              const Text('워치 연결', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              CircleAvatar(radius: 5, backgroundColor:
                  watchConnected ? Colors.green : Colors.red),
              const SizedBox(width: 5),
              Text(watchConnected ? '연결' : '해제',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('건강 ${healthCheckCompleted ? '완료' : '미측정'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF394C65))),
            ]),
          ),
        ),
        Expanded(
            child: Center(
              child: Text(
                '오늘도 안전하게 근무하세요!',
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold
                ),
              ),
            )
        ),
        // 구정민 : 수정 - 건강 측정 및 두 이력 버튼을 추가하여 HomeScreen 콜백으로 연결한다.
        OutlinedButton.icon(
          onPressed: onHealthCheckPressed,
          icon: const Icon(Icons.watch),
          // 구정민 : 수정 - 이미 연결된 워치는 재연결 없이 다음 근무의 건강 측정만 진행한다.
          label: Text(healthCheckCompleted
              ? '워치·건강 측정 완료 (테스트)'
              : (watchConnected ? '건강 측정 테스트' : '워치 연결·건강 측정 테스트')),
        ),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onWorkHistoryPressed,
                child: const Text('나의 근무 이력'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: onHealthHistoryPressed,
                child: const Text('나의 상태 이력'),
              ),
            ),
          ],
        ),
        const Text('화면 테스트 · 서버/워치 미연동',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: l10n.color_green.toColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
            ),
            onPressed: onButtonPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 40.0,
                ),
                Text(
                  l10n.work_start,
                  style: TextStyle(
                      fontSize: fontSizeBig,
                      fontWeight: FontWeight.bold
                  ),
                )
              ],
            )
        ),
        SizedBox(height: 10.0,),
        FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: l10n.color_red.toColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
            ),
            onPressed: (){
              Toast.showToast(context, '화면 테스트: 담당자에게 실제 연락하지 않습니다.');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_forwarded,
                  size: 30.0,
                ),
                SizedBox(width: 5.0,),
                Text(
                  l10n.connect_pic,
                  style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold
                  ),
                )
              ],
            )

        ),
      ],
    );
  }
}