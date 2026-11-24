// [인수인계] 화면 색상 변환을 돕는 공통 확장이다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

extension HexColorExtension on String {
  /// [인수인계] 색상 문자열을 Flutter Color로 변환한다.
  Color toColor() {
    final buffer = StringBuffer();
    if (length == 6 || length == 7) buffer.write('ff');
    buffer.write(replaceFirst('#', ''));

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
