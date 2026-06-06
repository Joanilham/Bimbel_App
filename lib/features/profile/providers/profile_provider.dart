import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class ProfileProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  int _photoVersion = DateTime.now().millisecondsSinceEpoch;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  int get photoVersion => _photoVersion;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/user');
      if (response.statusCode == 200 && response.data['data'] != null) {
        _userProfile = response.data['data'];
      } else {
        _errorMessage = "Gagal memuat data profil.";
      }
    } on DioException {
      _errorMessage = "Terjadi kesalahan koneksi saat memuat profil.";
    } catch (e) {
      _errorMessage = "Terjadi kesalahan yang tidak terduga.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('/profile/update', data: data);
      if (response.statusCode == 200) {
        // Refresh data
        await fetchProfile();
        return true;
      }
      _errorMessage = "Gagal memperbarui profil";
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        _errorMessage = e.response?.data['message'] ?? "Data tidak valid (mungkin email sudah digunakan).";
      } else {
        _errorMessage = "Terjadi kesalahan saat memperbarui profil.";
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfilePhoto(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post('/profile/photo', data: formData);
      if (response.statusCode == 200) {
        _photoVersion = DateTime.now().millisecondsSinceEpoch; // Break image cache
        // Refresh data
        await fetchProfile();
        return true;
      }
      _errorMessage = "Gagal memperbarui foto profil";
      return false;
    } on DioException catch (e) {
      _errorMessage = "Terjadi kesalahan koneksi saat mengupload foto profil: ${e.message}";
      return false;
    } catch (e) {
      _errorMessage = "Terjadi kesalahan tidak terduga: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
