# 헬스가드 Flutter 워치 연동 준비본

최신 연동 경계와 팀원 작업 순서는 `WATCH_HANDOFF.txt`를 확인하세요.

이번 health-guard-server와 함께 사용하세요. 측정 ID/실제 측정 시각 및 실제 DB 저장값 응답 계약이 추가되었습니다.

실제 워치 통신 모듈은 팀원이 연결해야 합니다. 기본 실행은 미연결 상태이며 가상값을 생성하지 않습니다.

# aws402_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 담당자 연결과 119 테스트

같이 배포한 서버의 모바일 연락처 API가 기존 PIC.USER_IDX에 등록된 담당자 이름과 번호를 조회합니다. 앱 계정에 유효한 담당자 번호가 있어야 합니다.

- 메인 및 근무 화면의 담당자 연결에서 연락처를 선택하면 Android 전화 앱에 번호가 표시됩니다.
- 주의 화면에서는 휴식, 경고 및 위험 화면에서는 담당자 연결과 119가 표시됩니다.
- 119 버튼은 테스트 모드입니다. 확인 화면에서 실제로 사용할 담당자 이름과 번호를 표시하며, 통화는 Android 전화 앱에서 사용자가 직접 시작합니다.
- 검사 명령은 `flutter test test/person_in_charge_contact_test.dart`입니다.
