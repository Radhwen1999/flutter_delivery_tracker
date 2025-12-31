import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

class NotificationPayload {
  final String? title;
  final String? body;
  final String? payload;

  NotificationPayload({this.title, this.body, this.payload});
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  final _notificationController = BehaviorSubject<NotificationPayload?>();
  Stream<NotificationPayload?> get onNotificationTap => _notificationController.stream;

  static const String _channelId = 'delivery_tracker_channel';
  static const String _channelName = 'Delivery Updates';
  static const String _channelDescription = 'Notifications for delivery order updates';

  // Notification IDs
  static const int orderAssignedId = 1;
  static const int driverArrivedId = 2;
  static const int orderPickedUpId = 3;
  static const int orderDeliveredId = 4;
  static const int orderCancelledId = 5;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _requestAndroidPermission();
    }

    // Create notification channel for Android
    await _createNotificationChannel();

    debugPrint('🔔 Notification Service: Initialized');
  }

  Future<void> _requestAndroidPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    _notificationController.add(NotificationPayload(
      title: title,
      body: body,
      payload: payload,
    ));
  }

  void _onNotificationResponse(NotificationResponse response) {
    _notificationController.add(NotificationPayload(
      payload: response.payload,
    ));
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Background notification: ${response.payload}');
  }

  NotificationDetails _getNotificationDetails({
    bool playSound = true,
    bool vibrate = true,
    bool ongoing = false,
    String? largeIcon,
  }) {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound,
      enableVibration: vibrate,
      ongoing: ongoing,
      autoCancel: !ongoing,
      largeIcon: largeIcon != null 
          ? DrawableResourceAndroidBitmap(largeIcon)
          : null,
      styleInformation: const BigTextStyleInformation(''),
      category: AndroidNotificationCategory.status,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _getNotificationDetails(playSound: playSound, vibrate: vibrate),
      payload: payload,
    );
    
    debugPrint('🔔 Notification shown: $title');
  }

  Future<void> showOrderAssignedNotification({
    required String orderId,
    required String driverName,
    required String pickupAddress,
  }) async {
    await showNotification(
      id: orderAssignedId,
      title: '📦 New Order Assigned',
      body: '$driverName has been assigned to pick up from $pickupAddress',
      payload: 'order:$orderId',
    );
  }

  Future<void> showDriverArrivedNotification({
    required String orderId,
    required String driverName,
    required String location,
  }) async {
    await showNotification(
      id: driverArrivedId,
      title: '🚗 Driver Arrived',
      body: '$driverName has arrived at $location',
      payload: 'order:$orderId',
    );
  }

  Future<void> showOrderPickedUpNotification({
    required String orderId,
    required String driverName,
  }) async {
    await showNotification(
      id: orderPickedUpId,
      title: '📦 Order Picked Up',
      body: '$driverName has picked up the order and is on the way',
      payload: 'order:$orderId',
    );
  }

  Future<void> showOrderDeliveredNotification({
    required String orderId,
  }) async {
    await showNotification(
      id: orderDeliveredId,
      title: '✅ Order Delivered!',
      body: 'Your order has been successfully delivered',
      payload: 'order:$orderId',
    );
  }

  Future<void> showOrderCancelledNotification({
    required String orderId,
    String? reason,
  }) async {
    await showNotification(
      id: orderCancelledId,
      title: '❌ Order Cancelled',
      body: reason ?? 'Your order has been cancelled',
      payload: 'order:$orderId',
    );
  }

  Future<void> showOngoingTrackingNotification({
    required String orderId,
    required String driverName,
    required String eta,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: 50,
      category: AndroidNotificationCategory.navigation,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    await _notifications.show(
      100,
      '🚚 Tracking $driverName',
      'ETA: $eta',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'order:$orderId',
    );
  }

  Future<void> updateOngoingNotification({
    required String driverName,
    required String eta,
    required int progress,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      category: AndroidNotificationCategory.navigation,
    );

    await _notifications.show(
      100,
      '🚚 Tracking $driverName',
      'ETA: $eta',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelOngoingTracking() async {
    await cancelNotification(100);
  }

  void dispose() {
    _notificationController.close();
  }
}
