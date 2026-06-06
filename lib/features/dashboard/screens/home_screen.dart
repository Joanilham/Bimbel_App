import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../beranda/providers/beranda_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../chat/screens/chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTagihanToast();
    });
  }

  void _checkAndShowTagihanToast() {
    final beranda = Provider.of<BerandaProvider>(context, listen: false);
    final tagihan = beranda.tagihanAktif;
    
    if (tagihan != null && tagihan['kekurangan'] != null && tagihan['kekurangan'] > 0) {
      bool isOverdue = tagihan['is_overdue'] == true;
      String batasWaktu = tagihan['batas_waktu'] ?? '';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isOverdue ? Icons.warning_rounded : Icons.info_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isOverdue 
                      ? 'Tagihan Anda telah jatuh tempo!' 
                      : 'Jangan lupa, tagihan jatuh tempo pada $batasWaktu',
                ),
              ),
            ],
          ),
          backgroundColor: isOverdue ? Colors.red.shade800 : Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'BAYAR',
            textColor: Colors.white,
            onPressed: () => widget.onNavigate?.call(3),
          ),
        ),
      );
    }
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Provider.of<BerandaProvider>(context, listen: false).fetchBeranda();
              _checkAndShowTagihanToast();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer2<BerandaProvider, ProfileProvider>(
                    builder: (context, beranda, profile, _) {
                      final user = profile.userProfile;
                      final namaUser = user?['nama'] ?? user?['name'] ?? 'Siswa';
                      final asalSekolah = user?['asal_sekolah'] ?? '';
                      return _buildHeader(namaUser, asalSekolah, beranda.unreadPengumumanCount, beranda.tagihanAktif);
                    },
                  ),
                  Consumer<BerandaProvider>(
                    builder: (context, beranda, _) => _buildPeringatanTagihan(beranda.tagihanAktif),
                  ),
                  _buildBanner(),
                  _buildGridMenu(context),
                  Consumer<BerandaProvider>(
                    builder: (context, beranda, _) => _buildJadwalHariIni(beranda.jadwalHariIni),
                  ),
                  Consumer<BerandaProvider>(
                    builder: (context, beranda, _) => _buildPengumuman(beranda.pengumuman),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String namaUser, String asalSekolah, int notifCount, Map<String, dynamic>? tagihan) {
    bool isOverdue = tagihan != null && tagihan['is_overdue'] == true;
    bool isLunas = tagihan == null;
    
    String statusText = 'Aktif';
    Color statusColor = Colors.teal;
    String aktifSampai = '';
    
    if (isOverdue) {
      statusText = 'Tidak Aktif (Nunggak)';
      statusColor = Colors.red;
    } else if (!isLunas && tagihan['batas_waktu'] != null) {
      aktifSampai = 's.d ${tagihan['batas_waktu']}';
    } else if (isLunas) {
      aktifSampai = 'Lunas';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Halo, ${namaUser.split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (asalSekolah.isNotEmpty) ...[
                      const Icon(Icons.school_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        asalSekolah,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                            if (aktifSampai.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isLunas ? Icons.verified_rounded : Icons.event_available_rounded, 
                                      size: 12, 
                                      color: Colors.blue.shade700
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      aktifSampai,
                                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 26, color: Color(0xFF1E293B)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                },
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 28, color: Color(0xFF1E293B)),
                    onPressed: _showNotificationsSheet,
                  ),
                  if (notifCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$notifCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeringatanTagihan(Map<String, dynamic>? tagihan) {
    if (tagihan == null) return const SizedBox.shrink();
    
    bool isOverdue = tagihan['is_overdue'] == true;
    String batasWaktu = tagihan['batas_waktu'] ?? '-';
    
    // Hanya tampilkan jika belum lunas dan ada batas waktu
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOverdue ? Colors.red.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_rounded : Icons.info_outline_rounded,
            color: isOverdue ? Colors.red : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue ? 'Tagihan Telah Jatuh Tempo!' : 'Informasi Tagihan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red.shade700 : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Batas pembayaran: $batasWaktu',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue ? Colors.red.shade600 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => widget.onNavigate?.call(3), // Ke halaman Tagihan
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2F58E5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F58E5).withValues(alpha: 0.2), // Opacity diturunkan sedikit
            blurRadius: 8, // Diturunkan dari 20 untuk hemat GPU
            offset: const Offset(0, 4), // Diturunkan dari 10
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorations (circles)
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Belajar Terarah,\nRaih Prestasi!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bimbingan belajar terbaik\nuntuk masa depanmu.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => widget.onNavigate?.call(2), // Tryout / CBT
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD15B),
                          foregroundColor: const Color(0xFF1E293B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Mulai Tryout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.school_rounded, size: 100, color: Colors.white.withValues(alpha: 0.9)), // Placeholder for the 3D illustration
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    final menus = [
      {'icon': Icons.menu_book_rounded, 'label': 'Jadwal', 'color': const Color(0xFF4A85F6), 'index': 1},
      {'icon': Icons.how_to_reg_rounded, 'label': 'Absensi', 'color': const Color(0xFF4ADE80), 'index': 99}, // 99 triggers QR Code
      {'icon': Icons.assignment_rounded, 'label': 'Ujian CBT', 'color': const Color(0xFFA162F7), 'index': 2},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Tagihan', 'color': const Color(0xFFFB923C), 'index': 3},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: menus.map((menu) {
          return GestureDetector(
            onTap: () => widget.onNavigate?.call(menu['index'] as int),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4, // Diturunkan dari 10
                        offset: const Offset(0, 2), // Diturunkan dari 4
                      ),
                    ],
                  ),
                  child: Icon(
                    menu['icon'] as IconData,
                    color: menu['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  menu['label'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJadwalHariIni(List jadwal) {
    if (jadwal.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jadwal Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text('Lihat semua', style: TextStyle(color: Color(0xFF2F58E5), fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2F58E5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120, // increased height slightly to prevent overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: jadwal.length,
            itemBuilder: (context, i) {
              final item = jadwal[i];
              return _buildJadwalCard(
                item['mapel'] ?? 'Pelajaran',
                '${item['jam_mulai']} - ${item['jam_selesai']}',
                item['nama_guru'] ?? 'Guru',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJadwalCard(String title, String subtitle, String guru) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3, // Diturunkan dari 8
            offset: const Offset(0, 2), // Diturunkan dari 4
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_note_rounded, color: Color(0xFF4F46E5), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Prevents expanding to max height and causing overflow
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        guru, 
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPengumumanDetail(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (item['foto'] != null && item['foto'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      item['foto'],
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A85F6), Color(0xFF2F58E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.newspaper_rounded, color: Colors.white54, size: 64),
                    ),
                  ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['judul'] ?? 'Pengumuman',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item['isi'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPengumuman(List pengumuman) {
    if (pengumuman.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Berita & Informasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Jika ada layar khusus Berita, navigasi ke sana
                  // Namun sementara kita bisa buka bottom sheet atau navigasi
                  _showNotificationsSheet();
                },
                child: const Row(
                  children: [
                    Text('Lihat semua', style: TextStyle(color: Color(0xFF2F58E5), fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2F58E5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210, // increased to prevent text overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pengumuman.length,
            itemBuilder: (context, index) {
              final item = pengumuman[index];
              return GestureDetector(
                onTap: () => _showPengumumanDetail(context, item),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['foto'] != null && item['foto'].toString().isNotEmpty)
                        Container(
                          height: 70,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            image: DecorationImage(
                              image: NetworkImage(item['foto']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 70,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4A85F6), Color(0xFF2F58E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.newspaper_rounded, color: Colors.white54, size: 32),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['judul'] ?? 'Pengumuman',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['isi'] ?? '',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
    );
  }
}

class _NotificationSheet extends StatefulWidget {
  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  String selectedCategory = 'Semua';
  final categories = [
    {'icon': Icons.all_inbox_rounded, 'label': 'Semua', 'color': Colors.blue},
    {'icon': Icons.account_balance_wallet_rounded, 'label': 'Keuangan', 'color': Colors.orange},
    {'icon': Icons.menu_book_rounded, 'label': 'Akademik', 'color': Colors.green},
    {'icon': Icons.campaign_rounded, 'label': 'Promo', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat['label'] as String),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withValues(alpha: isSelected ? 0.2 : 0.05),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: cat['color'] as Color, width: 2) : null,
                        ),
                        child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<BerandaProvider>(
              builder: (context, beranda, _) {
                var notifs = beranda.pengumuman;
                
                // Simulate filtering based on text for demonstration since backend doesn't have categories yet
                if (selectedCategory != 'Semua') {
                  notifs = notifs.where((n) {
                    final txt = '${n['judul']} ${n['isi']}'.toLowerCase();
                    if (selectedCategory == 'Keuangan') return txt.contains('tagih') || txt.contains('bayar') || txt.contains('rp');
                    if (selectedCategory == 'Akademik') return txt.contains('jadwal') || txt.contains('tryout') || txt.contains('ujian') || txt.contains('nilai');
                    if (selectedCategory == 'Promo') return txt.contains('diskon') || txt.contains('promo') || txt.contains('gratis');
                    return false;
                  }).toList();
                }
                
                if (notifs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada notifikasi $selectedCategory',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    final item = notifs[index];
                    final isRead = beranda.isNotifRead(item['id'].toString());
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : Colors.blue.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isRead ? Colors.transparent : Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.grey.shade100 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.campaign_rounded, color: isRead ? Colors.grey.shade500 : Colors.blue.shade700, size: 28),
                        ),
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['judul'] ?? 'Pengumuman',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isRead ? Colors.grey.shade700 : const Color(0xFF1E293B)),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4, left: 8),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['isi'] ?? '',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Baru saja', // Ideally format real date
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (!isRead) {
                            beranda.markNotifAsRead(item['id'].toString());
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
