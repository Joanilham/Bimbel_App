import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../../../core/api_client.dart';

class KeuanganProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingTagihan = false;
  String? _errorTagihan;
  Map<String, dynamic>? _tagihan;

  bool _isLoadingRiwayat = false;
  String? _errorRiwayat;
  List<dynamic> _riwayat = [];

  bool get isLoadingTagihan => _isLoadingTagihan;
  String? get errorTagihan => _errorTagihan;
  Map<String, dynamic>? get tagihan => _tagihan;

  bool get isLoadingRiwayat => _isLoadingRiwayat;
  String? get errorRiwayat => _errorRiwayat;
  List<dynamic> get riwayat => _riwayat;

  Future<void> fetchTagihan() async {
    _isLoadingTagihan = true;
    _errorTagihan = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/keuangan/tagihan');
      if (response.statusCode == 200) {
        _tagihan = response.data['data']; // null jika tidak ada tagihan
      } else {
        _errorTagihan = "Gagal memuat tagihan.";
      }
    } on DioException catch (e) {
       if (e.response?.statusCode == 403) {
         _errorTagihan = "Fitur keuangan khusus untuk siswa.";
      } else {
         _errorTagihan = "Terjadi kesalahan koneksi saat memuat tagihan.";
      }
    } catch (e) {
      _errorTagihan = "Terjadi kesalahan yang tidak terduga.";
    } finally {
      _isLoadingTagihan = false;
      notifyListeners();
    }
  }

  Future<void> fetchRiwayat() async {
    _isLoadingRiwayat = true;
    _errorRiwayat = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/keuangan/riwayat');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final responseData = response.data['data'];
        if (responseData is Map && responseData.containsKey('data')) {
          _riwayat = responseData['data'];
        } else if (responseData is List) {
          _riwayat = responseData;
        } else {
          _riwayat = [];
        }
      } else {
        _errorRiwayat = "Gagal memuat riwayat pembayaran.";
      }
    } on DioException {
      _errorRiwayat = "Terjadi kesalahan koneksi saat memuat riwayat.";
    } catch (e) {
      _errorRiwayat = "Terjadi kesalahan yang tidak terduga.";
    } finally {
      _isLoadingRiwayat = false;
      notifyListeners();
    }
  }
  bool _isLoadingBanks = false;
  String? _errorBanks;
  List<dynamic> _banks = [];

  bool get isLoadingBanks => _isLoadingBanks;
  String? get errorBanks => _errorBanks;
  List<dynamic> get banks => _banks;

  Future<void> fetchBanks() async {
    _isLoadingBanks = true;
    _errorBanks = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/keuangan/bank');
      if (response.statusCode == 200 && response.data['data'] != null) {
        _banks = response.data['data'];
      } else {
        _errorBanks = "Gagal memuat daftar bank.";
      }
    } catch (e) {
      _errorBanks = "Terjadi kesalahan saat memuat daftar bank.";
    } finally {
      _isLoadingBanks = false;
      notifyListeners();
    }
  }

  String? _submitError;
  String? get submitError => _submitError;

  Future<bool> submitPembayaran(String nominal, int bankId, String imagePath) async {
    _submitError = null;
    try {
      final cleanNominal = nominal.replaceAll(RegExp(r'[^0-9]'), '');
      
      FormData formData = FormData.fromMap({
        'nominal': cleanNominal,
        'bank_id': bankId,
        'bukti_pembayaran': await MultipartFile.fromFile(
          imagePath,
          filename: 'bukti_transfer.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      developer.log('Submitting payment: nominal=$cleanNominal, bank_id=$bankId', name: 'KeuanganProvider');
      
      final response = await _apiClient.dio.post('/keuangan/bayar', data: formData);
      developer.log('Response: ${response.statusCode} - ${response.data}', name: 'KeuanganProvider');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTagihan();
        await fetchRiwayat();
        return true;
      }
      _submitError = 'Server menolak permintaan (${response.statusCode})';
      return false;
    } on DioException catch (e) {
      developer.log('DioException: ${e.type} - ${e.response?.statusCode} - ${e.response?.data}', name: 'KeuanganProvider');
      if (e.response?.data != null) {
        final errData = e.response!.data;
        if (errData is Map && errData.containsKey('message')) {
          _submitError = errData['message'].toString();
        } else if (errData is Map && errData.containsKey('errors')) {
          final errors = errData['errors'] as Map;
          _submitError = errors.values.first is List ? errors.values.first[0] : errors.values.first.toString();
        } else {
          _submitError = 'Error ${e.response?.statusCode}: Gagal mengirim pengajuan.';
        }
      } else {
        _submitError = 'Koneksi gagal: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      developer.log('Unknown error: $e', name: 'KeuanganProvider');
      _submitError = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }
}
