// [인수인계] 휴대폰 위치 권한 요청과 현재 좌표 조회를 분리한다. 위치가 없어도 건강 측정 저장은 계속할 수 있다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:geolocator/geolocator.dart';

// 구정민 : STEP 2 GPS 권한 승인·설정 이동과 위치 획득을 분리한 모바일 전용 서비스.
// 구정민 : 수정 - 앱 첫 화면과 명시적 버튼에서 권한을 요청하며 건강 측정의 필수 조건으로 사용하지 않는다.
enum LocationAccessStatus {
  checking,
  denied,
  permanentlyDenied,
  serviceDisabled,
  granted,
  error,
}

class LocationPermissionService {
  LocationPermissionService._();

  // 구정민 : 수정 - 이미 승인되었거나 영구 거부된 권한은 다시 요청하지 않는다.
  /// [인수인계] 앱 시작 시 필요한 권한만 요청한다. 이미 허용됐거나 영구 거부된 권한을 반복 요청하지 않는다.
  static Future<LocationAccessStatus> requestOnAppStart() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        return await requestAccess();
      }
      return await checkStatus();
    } catch (_) {
      return LocationAccessStatus.error;
    }
  }

  /// [인수인계] 위치 서비스 활성 여부와 현재 OS 권한을 확인한다.
  static Future<LocationAccessStatus> checkStatus() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return LocationAccessStatus.permanentlyDenied;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return LocationAccessStatus.denied;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccessStatus.serviceDisabled;
      }
      return LocationAccessStatus.granted;
    } catch (_) {
      return LocationAccessStatus.error;
    }
  }

  // 구정민 : 수정 - 앱 시작 시 또는 GPS 권한 승인 버튼에서 Android 시스템 권한 대화상자를 요청한다.
  /// [인수인계] 사용자 동작에 따라 OS 위치 권한을 요청하고 결과 상태를 반환한다.
  static Future<LocationAccessStatus> requestAccess() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return LocationAccessStatus.permanentlyDenied;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return LocationAccessStatus.denied;
      }
      return await checkStatus();
    } catch (_) {
      return LocationAccessStatus.error;
    }
  }

  /// [인수인계] 영구 거부 등으로 직접 변경이 필요할 때 OS 앱 설정을 연다.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// [인수인계] OS 위치 서비스 설정 화면을 연다.
  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  // 구정민 : 실제 위치 취득 시 재차 권한을 요청하지 않는다. 미승인/센서 오류는 null 처리한다.
  // 구정민 : 서버는 위치가 없어도 건강 수치를 저장하며, 과거 GPS 정보를 재사용하지 않는다.
  /// [인수인계] 새 권한 팝업 없이 허용된 경우에만 좌표를 조회한다. 실패/거부는 null로 반환한다.
  static Future<Position?> tryCurrentPosition() async {
    if (await checkStatus() != LocationAccessStatus.granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
