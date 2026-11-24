// [인수인계] Flutter와 /api/mobile 사이 HTTP·세션·오류 변환을 담당한다. 서버 저장값을 응답받고 GPS는 전송 직전 선택적으로 첨부한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_permission_service.dart';
import 'home_dashboard.dart';
import 'history_summaries.dart';
import '../models/health_measurement.dart';

// 구정민 : 수정 - 실제 워치 측정값과 선택 GPS를 모바일 서버에 전송한다.
// 구정민 : 안드로이드 에뮬레이터의 10.0.2.2는 개발 PC를 의미한다. 실기기는 --dart-define으로 변경한다.
class MobileApi {
  static MobileApi instance = MobileApi();
  static const baseUrl = String.fromEnvironment(
    'MOBILE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final Dio _dio;
  String? _token;
  int? _userIdx;
  String? _name;

  /// [인수인계] 필요한 의존성/콜백/초기값으로 MobileApi 객체를 구성한다.
  MobileApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 5),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String get displayName => _name ?? '';
  int? get userIdx => _userIdx;

  /// [인수인계] 현재 토큰을 X-Mobile-Session 헤더에 넣는다.
  Options get _authorized => Options(headers: {'X-Mobile-Session': _token});

  // 구정민 : 앱 재실행 시 저장된 임시 세션을 서버로 검증한다. 서버가 재시작하면 로그인 화면으로 돌아간다.
  /// [인수인계] 로컬 토큰을 /auth/me로 검증한다. 만료·서버 재시작·통신 실패 시 로컬 세션을 지운다.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('mobile_session');
    if (!isAuthenticated) return false;
    try {
      final data = await _dio.get<Map<String, dynamic>>(
        '/api/mobile/auth/me',
        options: _authorized,
      );
      _userIdx = (data.data?['userIdx'] as num).toInt();
      _name = data.data?['name']?.toString();
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  /// [인수인계] 로그인 성공 응답의 토큰을 저장하고 사용자 이름/번호를 메모리에 반영한다.
  Future<void> login(String id, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/auth/login',
      data: {'id': id, 'password': password},
    );
    final data = response.data!;
    _token = data['token'].toString();
    _userIdx = (data['userIdx'] as num).toInt();
    _name = data['name'].toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobile_session', _token!);
  }

  /// [인수인계] 앱 메모리와 SharedPreferences의 토큰을 지운다. 이 함수 자체는 서버 logout API를 호출하지 않는다.
  Future<void> clearSession() async {
    _token = null;
    _userIdx = null;
    _name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobile_session');
  }

