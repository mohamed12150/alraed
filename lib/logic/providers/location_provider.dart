import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  String _currentAddress = '';
  bool _isLoading = false;

  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    _isLoading = true;
    notifyListeners();

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _currentAddress = 'خدمات الموقع معطلة';
        _isLoading = false;
        notifyListeners();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _currentAddress = 'تم رفض إذن الوصول للموقع';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentAddress = 'تم رفض إذن الموقع بشكل دائم';
        _isLoading = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Create a readable address including the neighborhood (subLocality)
        String neighborhood = place.subLocality ?? '';
        String city = place.locality ?? '';
        
        if (neighborhood.isNotEmpty && neighborhood != city) {
          _currentAddress = '$neighborhood, $city';
        } else if (place.name != null && place.name!.isNotEmpty && place.name != city) {
          _currentAddress = '${place.name}, $city';
        } else {
          _currentAddress = city;
        }
      } else {
        _currentAddress = 'تعذر تحديد العنوان';
      }
    } catch (e) {
      _currentAddress = 'خطأ في تحديد الموقع';
      debugPrint('Error getting location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
