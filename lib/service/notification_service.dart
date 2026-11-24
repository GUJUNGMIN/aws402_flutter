import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'health_guard_fcm_channel',
    '헬스가드 알림',
    importance: Importance.max
  );

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android:AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(settings: initSettings);

    final token = await _messaging.getToken();
    final fid = await getFirebaseInstallationId();
    debugPrint('Firebase Installation ID: $fid');
    debugPrint('Firebase FCM Token : $token');



    FirebaseMessaging.onMessage.listen((RemoteMessage message){
      final notification = message.notification;
      final android = message.notification?.android;

      if(notification != null && android != null){
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails:
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.max,
                priority: Priority.high,
              )
            )
        );
      }
    });
  }

  static Future<String> getFirebaseInstallationId() async {
    try {
      final String id = await FirebaseInstallations.instance.getId();
      return id;
    } catch (e) {
      debugPrint('FID 가져오기 실패: $e');
      return '';
    }
  }
}