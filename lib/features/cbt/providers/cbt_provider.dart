import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class CbtProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _daftarUjian = [];

  Map<String, dynamic>? _activeUjian;
  Map<String, dynamic>? _activePeserta;
  List<dynamic> _soalList = [];
  double? _lastSkor;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get daftarUjian => _daftarUjian;
  Map<String, dynamic>? get activeUjian => _activeUjian;
  Map<String, dynamic>? get activePeserta => _activePeserta;
  List<dynamic> get soalList => _soalList;
  double? get lastSkor => _lastSkor;

  Future<void> fetchDaftarUjian() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/cbt/ujian');
      if (response.statusCode == 200 && response.data['data'] != null) {
        _daftarUjian = response.data['data'];
      } else {
        _errorMessage = "Gagal memuat daftar ujian.";
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
         _errorMessage = "Fitur CBT khusus untuk siswa.";
      } else {
         _errorMessage = "Terjadi kesalahan koneksi saat memuat ujian.";
      }
    } catch (e) {
      _errorMessage = "Terjadi kesalahan yang tidak terduga.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchSoal(int ujianId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/cbt/ujian/$ujianId/soal');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        _activeUjian = data['ujian'];
        _activePeserta = data['peserta'];
        _soalList = data['soal'];
        return true;
      }
      _errorMessage = "Gagal memuat soal ujian.";
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _errorMessage = e.response?.data['message'] ?? "Anda sudah menyelesaikan ujian ini.";
      } else {
        _errorMessage = "Terjadi kesalahan koneksi.";
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitJawaban(int ujianId, int bankSoalId, int? opsiId, {String? essay, bool raguRagu = false}) async {
    try {
      final response = await _apiClient.dio.post('/cbt/ujian/$ujianId/jawab', data: {
        'cbt_bank_soal_id': bankSoalId,
        'cbt_opsi_jawaban_id': opsiId,
        'jawaban_essay': essay,
        'ragu_ragu': raguRagu,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> selesaiUjian(int ujianId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post('/cbt/ujian/$ujianId/selesai');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _lastSkor = (data?['skor'] as num?)?.toDouble();
        // Simpan soalList untuk review pembahasan sebelum di-reset
        final reviewSoal = List<dynamic>.from(_soalList);
        _activeUjian = null;
        _activePeserta = null;
        _soalList = [];
        return {'skor': _lastSkor, 'soal': reviewSoal};
      }
      _errorMessage = 'Gagal menyelesaikan ujian.';
      return null;
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Gagal menyelesaikan ujian: Terjadi kesalahan jaringan.';
      debugPrint('DEBUG selesaiUjian DioException: ${e.response?.data}');
      return null;
    } catch (e) {
      _errorMessage = 'Gagal menyelesaikan ujian: Terjadi kesalahan.';
      debugPrint('DEBUG selesaiUjian Exception: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil hasil ujian yang sudah selesai dari server (beserta pembahasan & jawaban benar)
  Future<Map<String, dynamic>?> fetchHasil(int ujianId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('DEBUG: Mengambil hasil ujian untuk id: $ujianId');
      final response = await _apiClient.dio.get('/cbt/ujian/$ujianId/hasil');
      debugPrint('DEBUG: Response hasil ujian: ${response.statusCode}');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        debugPrint('DEBUG: Data hasil ujian berhasil diambil');
        return data; // {skor, status, soal, peserta}
      }
      _errorMessage = 'Hasil ujian tidak ditemukan.';
      return null;
    } on DioException catch (e) {
      debugPrint('DEBUG: DioException fetchHasil: ${e.message}, data: ${e.response?.data}');
      _errorMessage = e.response?.data?['message'] ?? 'Gagal memuat hasil ujian.';
      return null;
    } catch (e) {
      debugPrint('DEBUG: Exception fetchHasil: $e');
      _errorMessage = 'Terjadi kesalahan.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
