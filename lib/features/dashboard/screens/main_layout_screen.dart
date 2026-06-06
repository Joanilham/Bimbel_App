import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../akademik/providers/akademik_provider.dart';
import '../../../core/utils/custom_toast.dart';
import 'home_screen.dart';
import '../../akademik/screens/akademik_screen.dart';
import '../../keuangan/screens/keuangan_screen.dart';
import '../../cbt/screens/cbt_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../beranda/providers/beranda_provider.dart';
import '../../keuangan/providers/keuangan_provider.dart';
import '../../chat/providers/chat_provider.dart' as import_chat;

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final PageController _pageController;

  void _onNavigate(int index) {
    // Check verification and overdue status
    if (index == 0 || index == 1 || index == 2) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      final user = provider.userProfile;

      if (user != null) {
        bool isAktif =
            user['status'] != null &&
            user['status'].toString().toLowerCase() == 'aktif';
        bool isOverdue = user['is_overdue'] == true || user['is_overdue'] == 1;
        bool hasDispensasi =
            user['dispensasi'] == true || user['dispensasi'] == 1;

        if (!isAktif) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.lock_person_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akun Belum Diverifikasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Maaf, akun Anda saat ini sedang menunggu proses verifikasi oleh Admin Pusat. Akses ke menu Beranda, Akademik, dan Ujian ditutup sementara.\n\nSilakan lunasi tagihan Anda (jika ada) dan tunggu proses verifikasi selesai.',
                style: TextStyle(height: 1.5),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mengerti'),
                ),
              ],
            ),
          );
          return; // Stop navigation
        }

        if (isOverdue && !hasDispensasi) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text('Akses Dibekukan'),
                ],
              ),
              content: const Text(
                'Maaf, akses Anda ke fitur Akademik dan Ujian ditangguhkan karena Anda memiliki tagihan yang sudah melewati batas waktu (jatuh tempo).\n\nSilakan lunasi tagihan Anda terlebih dahulu atau hubungi Admin.',
                style: TextStyle(height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Force navigate to Keuangan (index 3)
                    setState(() {
                      _currentIndex = 3;
                    });
                    _pageController.jumpToPage(3);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lihat Tagihan'),
                ),
              ],
            ),
          );
          return; // Stop navigation
        }
      }
    }

    if (index == 99) {
      _showQrCodeDialog(context);
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);

    // Auto-refresh when switching tabs
    if (index == 0) {
      Provider.of<BerandaProvider>(context, listen: false).fetchBeranda();
    } else if (index == 3) {
      final keuangan = Provider.of<KeuanganProvider>(context, listen: false);
      keuangan.fetchTagihan();
      keuangan.fetchRiwayat();
    }
  }

  // Daftar halaman untuk setiap tab
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);
    _pages = [
      HomeScreen(onNavigate: _onNavigate),
      AkademikScreen(key: akademikScreenKey),
      const CbtScreen(),
      const KeuanganScreen(),
      const ProfileScreen(),
    ];

    // Muat data awal saat pertama kali masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
      Provider.of<BerandaProvider>(context, listen: false).fetchBeranda();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_currentIndex == 0) {
        Provider.of<BerandaProvider>(context, listen: false).fetchBeranda();
      } else if (_currentIndex == 3) {
        final keuangan = Provider.of<KeuanganProvider>(context, listen: false);
        keuangan.fetchTagihan();
        keuangan.fetchRiwayat();
      }
    }
  }

  void _showQrCodeDialog(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final user = provider.userProfile;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data profil belum dimuat. Buka menu Profil lalu coba lagi.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QrCodeBottomSheet(
          user: user,
          onNavigateToRiwayat: () {
            // Force navigate to Akademik (index 1)
            setState(() {
              _currentIndex = 1;
            });
            _pageController.jumpToPage(1);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              akademikScreenKey.currentState?.switchToTab(1);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auto-redirect for unverified users on first load
    final user = Provider.of<ProfileProvider>(context).userProfile;
    if (user != null) {
      // Start global polling for chat notifications
      Provider.of<import_chat.ChatProvider>(context, listen: false).startGlobalPolling(user['id']);
      
      bool isAktif = user['status'] != null && user['status'].toString().toLowerCase() == 'aktif';
      if (!isAktif && (_currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentIndex = 3;
            });
            _pageController.jumpToPage(3);
            CustomToast.showInfo(context, 'Akun belum diverifikasi. Akses dibatasi.');
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 32), // Add padding to prevent FAB from covering content
        child: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Prevent conflict with nested scroll views
          children: _pages,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQrCodeDialog(context),
        backgroundColor: const Color(0xFF2F58E5), // Primary blue
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        padding: EdgeInsets.zero,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    Icons.home_rounded,
                    Icons.home_outlined,
                    'Beranda',
                  ),
                  _buildNavItem(
                    1,
                    Icons.menu_book_rounded,
                    Icons.menu_book_outlined,
                    'Jadwal',
                  ),
                  const SizedBox(width: 48), // Space for FAB
                  _buildNavItem(
                    2,
                    Icons.assignment_rounded,
                    Icons.assignment_outlined,
                    'Tryout',
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_rounded,
                    Icons.person_outline_rounded,
                    'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    const color = Color(0xFF2F58E5); // Primary Blue
    return Expanded(
      child: InkWell(
        onTap: () => _onNavigate(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  key: ValueKey(isSelected),
                  color: isSelected ? color : Colors.grey.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCodeBottomSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onNavigateToRiwayat;

  const _QrCodeBottomSheet({
    required this.user,
    required this.onNavigateToRiwayat,
  });

  @override
  State<_QrCodeBottomSheet> createState() => _QrCodeBottomSheetState();
}

class _QrCodeBottomSheetState extends State<_QrCodeBottomSheet> {
  late String qrData;
  late Stream<int> _timerStream;
  late StreamSubscription<int> _subscription;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _updateQrData();
    // Update every 30 seconds
    _timerStream = Stream.periodic(const Duration(seconds: 30), (x) => x);
    _subscription = _timerStream.listen((_) {
      if (mounted) {
        setState(() {
          _updateQrData();
        });
      }
    });

    // Start polling attendance status every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkAbsensiStatus();
    });
  }

  Future<void> _checkAbsensiStatus() async {
    if (!mounted) return;
    final provider = Provider.of<AkademikProvider>(context, listen: false);
    final status = await provider.checkAbsensiToday();
    if (status != null && mounted) {
      if (status['jam_masuk'] != null) {
        CustomToast.showSuccess(context, 'Berhasil absen!');
        _pollingTimer?.cancel();
        Navigator.pop(context);
        widget.onNavigateToRiwayat();
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _updateQrData() {
    // Generate new token based on current time (unix timestamp rounded to 30s)
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    qrData =
        'ABSEN-SISWA-${widget.user['id']}-${widget.user['email']}-$timestamp';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'QR Code Absensi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tunjukkan QR Code ini kepada Admin\n(QR otomatis diperbarui setiap 30 detik)',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.user['name'] ?? 'Nama Siswa',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.user['email'] ?? '-',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigateToRiwayat();
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text(
                'Riwayat Absensi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: const Color(0xFF1E293B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
