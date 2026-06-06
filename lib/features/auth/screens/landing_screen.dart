import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import '../../../core/api_client.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _d = {};
  List<dynamic> _pakets = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await _apiClient.dio.get('/landing');
      if (r.statusCode == 200 && r.data['success'] == true) {
        setState(() {
          _d = r.data['data'] ?? {};
          _pakets = _d['pakets'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _rp(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      c++;
      if (c % 3 == 0 && i != 0) buf.write('.');
    }
    return 'Rp ${buf.toString().split('').reversed.join()}';
  }

  // Shorthand getters
  String get _nama => _d['nama_lembaga'] ?? 'Genius Education';
  String get _heroTitle => _d['hero_title'] ?? 'Wujudkan Impian Akademik Bersama Kami';
  String get _heroSub => _d['hero_subtitle'] ?? 'Platform pembelajaran terintegrasi yang memudahkan manajemen pendaftaran, progres belajar, dan evaluasi hasil belajar.';
  String get _tentang => _d['tentang_kami'] ?? 'Kami adalah institusi pendidikan yang berdedikasi tinggi dalam menyediakan bimbingan belajar berkualitas dengan teknologi informasi terkini.';
  String? get _logoUrl => _d['logo_url'];
  String? get _heroImgUrl => _d['hero_image_url'];

  // ─── Colors ───
  static const _indigo = Color(0xFF4F46E5);
  static const _indigoDark = Color(0xFF3730A3);
  static const _slate900 = Color(0xFF0F172A);
  static const _slate50 = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: _indigo)));
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _slate50,
        body: SingleChildScrollView(
          child: Column(children: [
            _heroSection(),
            _programSection(),
            _aboutSection(),
            _footerSection(),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  1. HERO  (dark bg + image, like website)
  // ════════════════════════════════════════════
  Widget _heroSection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 420),
      child: Stack(
        children: [
          // Background
          Positioned.fill(
            child: _heroImgUrl != null
                ? Stack(children: [
                    Image.network(_heroImgUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                        errorBuilder: (_, _, _) => Container(color: _slate900)),
                    Container(color: Colors.black.withValues(alpha: 0.5)),
                  ])
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_indigoDark, _slate900, Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
          ),
          // Content
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Column(
                children: [
                  // Navbar row
                  Row(
                    children: [
                      if (_logoUrl != null) ...[
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_logoUrl!, height: 28, width: 28, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(_nama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: PopupMenuThemeData(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                          ),
                        ),
                        child: PopupMenuButton<int>(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          offset: const Offset(0, 48),
                          onSelected: (value) async {
                            if (value == 1) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                            } else if (value == 2) {
                              final baseUrl = _apiClient.dio.options.baseUrl.split('/api').first;
                              final url = Uri.parse('$baseUrl/daftar/step1');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 1,
                              child: Row(
                                children: [
                                  Icon(Icons.login_rounded, size: 20, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 12),
                                  Text('Masuk Ke Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 2,
                              child: Row(
                                children: [
                                  Icon(Icons.person_add_rounded, size: 20, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 12),
                                  Text('Daftar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  // Title
                  Text(
                    _heroTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _heroSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.75), height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 28),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  2. PROGRAM BIMBINGAN UNGGULAN
  // ════════════════════════════════════════════
  Widget _programSection() {
    return Container(
      width: double.infinity,
      color: _slate50,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Program Bimbingan Unggulan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _slate900, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Text('Pilih jalur bimbingan yang sesuai dengan target dan kebutuhan akademikmu.',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 20),
          if (_pakets.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.shade200, width: 2, strokeAlign: BorderSide.strokeAlignInside)),
              child: const Text('Belum Ada Program', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: _slate900)),
            )
          else
            ..._pakets.map((p) => _paketCard(p as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _paketCard(Map<String, dynamic> p) {
    final nama = p['nama_paket'] ?? '';
    final target = p['target_peserta'] ?? 'Semua Jenjang';
    final nominal = p['nominal'] as int? ?? 0;
    final hargaCoret = p['harga_coret'] as int?;
    final durasiJml = p['durasi_jumlah'];
    final durasiSat = p['durasi_satuan'];
    final labelPop = p['label_populer'] as String?;
    final allBenefits = (p['benefits'] as List<dynamic>?)?.cast<String>() ?? [];
    final benefits = allBenefits.take(3).toList();
    final gambarUrl = p['gambar_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPaketDetail(p);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Image header
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: gambarUrl != null
                    ? Image.network(gambarUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _gradientPlaceholder())
                    : _gradientPlaceholder(),
              ),
              // Dark overlay
              Positioned.fill(child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
              )),
              // Discount badge
              if (hargaCoret != null && hargaCoret > nominal)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('${((hargaCoret - nominal) / hargaCoret * 100).round()}% OFF', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
              // Popular label
              if (labelPop != null && labelPop.isNotEmpty)
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(20)),
                    child: Text('✨ $labelPop', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _slate900)),
                const SizedBox(height: 2),
                Text(target.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _indigo, letterSpacing: 2)),
                const SizedBox(height: 16),
                // Benefits
                if (benefits.isNotEmpty) ...[
                  ...benefits.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(color: Colors.yellow.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.star_rounded, size: 12, color: Colors.yellow.shade700),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(b.trim(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, height: 1.3))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
                // Price box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _slate50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hargaCoret != null && hargaCoret > nominal)
                        Text(_rp(hargaCoret), style: TextStyle(fontSize: 10, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(_rp(nominal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _indigo, height: 1.1)),
                            ),
                          ),
                          if (durasiJml != null) ...[
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('/ $durasiJml $durasiSat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6366F1), _indigoDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Icon(Icons.school_rounded, size: 48, color: Colors.white.withValues(alpha: 0.15))),
    );
  }

  // ════════════════════════════════════════════
  //  3. ABOUT — Visi & Misi + Tentang Kami
  // ════════════════════════════════════════════
  Widget _aboutSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0E7FF))),
            child: const Text('PROFIL INSTITUSI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _indigo, letterSpacing: 2)),
          ),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _slate900, height: 1.15),
              children: [
                TextSpan(text: 'Ekosistem Belajar '),
                TextSpan(text: 'Modern', style: TextStyle(color: _indigo, decoration: TextDecoration.underline, decorationColor: Color(0xFFC7D2FE))),
                TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(_tentang, style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.7, fontWeight: FontWeight.w500)),
          const SizedBox(height: 28),
          // Visi & Misi Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _slate50,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.grey.shade200.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visi
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _indigo, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 8)]),
                    child: const Center(child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                  ),
                  const SizedBox(width: 12),
                  const Text('Visi Kami', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _slate900)),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(left: 16),
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: _indigo, width: 3))),
                  child: Text(
                    '"Menjadi lembaga pendidikan terdepan yang mengintegrasikan teknologi modern dengan metode pembelajaran efektif."',
                    style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade600, height: 1.6),
                  ),
                ),
                const SizedBox(height: 28),
                // Misi
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _indigo, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.3), blurRadius: 8)]),
                    child: const Center(child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
                  ),
                  const SizedBox(width: 12),
                  const Text('Misi Institusi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _slate900)),
                ]),
                const SizedBox(height: 16),
                ...['Fasilitas Pembelajaran Digital', 'Kurikulum Adaptif Standar Tinggi', 'Evaluasi Sistem CBT Akurat']
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4)]),
                              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: _indigo, fontWeight: FontWeight.w900, fontSize: 11))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(e.value.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1, height: 1.4))),
                          ]),
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  4. FOOTER (dark, matching website)
  // ════════════════════════════════════════════
  Widget _footerSection() {
    return Container(
      width: double.infinity,
      color: _slate900,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + name
          Row(children: [
            if (_logoUrl != null)
              Container(
                width: 44, height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Image.network(_logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.school, color: _indigo)),
              )
            else
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('G', style: TextStyle(color: _indigo, fontWeight: FontWeight.w900, fontSize: 22))),
              ),
            const SizedBox(width: 12),
            Expanded(child: Text(_nama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
          ]),
          const SizedBox(height: 14),
          Text(_heroSub, style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5)),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© ${DateTime.now().year} $_nama.\nSistem Manajemen Pendidikan Terpadu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, height: 1.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaketDetail(Map<String, dynamic> p) {
    final nama = p['nama_paket'] ?? '';
    final target = p['target_peserta'] ?? 'Semua Jenjang';
    final nominal = p['nominal'] as int? ?? 0;
    final hargaCoret = p['harga_coret'] as int?;
    final durasiJml = p['durasi_jumlah'];
    final durasiSat = p['durasi_satuan'];
    final allBenefits = (p['benefits'] as List<dynamic>?)?.cast<String>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Text(target.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5), letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(nama, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hargaCoret != null && hargaCoret > nominal)
                          Text(_rp(hargaCoret), style: TextStyle(fontSize: 12, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold)),
                        Text(_rp(nominal), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5), height: 1.1)),
                      ],
                    ),
                  ),
                  if (durasiJml != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF4F46E5).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('$durasiJml $durasiSat', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
                    ),
                ],
              ),
            ),
            if (allBenefits.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Fasilitas & Keunggulan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              ...allBenefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(b.trim(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700, height: 1.4))),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Tutup modal
                  final baseUrl = _apiClient.dio.options.baseUrl.split('/api').first;
                  final url = Uri.parse('$baseUrl/daftar/step1');
                  if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('DAFTAR SEKARANG', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
