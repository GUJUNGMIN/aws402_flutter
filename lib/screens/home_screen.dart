
import 'package:aws402_flutter/utils/color_extension.dart';
import 'package:aws402_flutter/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../l10n/app_localizations.dart';


class HomeScreen extends StatelessWidget {
  final String title;

  const HomeScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double fontSize = double.tryParse(l10n.font_size) ?? 20.0;
    double fontSizeSub = double.tryParse(l10n.font_size_sub) ?? 15.0;
    double fontSizeBig = double.tryParse(l10n.font_size_big) ?? 30.0;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child:
        Container(
          decoration: BoxDecoration(
            color: l10n.color_appbar.toColor()
          ),
          child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child:  Row(
                  children: [
                    GestureDetector(
                      onTap: (){
                        Toast.showToast(context, '내 정보 화면');
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage('https://i.namu.wiki/i/rcKQd_FcumdnxIyIPYkZo1B2IA2MZmfnc_HlpQUGksSQFjXiF-mAFjjxEcNk3AGKRwkz3Fho8TgEM-doCb8vMtZmM2neQAb6kRAc127qSGPU4EMaAEN7wlxm3sJZFoMN1hdeUozx8nugzdOA2xt-QQ.webp'),
                            radius: 30.0,
                          ),
                          SizedBox(width: 10.0,),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '빌헬름 ${l10n.sir}',
                                style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white
                                ),
                              ),
                              Text(
                                '공원 환경 정비',
                                style: TextStyle(
                                    fontSize: fontSizeSub,
                                    color: Colors.white
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Container(
                      width: 150.0,
                      height: double.infinity,
                      decoration: BoxDecoration(
                          color: l10n.color_orange.toColor(),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      padding: EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Image(
                            image: AssetImage('assets/images/icon-sun.png'),
                          ),
                          Text(
                            '99℃ 폭염',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        // decoration: BoxDecoration(
        //   border: Border.all(
        //     color: Colors.blueGrey,
        //     width: 2.0
        //   ),
        // ),
        child: Column(
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
              ),
              onPressed: (){}, 
              child: Container(
                padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
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
                ),
              )
            ),
            SizedBox(height: 10.0,),
            FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: l10n.color_red.toColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: (){},
                child: Container(
                  padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.doorbell_outlined,
                        size: 30.0,
                      ),
                      Text(
                        l10n.emergency,
                        style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold
                        ),
                      )
                    ],
                  ),
                )

            ),
          ],
        ),
      ),
    );
  }
}









