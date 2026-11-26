import 'package:aws402_flutter/l10n/app_localizations.dart';
import 'package:aws402_flutter/screens/alert_screen.dart';
import 'package:aws402_flutter/widgets/main_widget.dart';
import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:aws402_flutter/widgets/person_in_charge_contact.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dialer = MethodChannel('health_guard/phone');
const _contacts = [
  {'name': '첫 번째 담당자', 'phone': '010-1234-5678'},
  {'name': '두 번째 담당자', 'phone': '051-123-4567'},
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('사용자가 선택한 담당자 번호를 전화 앱에 전달한다', (tester) async {
    final calls = await _openContacts(tester, _contacts);

    expect(find.text('담당자 연결'), findsOneWidget);
    expect(find.text('010-1234-5678'), findsOneWidget);
    expect(find.text('051-123-4567'), findsOneWidget);
    expect(calls, isEmpty);

    final dialButtons = find.widgetWithText(TextButton, '전화');
    expect(dialButtons, findsNWidgets(2));
    await tester.tap(dialButtons.last);
    await tester.pumpAndSettle();

    expect(calls.single.method, 'openDialer');
    expect(calls.single.arguments, '0511234567');
  });

  testWidgets('119 화면은 테스트 대상과 번호를 표시하고 선택한 담당자에게 연결한다', (tester) async {
    final calls = await _openContacts(
      tester,
      _contacts,
      emergencyPreview: true,
    );

    expect(find.text('119 연결 테스트'), findsOneWidget);
    expect(find.textContaining('등록된 담당자 번호로 연결합니다.'), findsOneWidget);
    expect(find.text('010-1234-5678'), findsOneWidget);
    expect(calls, isEmpty);

    await tester.tap(find.text('첫 번째 담당자'));
    await tester.pumpAndSettle();

    expect(calls.single.method, 'openDialer');
    expect(calls.single.arguments, '01012345678');
  });

  testWidgets('메인 화면의 담당자 연락 버튼이 연결 콜백을 실행한다', (tester) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MainWidget(
            onButtonPressed: () {},
            onHealthCheckPressed: () {},
            onWorkHistoryPressed: () {},
            onHealthHistoryPressed: () {},
            onContactPressed: () => requests++,
            healthCheckCompleted: false,
            watchConnected: false,
          ),
        ),
      ),
    );
    final contact = find.widgetWithIcon(FilledButton, Icons.phone_forwarded);
    await tester.ensureVisible(contact);
    await tester.tap(contact);
    expect(requests, 1);
  });

  for (final type in ['notice', 'warning', 'danger', 'emergency']) {
    testWidgets('등급에 맞는 연락 버튼을 배치한다: $type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AlertScreen(
            type: type,
            measurement: const {
              'bpm': 100,
              'skinTemperature': 37.5,
              'spo2': 95,
            },
          ),
        ),
      );
      if (type == 'notice') {
        expect(find.text('닫기'), findsOneWidget);
        expect(find.text('담당자 연결'), findsNothing);
        expect(find.text('119'), findsNothing);
        return;
      }

      if (type == 'warning') {
        expect(find.text('휴식하기'), findsOneWidget);
        expect(find.text('담당자 연결'), findsNothing);
        expect(find.text('119'), findsNothing);
        return;
      }
      final contact = find.widgetWithText(FilledButton, '담당자 연결');
      final emergency = find.widgetWithText(OutlinedButton, '119');
      expect(tester.widget<FilledButton>(contact).onPressed, isNotNull);
      if (type == 'danger') {
        expect(emergency, findsNothing);
        return;
      }
      expect(tester.widget<OutlinedButton>(emergency).onPressed, isNotNull);
      expect(
        tester.getTopLeft(contact).dy,
        lessThan(tester.getTopLeft(emergency).dy),
      );
      expect(find.text('테스트 연결 · 담당자 번호 사용'), findsOneWidget);
    });
  }

  testWidgets('등록된 담당자 목록이 비어 있으면 안내를 표시한다', (tester) async {
    final calls = await _openContacts(tester, []);

    expect(find.text('등록된 담당자 연락처가 없습니다.'), findsOneWidget);
    expect(calls, isEmpty);
  });
}

Future<List<MethodCall>> _openContacts(
  WidgetTester tester,
  List<Map<String, String>> contacts, {
  bool emergencyPreview = false,
}) async {
  SharedPreferences.setMockInitialValues({'mobile_session': 'contact-token'});
  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'http://contact.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        requests.add(request);
        final Object? data = switch (request.path) {
          '/api/mobile/auth/me' => {'userIdx': 1, 'name': '테스트 근로자'},
          '/api/mobile/contacts/pic' => contacts,
          _ => null,
        };
        handler.resolve(
          Response<dynamic>(
            requestOptions: request,
            statusCode: data == null ? 404 : 200,
            data: data,
          ),
        );
      },
    ),
  );

  final originalApi = MobileApi.instance;
  final api = MobileApi(dio: dio);
  MobileApi.instance = api;
  addTearDown(() {
    MobileApi.instance = originalApi;
    dio.close();
  });
  expect(await tester.runAsync(api.restoreSession), isTrue);

  final calls = <MethodCall>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_dialer, (call) async {
    calls.add(call);
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(_dialer, null));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPersonInChargeContact(
              context,
              emergencyPreview: emergencyPreview,
            ),
            child: const Text('연락처 열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('연락처 열기'));
  await tester.pumpAndSettle();

  final contactRequest = requests.singleWhere(
    (request) => request.path == '/api/mobile/contacts/pic',
  );
  expect(contactRequest.method, 'GET');
  expect(contactRequest.headers['X-Mobile-Session'], 'contact-token');
  return calls;
}
