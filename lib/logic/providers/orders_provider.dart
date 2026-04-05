import 'package:flutter/material.dart';
import '../../data/services/supabase_service.dart';
import '../../models/order.dart';

class OrdersProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

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
          print('Error parsing order: $e');
        }
      }
    } catch (e) {
      _error = e.toString();
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearOrders() {
    _orders = [];
    notifyListeners();
  }
}
