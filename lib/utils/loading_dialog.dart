// [인수인계] 처리 중 표시와 닫기 동작을 공통화한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

class LoadingDialog {
  // 로딩 다이얼로그 띄우기
  /// [인수인계] 처리 중 다이얼로그를 표시한다.
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
                  const CircularProgressIndicator(color: Colors.white),
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
  /// [인수인계] 표시 중인 처리 다이얼로그를 닫는다.
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
