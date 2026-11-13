import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../router/app_routes.dart';
import '../utils/color_extension.dart';
import '../utils/toast.dart';

class MainWidget extends StatelessWidget{
  final VoidCallback onButtonPressed;
  const MainWidget({super.key, required this.onButtonPressed});

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
                  width: 3.0
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
              Toast.showToast(context, '담당자 연결');
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