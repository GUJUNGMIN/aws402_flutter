import 'package:flutter/cupertino.dart';
import 'package:toastification/toastification.dart';

class Toast {
  const Toast._();

  static void showToast(BuildContext context, String title){
    toastification.show(
      style: ToastificationStyle.simple,
      context: context,
      title: Text(title),
      autoCloseDuration: Duration(seconds: 1),
      alignment: Alignment.bottomCenter,
      closeOnClick: false,
      dragToClose: false,
      closeButton: const ToastCloseButton(
        showType: CloseButtonShowType.none,
      ),
    );
  }
}