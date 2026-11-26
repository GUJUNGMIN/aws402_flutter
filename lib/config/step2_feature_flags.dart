// [인수인계] 표시 가능한 알림/낙상 기능을 한곳에서 제어한다. 숨긴 기능의 수신·화면 이동도 이 설정을 따른다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

// 구정민 : STEP 2의 UI 노출 정책. 숨김 기능의 기존 화면·라우트·서버 코드는 보존한다.
class Step2FeatureFlags {
  const Step2FeatureFlags._();

  // 응급 기준 판정 화면은 사용하고 낙상 센서 입력은 기존 정책을 유지한다.
  static const bool showEmergency = true;
  static const bool showFall = false;

  // 새 DB 코드 7005와 기존 E/EMERGENCY 이력을 함께 인식한다.
  /// [인수인계] 서버 등급이 응급 상태인지 확인한다.
  static bool isEmergencyStatus(String? value) {
    final status = value?.trim().toUpperCase();
    return status == 'EMERGENCY' ||
        status == 'E' ||
        status == '7005' ||
        status == '응급' ||
        status == '위급';
  }
}
