import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/color_extension.dart';

class WorkWidget extends StatelessWidget{
  final VoidCallback onButtonPressed;
  final void Function(String type) showAlert;
  const WorkWidget({super.key, required this.onButtonPressed, required this.showAlert});

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
              width: 3.0,
            ),
            color: l10n.color_yellow_light.toColor(),
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
                      color: l10n.color_orange.toColor(),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '99℃',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: l10n.color_orange.toColor(),
                    ),
                  ),
                ],
              ),
              Divider(color: l10n.color_orange.toColor(), thickness: 1.0),
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
                      color: l10n.color_orange.toColor(),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '15시 35º',
                    style: TextStyle(
                      fontSize: fontSizeSub,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20.0),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  spacing: 10.0,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Colors.grey,
                              width: 3.0,
                            ),
                            color: Colors.black12
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.bpm,
                              style: TextStyle(
                                  fontSize: fontSize
                              ),
                            ),
                            Text(
                              '72 bpm',
                              style: TextStyle(
                                  fontSize: fontSizeBig,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              '정상',
                              style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: l10n.color_green.toColor()
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Colors.grey,
                              width: 3.0,
                            ),
                            color: Colors.black12
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.temperature,
                              style: TextStyle(
                                  fontSize: fontSize
                              ),
                            ),
                            Text(
                              '36.5 ℃',
                              style: TextStyle(
                                  fontSize: fontSizeBig,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              '정상',
                              style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: l10n.color_green.toColor()
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.0,),
              Expanded(
                child: Row(
                  spacing: 10.0,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Colors.grey,
                              width: 3.0,
                            ),
                            color: Colors.black12
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.spo2,
                              style: TextStyle(
                                  fontSize: fontSize
                              ),
                            ),
                            Text(
                              '95%',
                              style: TextStyle(
                                  fontSize: fontSizeBig,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              '정상',
                              style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: l10n.color_green.toColor()
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Colors.grey,
                              width: 3.0,
                            ),
                            color: Colors.black12
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.is_fall,
                              style: TextStyle(
                                  fontSize: fontSize
                              ),
                            ),
                            Text(
                              '없음',
                              style: TextStyle(
                                  fontSize: fontSizeBig,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              '정상',
                              style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: l10n.color_green.toColor()
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.0,)
            ],
          ),
        ),
        Text('알림창 테스트용'),
        Row(
          children: [
            ElevatedButton(
              onPressed: (){
                showAlert('notice');
              },
              child: Text('주의'),
            ),
            ElevatedButton(
              onPressed: (){
                showAlert('warning');
              },
              child: Text('경고'),
            ),
            ElevatedButton(
              onPressed: (){
                showAlert('danger');
              },
              child: Text('위험'),
            )
          ],
        ),
        Row(
          spacing: 10.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                  backgroundColor: l10n.color_blue.toColor(),
                ),
                onPressed: () {},
                child: Text(
                  l10n.work_rest,
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
            Expanded(
              child: OutlinedButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                ),
                onPressed: onButtonPressed,
                child: Text(
                  l10n.work_end,
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.0),
        Row(
          spacing: 10.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: OutlinedButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                ),
                onPressed: () {},
                child: Text(
                  l10n.work_history,
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                  backgroundColor: l10n.color_red.toColor(),
                ),
                onPressed: (){},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_forwarded, size: 30.0),
                    SizedBox(width: 5.0,),
                    Text(
                      l10n.connect_pic,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}