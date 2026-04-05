import 'supabase_service.dart';

class ApiService {
  // Placeholder baseUrl — implement Supabase or other backend integration here.
  static String get baseUrl => '';
  // Use SupabaseService to handle backend operations
  final SupabaseService _supabase = SupabaseService();

  Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String password,
  ) async {
    return _supabase.register(name, phone, password);
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    return _supabase.login(phone, password);
  }

  // No HTTP response handler here — implement response handling when adding a backend.

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return _supabase.getProfile(userId);
  }

  Future<bool> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    return _supabase.updateProfile(userId, updates);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return _supabase.getCategories();
  }

  Future<List<Map<String, dynamic>>> getProducts({String? categoryId}) async {
    return _supabase.getProducts(categoryId: categoryId);
  }

  Future<List<Map<String, dynamic>>> getBanners() async {
    return _supabase.getBanners();
  }

  Future<List<Map<String, dynamic>>> getSpecialOffers() async {
    return _supabase.getSpecialOffers();
  }

  Future<Map<String, dynamic>?> getAppSettings() async {
    return _supabase.getAppSettings();
  }

  Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> orderData,
  ) async {
    return _supabase.placeOrder(orderData);
  }
}
