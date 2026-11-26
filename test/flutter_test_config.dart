import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
// Firebase가 제공하는 테스트 전용 네이티브 초기화 대역이다.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제 Firebase/알림 서버에 접근하지 않고 기존 홈 화면 테스트를 실행한다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // 명시적으로 실행한 격리 서버 계약 테스트만 실제 HTTP를 사용한다.
  if (const String.fromEnvironment('WATCH_CONTRACT_BASE_URL').isNotEmpty) {
    HttpOverrides.global = null;
  }
  setupFirebaseCoreMocks();
  await Firebase.initializeApp();
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_messaging'),
    (call) async {
      if (call.method == 'Messaging#getToken') {
        return {'token': 'test-only-token'};
      }
      return <String, int>{
        'authorizationStatus': 1,
        'alert': 1,
        'announcement': 0,
        'badge': 1,
        'carPlay': 0,
        'criticalAlert': 0,
        'lockScreen': 1,
        'notificationCenter': 1,
        'showPreviews': 1,
        'timeSensitive': 0,
        'sound': 1,
      };
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (call) async => call.method == 'initialize' ? true : null,
  );
  messenger.setMockDecodedMessageHandler<Object?>(
    const BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.firebase_app_installations_platform_interface.FirebaseAppInstallationsHostApi.getId',
      StandardMessageCodec(),
    ),
    (message) async => <Object?>['test-only-installation'],
  );
  await testMain();
}
