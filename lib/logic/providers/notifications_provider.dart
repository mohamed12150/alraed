import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      titleAr: json['title_ar'] ?? '',
      titleEn: json['title_en'] ?? '',
      bodyAr: json['body_ar'] ?? '',
      bodyEn: json['body_en'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationsProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;
  List<AppNotification> _notifications = [];
  RealtimeChannel? _channel;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(String userId) async {
    try {
      final res = await _client
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _notifications = (res as List).map((e) => AppNotification.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void subscribeRealtime(String userId) {
    _channel?.unsubscribe();
    _channel = _client.channel('notifications:$userId');
    _channel!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'user_notifications',
            filter: 'user_id=eq.$userId',
          ),
          (payload, [ref]) {
            final newRecord = payload['new'] as Map<String, dynamic>?;
            if (newRecord != null) {
              final newNotif = AppNotification.fromJson(newRecord);
              _notifications = [newNotif, ..._notifications];
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        titleAr: n.titleAr,
        titleEn: n.titleEn,
        bodyAr: n.bodyAr,
        bodyEn: n.bodyEn,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return AppNotification(
            id: n.id,
            titleAr: n.titleAr,
            titleEn: n.titleEn,
            bodyAr: n.bodyAr,
            bodyEn: n.bodyEn,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  void clear() {
    _channel?.unsubscribe();
    _channel = null;
    _notifications = [];
    notifyListeners();
  }
}
