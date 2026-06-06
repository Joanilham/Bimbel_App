import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class AkademikProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingJadwal = false;
  String? _errorJadwal;
  Map<String, dynamic> _jadwal = {}; // Grouped by day

  bool _isLoadingAbsensi = false;
  String? _errorAbsensi;
  List<dynamic> _absensi = [];

  bool get isLoadingJadwal => _isLoadingJadwal;
  String? get errorJadwal => _errorJadwal;
  Map<String, dynamic> get jadwal => _jadwal;

  bool get isLoadingAbsensi => _isLoadingAbsensi;
  String? get errorAbsensi => _errorAbsensi;
  List<dynamic> get absensi => _absensi;

  Future<void> fetchJadwal() async {
    _isLoadingJadwal = true;
    _errorJadwal = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/jadwal');
      if (response.statusCode == 200 && response.data['data'] != null) {
        _jadwal = Map<String, dynamic>.from(response.data['data']);
      } else {
        _errorJadwal = "Gagal memuat jadwal.";
      }
    } on DioException {
      _errorJadwal = "Terjadi kesalahan koneksi saat memuat jadwal.";
    } catch (e) {
      _errorJadwal = "Terjadi kesalahan yang tidak terduga.";
    } finally {
      _isLoadingJadwal = false;
      notifyListeners();
    }
  }

  Future<void> fetchAbsensi() async {
    _isLoadingAbsensi = true;
    _errorAbsensi = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/absensi');
      if (response.statusCode == 200 && response.data['data'] != null) {
        // Asumsi data yang dikembalikan adalah array data absensi (karena Laravel paginate mengembalikan { data: [...] } di dalam response format)
        // Wait, ApiResponse Laravel custom format: {status: success, message: ..., data: { data: [...], current_page: 1... }}
        final responseData = response.data['data'];
        if (responseData is Map && responseData.containsKey('data')) {
          _absensi = responseData['data'];
        } else if (responseData is List) {
          _absensi = responseData;
        } else {
          _absensi = [];
        }
      } else {
        _errorAbsensi = "Gagal memuat absensi.";
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
         _errorAbsensi = "Fitur absensi khusus untuk siswa.";
      } else {
         _errorAbsensi = "Terjadi kesalahan koneksi saat memuat absensi.";
      }
    } catch (e) {
      _errorAbsensi = "Terjadi kesalahan yang tidak terduga.";
    } finally {
      _isLoadingAbsensi = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> checkAbsensiToday() async {
    try {
      final response = await _apiClient.dio.get('/absensi/today');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
    } catch (e) {
      // Ignore error for silent polling
    }
    return null;
  }
}
