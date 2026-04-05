import 'package:flutter/material.dart';
import 'package:meatly/data/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/api_service.dart';
import '../../models/user.dart' as model;

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoggedIn = false;
  model.User? _user;
  String? _token;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  model.User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _isLoggedIn = true;
      _token = session.accessToken;
      _user = model.User(
        id: session.user.id,
        email: session.user.email ?? '',
        name: session.user.userMetadata?['full_name'] ?? '',
        phone: session.user.userMetadata?['phone_number'],
      );
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _isLoggedIn = true;
        _token = session.accessToken;
        _user = model.User(
          id: session.user.id,
          email: session.user.email ?? '',
          name: session.user.userMetadata?['full_name'] ?? '',
          phone: session.user.userMetadata?['phone_number'],
        );
      } else {
        _isLoggedIn = false;
        _user = null;
        _token = null;
      }
      notifyListeners();
    });
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(phone, password);

      if (result['success'] == true) {
        // We don't need to manually set _isLoggedIn or _user here
        // because the onAuthStateChange listener will handle it.
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String phone,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(name, phone, password);

      if (result['success'] == true) {
        // onAuthStateChange listener will handle the state update
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> fetchProfile() async {
    if (_user == null) return;
    try {
      final profile = await _apiService.getProfile(_user!.id);
      if (profile != null) {
        _user = model.User(
          id: _user!.id,
          email: _user!.email,
          name: profile['full_name'] ?? _user!.name,
          phone: profile['phone_number'],
        );
        notifyListeners();
      }
    } catch (_) {
      // Ignore errors
    }
  }

  Future<bool> updateProfile({String? name, String? phone}) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['full_name'] = name;
      if (phone != null) updates['phone_number'] = phone;

      final success = await _apiService.updateProfile(_user!.id, updates);
      if (success) {
        _user = model.User(
          id: _user!.id,
          email: _user!.email,
          name: name ?? _user!.name,
          phone: phone ?? _user?.phone,
        );
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    // onAuthStateChange will handle resetting variables and notifyListeners
  }

  Future<void> deleteAccount() async {
    // In a real app, you would call an Edge Function or RPC to delete the user
    // Since we don't have that set up, we'll perform logout as requested.
    await logout();
  }
}
