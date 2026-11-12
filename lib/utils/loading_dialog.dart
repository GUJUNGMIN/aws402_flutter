import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingDialog {
  // 로딩 다이얼로그 띄우기
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 바깥 영역 터치 시 닫힘 방지
      barrierColor: Colors.black.withOpacity(0.5), // 배경 어둡게 처리
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // 안드로이드 물리/제스처 뒤로가기 버튼 방지
          child: Dialog(
            backgroundColor: Colors.transparent, // 기본 다이얼로그 배경 투명화
            elevation: 0, // 그림자 제거
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 로딩 다이얼로그 닫기
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}