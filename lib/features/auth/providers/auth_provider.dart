import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  // Fungsi untuk mengecek sesi saat aplikasi pertama kali dibuka
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    notifyListeners();
  }

  // Fungsi Login
  Future<bool> login(String loginUser, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/login', data: FormData.fromMap({
        'login': loginUser, // Laravel mengharapkan field 'login' (bisa username / email)
        'password': password,
      }));

      // Sesuaikan dengan struktur response API Laravel Anda
      // Asumsi response Laravel Sanctum: { "token": "xxx", "user": {...} }
      if (response.statusCode == 200) {
        // Karena Laravel menggunakan ApiResponse trait:
        // Format response adalah { "status": "success", "message": "...", "data": { "token": "...", "user": {...} } }
        final responseData = response.data['data'];
        
        if (responseData != null && responseData['token'] != null) {
          _token = responseData['token'];
          
          // Simpan ke local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = "Format response tidak valid dari server.";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      return false;
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 401) {
        _errorMessage = "Email atau kata sandi salah.";
      } else if (e.response?.statusCode == 422) {
        _errorMessage = e.response?.data['message'] ?? "Data tidak valid.";
      } else {
        _errorMessage = "Terjadi kesalahan koneksi server.";
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Terjadi kesalahan yang tidak terduga.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fungsi Logout
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/logout');
    } catch (e) {
      // Abaikan error saat memanggil API logout jika token sudah mati
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _token = null;
      notifyListeners();
    }
  }
}
