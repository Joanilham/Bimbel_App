import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BerandaProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> _pengumuman = [];
  List<dynamic> _jadwalHariIni = [];
  Map<String, dynamic>? _tagihanAktif;
  List<dynamic> _ujianAktif = [];
  String _roleView = 'siswa';
  List<String> _readNotifs = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<dynamic> get pengumuman => _pengumuman;
  int get unreadPengumumanCount {
    if (_pengumuman.isEmpty) return 0;
    return _pengumuman.where((p) => !_readNotifs.contains(p['id'].toString())).length;
  }
  List<dynamic> get jadwalHariIni => _jadwalHariIni;
  Map<String, dynamic>? get tagihanAktif => _tagihanAktif;
  List<dynamic> get ujianAktif => _ujianAktif;
  String get roleView => _roleView;

  Future<void> fetchBeranda() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get('/beranda');

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        
        if (responseData != null) {
          _pengumuman = responseData['pengumuman'] ?? [];
          _jadwalHariIni = responseData['jadwal_hari_ini'] ?? [];
          _tagihanAktif = responseData['tagihan_aktif'];
          _ujianAktif = responseData['ujian_aktif'] ?? [];
          _roleView = responseData['role_view'] ?? 'siswa';

          final prefs = await SharedPreferences.getInstance();
          _readNotifs = prefs.getStringList('read_notifs') ?? [];
        } else {
          _errorMessage = "Data kosong dari server.";
        }
      } else {
        _errorMessage = "Gagal memuat data beranda.";
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _errorMessage = "Sesi telah berakhir. Silakan login kembali.";
      } else {
        _errorMessage = "Terjadi kesalahan koneksi saat memuat beranda.";
      }
    } catch (e) {
      _errorMessage = "Terjadi kesalahan yang tidak terduga.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isNotifRead(String id) => _readNotifs.contains(id);

  Future<void> markNotifAsRead(String id) async {
    if (!_readNotifs.contains(id)) {
      _readNotifs.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_notifs', _readNotifs);
      notifyListeners();
    }
  }
}
