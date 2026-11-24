// [인수인계] 짧은 사용자 안내 메시지 표시를 공통화한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/cupertino.dart';
import 'package:toastification/toastification.dart';

class Toast {
  const Toast._();

  /// [인수인계] 짧은 결과 안내 메시지를 표시한다.
  static void showToast(BuildContext context, String title) {
    toastification.show(
      style: ToastificationStyle.simple,
      context: context,
      title: Text(title),
      autoCloseDuration: Duration(seconds: 1),
      alignment: Alignment.bottomCenter,
      closeOnClick: false,
      dragToClose: false,
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
    );
  }
}
