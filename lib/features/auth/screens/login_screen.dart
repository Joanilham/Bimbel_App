import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../dashboard/screens/main_layout_screen.dart';
import '../../../core/utils/custom_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      CustomToast.showWarning(context, 'Email dan kata sandi wajib diisi');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password);

    if (!mounted) return;

    if (success) {
      CustomToast.showSuccess(context, 'Login Berhasil!');
      
      // Navigasi ke Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
      );
    } else {
      // Tampilkan pesan error
      CustomToast.showError(context, authProvider.errorMessage ?? 'Gagal login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    const primaryColor = Color(0xFF4F46E5);
    const indigoDark = Color(0xFF3730A3);
    const slate900 = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: Stack(
        children: [
          // Top Background Graphic
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, indigoDark, slate900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Icon & Title
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded, size: 56, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Selamat Datang!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk ke portal akademik Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 40),
                        
                        // Login Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email / Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 0.5)),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.person_rounded, color: primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9), // slate-100
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 24),
                              
                              const Text('Kata Sandi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 0.5)),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_rounded, color: primaryColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9), // slate-100
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                ),
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submitLogin(),
                              ),
                              const SizedBox(height: 16),
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Lupa Sandi?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: primaryColor.withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                      : const Text('MASUK SEKARANG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        Text(
                          'Sistem Manajemen Pendidikan Terpadu',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