  // 구정민 : 수정 - 로그인 후 이름/배정 일자리/저장된 기상 관측값을 서버 DB에서 조회한다.
  /// [인수인계] 인증 헤더로 홈 데이터를 조회하고 표시 모델로 변환한다.
  Future<HomeDashboard> homeDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/home',
      options: _authorized,
    );
    return HomeDashboard.fromJson(response.data!);
  }

  /// [인수인계] 인증 없이 서버의 ping 응답을 확인한다.
  Future<Map<String, dynamic>> ping() async =>
      (await _dio.get<Map<String, dynamic>>('/api/mobile/ping')).data!;

  /// [인수인계] 서버가 DB를 읽을 수 있는지 진단 응답을 받는다.
  Future<Map<String, dynamic>> dbCheck() async =>
      (await _dio.get<Map<String, dynamic>>('/api/mobile/db-check')).data!;

  // 구정민 : 낡은 값을 재전송하거나 내부 큐에 저장하지 않는다. 호출될 때마다 새 수치를 입력받는다.
  // 구정민 : GPS 권한/센서 오류가 있어도 건강값 저장은 계속하도록 위치를 선택 항목으로 보낸다.
  /// [인수인계] 현재 휴대폰 GPS를 선택 첨부해 /measurements에 POST한다. 수치와 판정은 이 함수에서 만들어 내지 않는다.
  Future<Map<String, dynamic>> sendMeasurement(HealthMeasurement value) async {
    final position = await LocationPermissionService.tryCurrentPosition();
    final body = value.toJson();
    if (position != null) {
      body['latitude'] = position.latitude;
      body['longitude'] = position.longitude;
    }
    return (await _dio.post<Map<String, dynamic>>(
      '/api/mobile/measurements',
      data: body,
      options: _authorized,
    )).data!;
  }

  /// [인수인계] START/REST/RESUME/END 의사를 서버에 전달한다. 성공 후의 화면 전환은 호출 화면이 처리한다.
  Future<Map<String, dynamic>> workEvent(String event) async =>
      (await _dio.post<Map<String, dynamic>>(
        '/api/mobile/work/events',
        data: {'event': event},
        options: _authorized,
      )).data!;

  /// [인수인계] 서버의 현재 근무 단계를 조회한다. 워치 연결 상태를 복원하는 API는 아니다.
  Future<Map<String, dynamic>> workStatus() async =>
      (await _dio.get<Map<String, dynamic>>(
        '/api/mobile/work/status',
        options: _authorized,
      )).data!;

  /// [인수인계] 지원되는 이력 종류와 날짜를 검증해 조회한다. 건강 이력의 시각은 서버 수신 기준이다.
  Future<List<Map<String, dynamic>>> history(String kind, DateTime day) async {
    if (!const ['work', 'health', 'alerts'].contains(kind)) {
      throw ArgumentError('지원하지 않는 이력 조회: $kind');
    }
    final date =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final response = await _dio.get<List<dynamic>>(
      '/api/mobile/history/$kind',
      options: _authorized,
      queryParameters: {'date': date},
    );
    return (response.data ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  // 구정민 : 수정 - 로그인 근로자의 선택 기간 근무 요약을 서버에서 직접 집계한다.
  /// [인수인계] 기간별 근무 요약을 서버에서 집계해 받는다.
  Future<List<WorkSummary>> workSummaries(DateTime from, DateTime to) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/mobile/history/work-summary',
      options: _authorized,
      queryParameters: _rangeQuery(from, to),
    );
    return (response.data ?? const [])
        .map(
          (row) => WorkSummary.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  // 구정민 : 수정 - N/W/D 알림 발생 횟수와 날짜별 상세 발생 시각을 함께 조회한다.
  /// [인수인계] 날짜별 상태 변경 알림의 건수와 발생 시각을 받는다.
  Future<List<DailyStatusSummary>> statusSummaries(
    DateTime from,
    DateTime to,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/mobile/history/status-summary',
      options: _authorized,
      queryParameters: _rangeQuery(from, to),
    );
    return (response.data ?? const [])
        .map(
          (row) => DailyStatusSummary.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  /// [인수인계] 조회 시작/종료일을 서버의 from/to 쿼리로 변환한다.
  Map<String, String> _rangeQuery(DateTime from, DateTime to) => {
    'from': _formatDate(from),
    'to': _formatDate(to),
  };

  /// [인수인계] 날짜를 서버가 요구하는 yyyy-MM-dd 형식으로 만든다.
  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// [인수인계] HTTP 인증/입력/서버 오류를 화면 안내 문구로 바꾼다. 여기서 재전송을 예약하지 않는다.
  static String errorMessage(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 401) return '로그인이 만료되었거나 계정이 올바르지 않습니다.';
      final payload = error.response?.data;
      if (code != null &&
          code >= 400 &&
          code < 500 &&
          payload is Map &&
          payload['message'] is String &&
          (payload['message'] as String).isNotEmpty) {
        return payload['message'] as String;
      }
      if (code == 409) return '서버 기준값(HEALTH_BASE), 배정 정보, 근무 상태를 확인해 주세요.';
      if (code != null) return '서버 처리 실패 (HTTP $code)';
      return '서버에 연결하지 못했습니다. 다음 신규 워치 측정값을 수신하면 전송합니다.';
    }
    return '요청에 실패했습니다: $error';
  }
}
