import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'api_client.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final String title = message.notification?.title ?? message.data['baslik'] ?? message.data['title'] ?? 'SOBO Society';
    final String body = message.notification?.body ?? message.data['mesaj'] ?? message.data['body'] ?? message.data['message'] ?? '';

    if (title.isNotEmpty || body.isNotEmpty) {
      final int id = int.tryParse(message.data['id']?.toString() ?? '') ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      await NotificationService().showNotification(
        id: id,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('[FCM Background] Error: $e');
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService().initialize();
      await NotificationService().registerDeviceToken();
      await NotificationService().checkAndShowPendingNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('[Workmanager] Background task error: $e');
      }
    }
    return Future.value(true);
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Timer? _pollingTimer;

  static const String channelId = 'high_importance_channel';
  static const String channelName = 'SOBO Bildirimleri';
  static const String channelDesc = 'SOBO Society stüdyo, ders ve kişiye özel duyuru bildirimleri';

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('[NotificationService] Notification tapped: ${response.payload}');
        }
      },
    );

    // Create High Importance Channel for Android (Lock screen, Heads-up banner, Vibration)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        showBadge: true,
      );

      await androidImplementation.createNotificationChannel(channel);
    }

    // Firebase Cloud Messaging (FCM) Integration
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final String title = message.notification?.title ?? message.data['baslik'] ?? message.data['title'] ?? 'SOBO Society';
        final String body = message.notification?.body ?? message.data['mesaj'] ?? message.data['body'] ?? message.data['message'] ?? '';
        final int id = int.tryParse(message.data['id']?.toString() ?? '') ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

        if (title.isNotEmpty || body.isNotEmpty) {
          showNotification(
            id: id,
            title: title,
            body: body,
            payload: jsonEncode(message.data),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Setup error: $e');
      }
    }

    _initialized = true;

    // Register device token if logged in
    await registerDeviceToken();

    // Workmanager OS-level background execution setup
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      await Workmanager().registerPeriodicTask(
        'sobo_bg_notif_sync_task',
        'sobo_notification_sync_task',
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[Workmanager] Init error: $e');
      }
    }
    
    // Immediate check + start periodic active poller
    checkAndShowPendingNotifications();
    startNotificationPoller();
  }

  /// Register FCM Device Token with backend for logged in user
  Future<void> registerDeviceToken() async {
    try {
      final authToken = await StorageService.getToken();
      if (authToken == null || authToken.isEmpty) return;

      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      
      final fcmToken = await messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await ApiClient.post('/my/device-token', <String, dynamic>{
          'device_token': fcmToken,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        });
        if (kDebugMode) {
          print('[FCM] Successfully registered device token: $fcmToken');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Device token registration error: $e');
      }
    }
  }

  /// Show native system notification with lock screen & status bar visibility
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'SOBO Bildirimi',
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      visibility: NotificationVisibility.public, // Lock screen visible!
      category: AndroidNotificationCategory.reminder,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Active polling service when app is open or in background
  void startNotificationPoller() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await checkAndShowPendingNotifications();
    });
  }

  Future<void> checkAndShowPendingNotifications() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return;

      // Ensure device token is registered
      registerDeviceToken();

      final prefs = await SharedPreferences.getInstance();
      final List<String> shownIds = prefs.getStringList('shown_notif_ids') ?? <String>[];

      // Call API for member notifications
      final dynamic res = await ApiClient.get('/my/notifications');
      List notifs = [];
      if (res is List) {
        notifs = res;
      } else if (res is Map && res['data'] is List) {
        notifs = res['data'];
      }

      for (var item in notifs) {
        if (item is Map) {
          final int id = item['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final String idStr = id.toString();

          // STRICT SINGLE-SHOW RULE: Never trigger notification if ID was already shown natively!
          if (!shownIds.contains(idStr)) {
            final String title = item['baslik'] ?? item['title'] ?? 'SOBO Society';
            final String body = item['mesaj'] ?? item['body'] ?? item['message'] ?? '';

            if (body.isNotEmpty || title.isNotEmpty) {
              await showNotification(
                id: id,
                title: title,
                body: body,
                payload: jsonEncode(item),
              );

              // Mark as shown locally
              shownIds.add(idStr);
              await prefs.setStringList('shown_notif_ids', shownIds);

              // Mark as read on backend
              try {
                await ApiClient.post('/my/notifications/$id/read', <String, dynamic>{});
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NotificationService] Poll error: $e');
      }
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
