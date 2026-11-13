import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/color_extension.dart';
import '../utils/toast.dart';

class TopbarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double fontSize = double.tryParse(l10n.font_size) ?? 20.0;
    double fontSizeSub = double.tryParse(l10n.font_size_sub) ?? 15.0;
    double fontSizeBig = double.tryParse(l10n.font_size_big) ?? 30.0;
    return Container(
      decoration: BoxDecoration(color: l10n.color_appbar.toColor()),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Toast.showToast(context, '내 정보 화면');
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://i.namu.wiki/i/rcKQd_FcumdnxIyIPYkZo1B2IA2MZmfnc_HlpQUGksSQFjXiF-mAFjjxEcNk3AGKRwkz3Fho8TgEM-doCb8vMtZmM2neQAb6kRAc127qSGPU4EMaAEN7wlxm3sJZFoMN1hdeUozx8nugzdOA2xt-QQ.webp',
                      ),
                      radius: 30.0,
                    ),
                    SizedBox(width: 10.0),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이원재 ${l10n.sir}',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '공원 환경 정비',
                          style: TextStyle(
                            fontSize: fontSizeSub,
                            color: Colors.white,
                          ),
                        ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Image(
                      image: AssetImage('assets/images/icon-sun.png'),
                      width: 30,
                    ),
                    Text(
                      '99℃ 폭염',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
