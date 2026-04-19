import 'package:flutter/material.dart';
import 'package:meatly/data/services/api_service.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/banner.dart' as banner_model;
import '../../models/special_offer.dart';

class ShopProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _trendingProducts = [];
  List<Product> _discountedProducts = [];
  List<banner_model.Banner> _banners = [];
  List<SpecialOffer> _specialOffers = [];
  String _selectedCategoryId = '';
  int _currentBannerIndex = 0;
  bool _isLoading = false;
  double _deliveryFee = 0.0;
  double _taxRate = 0.0;
  String _contactPhone = '';
  String _bankAccount = '';
  String _bankIban = '';
  String _bankRajhiAccount = '';
  String _bankRajhiIban = '';
  String _bankAhliAccount = '';
  String _bankAhliIban = '';
  String _bankInmaAccount = '';
  String _bankInmaIban = '';

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Product> get trendingProducts => _trendingProducts;
  List<Product> get discountedProducts => _discountedProducts;
  List<banner_model.Banner> get banners => _banners;
  List<SpecialOffer> get specialOffers => _specialOffers;
  String get selectedCategoryId => _selectedCategoryId;
  int get currentBannerIndex => _currentBannerIndex;
  bool get isLoading => _isLoading;
  double get deliveryFee => _deliveryFee;
  double get taxRate => _taxRate;
  String get contactPhone => _contactPhone;
  String get bankAccount => _bankAccount;
  String get bankIban => _bankIban;
  String get bankRajhiAccount => _bankRajhiAccount;
  String get bankRajhiIban => _bankRajhiIban;
  String get bankAhliAccount => _bankAhliAccount;
  String get bankAhliIban => _bankAhliIban;
  String get bankInmaAccount => _bankInmaAccount;
  String get bankInmaIban => _bankInmaIban;

  ShopProvider() {
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final categoriesData = await _apiService.getCategories();
      if (categoriesData.isNotEmpty) {
        _categories = categoriesData
            .map((json) => Category.fromJson(json))
            .toList();
      } else {
        _categories = [];
      }

      final productsData = await _apiService.getProducts();
      if (productsData.isNotEmpty) {
        _products = productsData.map((json) => Product.fromJson(json)).toList();

        // Sort by salesCount for trending
        _trendingProducts = List.from(_products);
        _trendingProducts.sort((a, b) => b.salesCount.compareTo(a.salesCount));

        _discountedProducts = _products
            .where((p) => p.discountPrice != null && p.discountPrice! > 0)
            .toList();
      } else {
        _products = [];
        _trendingProducts = [];
        _discountedProducts = [];
      }

      final bannersData = await _apiService.getBanners();
      if (bannersData.isNotEmpty) {
        _banners = bannersData
            .map((json) => banner_model.Banner.fromJson(json))
            .toList();
      } else {
        _banners = [];
      }

      final specialOffersData = await _apiService.getSpecialOffers();
      if (specialOffersData.isNotEmpty) {
        _specialOffers = specialOffersData
            .map((json) => SpecialOffer.fromJson(json))
            .toList();
      } else {
        _specialOffers = [];
      }

      final settings = await _apiService.getAppSettings();
      if (settings != null) {
        _deliveryFee = (settings['delivery_fee'] ?? 0.0).toDouble();
        final percentage = (settings['tax_percentage'] ?? 0.0).toDouble();
        _taxRate = percentage / 100;
        _contactPhone = settings['contact_phone']?.toString() ?? '';
        _bankAccount = settings['bank_account']?.toString() ?? '';
        _bankIban = settings['bank_iban']?.toString() ?? '';
        _bankRajhiAccount = settings['bank_rajhi_account']?.toString() ?? '';
        _bankRajhiIban = settings['bank_rajhi_iban']?.toString() ?? '';
        _bankAhliAccount = settings['bank_ahli_account']?.toString() ?? '';
        _bankAhliIban = settings['bank_ahli_iban']?.toString() ?? '';
        _bankInmaAccount = settings['bank_inma_account']?.toString() ?? '';
        _bankInmaIban = settings['bank_inma_iban']?.toString() ?? '';
      }
    } catch (e) {
      // Keep empty if error
      _categories = [];
      _products = [];
      _trendingProducts = [];
      _discountedProducts = [];
      _banners = [];
      _specialOffers = [];
      _deliveryFee = 0.0;
      _taxRate = 0.0;
      debugPrint('Error fetching data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProductsByCategory(String categoryId) async {
    _isLoading = true;
    _selectedCategoryId = categoryId;
    notifyListeners();

    try {
      final productsData = await _apiService.getProducts(
        categoryId: categoryId,
      );
      if (productsData.isNotEmpty) {
        _products = productsData.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = '';
      fetchInitialData();
    } else {
      fetchProductsByCategory(categoryId);
    }
  }

  void setBannerIndex(int index) {
    _currentBannerIndex = index;
    notifyListeners();
  }

  void nextBanner() {
    if (_banners.isEmpty) return;
    _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
    notifyListeners();
  }

  Category? getCategoryById(String id) {
    return _categories.where((category) => category.id == id).firstOrNull;
  }
}
