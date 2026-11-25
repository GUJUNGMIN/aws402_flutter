import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final code in [401, 503, null]) {
    test('세션 복원 시 401에서만 저장 토큰을 지운다: $code', () async {
      SharedPreferences.setMockInitialValues({'mobile_session': 'test-token'});
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.path, '/api/mobile/auth/me');
            handler.reject(
              DioException(
                requestOptions: request,
                response: code == null
                    ? null
                    : Response(requestOptions: request, statusCode: code),
                type: code == null
                    ? DioExceptionType.connectionError
                    : DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final api = MobileApi(dio: dio);
      expect(await api.restoreSession(), code != 401);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('mobile_session'),
        code == 401 ? null : 'test-token',
      );
    });
  }

  for (final accepted in [true, false]) {
    test('서버 로그아웃 확인 여부에 따라 저장 토큰을 처리한다: $accepted', () async {
      SharedPreferences.setMockInitialValues({'mobile_session': 'test-token'});
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.headers['X-Mobile-Session'], 'test-token');
            if (request.path.endsWith('/auth/me')) {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: request,
                  data: {'userIdx': 1, 'name': '검사 사용자'},
                ),
              );
              return;
            }
            expect(request.method, 'POST');
            expect(request.path, '/api/mobile/auth/logout');
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: request,
                data: {'loggedOut': accepted},
              ),
            );
          },
        ),
      );
      final api = MobileApi(dio: dio);
      expect(await api.restoreSession(), isTrue);
      if (accepted) {
        await api.logout();
      } else {
        await expectLater(api.logout(), throwsStateError);
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mobile_session'), accepted ? null : 'test-token');
      expect(api.isAuthenticated, !accepted);
    });
  }
}
