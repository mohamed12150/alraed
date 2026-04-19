import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/supabase_service.dart';
import '../../models/order.dart';

class OrdersProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final _client = Supabase.instance.client;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabaseService.getOrders(userId);
      _orders = [];
      for (var item in data) {
        try {
          _orders.add(Order.fromJson(item));
        } catch (e) {
          debugPrint('Error parsing order: $e');
        }
      }
    } catch (e) {
      _error = e.toString();
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _subscribeRealtime(userId);
  }

  void _subscribeRealtime(String userId) {
    _channel?.unsubscribe();
    _channel = _client.channel('orders:$userId');
    _channel!
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'orders',
            filter: 'user_id=eq.$userId',
          ),
          (payload, [ref]) {
            fetchOrders(userId);
          },
        )
        .subscribe();
  }

  void clearOrders() {
    _channel?.unsubscribe();
    _channel = null;
    _orders = [];
    notifyListeners();
  }
}
