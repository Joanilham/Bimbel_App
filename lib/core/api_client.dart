import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://lasciviously-enculturative-fran.ngrok-free.dev/api/'; // Pastikan berakhiran /

  final Dio dio;

  ApiClient() : dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
      'X-App-Access': 'true', // Custom header untuk izin akses API
      'ngrok-skip-browser-warning': 'true', // Penting untuk bypass halaman peringatan ngrok
    },
  )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Hapus leading slash agar Uri.resolve tidak menimpa /api/
        if (options.path.startsWith('/')) {
          options.path = options.path.substring(1);
        }

        // Ambil token dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        
        // Jika token ada, suntikkan ke Header Authorization
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options); // Lanjutkan request
      },
      onError: (DioException error, handler) {
        // Tangani error global di sini (misal: Token expired -> Logout otomatis)
        if (error.response?.statusCode == 401) {
          // Token tidak valid atau kedaluwarsa
        }
        return handler.next(error);
      },
    ));
  }
}
