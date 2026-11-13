import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../utils/color_extension.dart';

class AlertScreen extends StatefulWidget{
  final String type;
  const AlertScreen({super.key, required this.type});

  @override
  State<StatefulWidget> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen>{
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double fontSize = double.tryParse(l10n.font_size) ?? 20.0;
    double fontSizeSub = double.tryParse(l10n.font_size_sub) ?? 15.0;
    double fontSizeBig = double.tryParse(l10n.font_size_big) ?? 30.0;
    double fontSizeMega = double.tryParse(l10n.font_size_mega) ?? 40.0;

    Color bgColor;
    Color mainColor;
    String alertText;
    IconData icon;
    switch(widget.type.toLowerCase()){
      case 'notice' :
        bgColor = l10n.color_notice_bg.toColor();
        mainColor = l10n.color_alert_text.toColor();
        alertText = l10n.notice;
        icon = Icons.warning_amber_rounded;
        break;
      case 'warning' :
        bgColor = l10n.color_warning_bg.toColor();
        mainColor = l10n.color_alert_text.toColor();
        alertText = l10n.warning;
        icon = Icons.warning_rounded;
        break;
      case 'danger' :
        bgColor = l10n.color_danger_bg.toColor();
        mainColor = Colors.white;
        alertText = l10n.danger;
        icon = Icons.dangerous_rounded;
        break;
      default :
        bgColor = Colors.white;
        mainColor = l10n.color_alert_text.toColor();
        alertText = l10n.alarm;
        icon = Icons.alarm;
        break;
    }
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(10.0),
        color: bgColor,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_alert,
                    color: mainColor,
                  ),
                  Text(
                    l10n.appTitle,
                    style: TextStyle(
                      color: mainColor,
                      fontSize: fontSize
                    ),
                  ),
                  Spacer(),
                  Text(
                    DateFormat('HH:mm:ss').format(DateTime.now()),
                    style: TextStyle(
                        color: mainColor,
                        fontSize: fontSize
                    ),
                  ),
                ],
              ),

              Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(40, 43, 33, 0)
                        ),
                        padding: EdgeInsets.all(20.0),
                        child:  Icon(
                          icon,
                          size: 80,
                          color: mainColor,
                        ),
                      ),
                      SizedBox(height: 10.0,),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40.0),
                          border: Border.all(
                              color: mainColor,
                              width: 3.0
                          ),
                        ),
                        padding: EdgeInsets.only(top: 5.0, bottom: 5.0, left: 20.0, right: 20.0),
                        child: Text(
                          alertText,
                          style: TextStyle(
                            fontSize: fontSizeMega,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                          ),
                        ),
                      ),
                      Text(
                        '[발생 원인]',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: mainColor,
                        ),
                      ),
                      Text(
                        '심박수 120 bpm',
                        style: TextStyle(
                          fontSize: fontSizeBig,
                          fontWeight: FontWeight.bold,
                          color: mainColor

                        ),
                      ),
                      Text(
                        '(기준 초과)',
                        style: TextStyle(
                          fontSize: fontSizeBig,
                          fontWeight: FontWeight.bold,
                          color: mainColor
                        ),
                      ),
                      SizedBox(height: 10.0,),
                      Text(
                        '체감온도 34℃ 노출중',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: mainColor
                        ),
                      ),
                      Text(
                        '그늘에서 수분을 섭취하세요',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: mainColor
                        ),
                      )

                    ],
                  )
              ),
              FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    backgroundColor: mainColor,
                    padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                  ),
                  onPressed: (){
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 5.0,),
                      Text(
                        '${l10n.rest_start} (${l10n.pause})',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: bgColor
                        ),
                      )
                    ],
                  )

              ),
              SizedBox(height: 10.0,),
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    side: BorderSide(
                      color: mainColor
                    )
                  ),
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 5.0,),
                      Text(
                        l10n.close,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: mainColor
                        ),
                      )
                    ],
                  )

              ),
            ],
          )
        )


        ,
      )
    );
  }
}