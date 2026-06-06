import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cbt_provider.dart';
import 'cbt_exam_screen.dart';
import 'cbt_hasil_screen.dart';

class CbtScreen extends StatefulWidget {
  const CbtScreen({super.key});

  @override
  State<CbtScreen> createState() => _CbtScreenState();
}

class _CbtScreenState extends State<CbtScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final provider = Provider.of<CbtProvider>(context, listen: false);
    await provider.fetchDaftarUjian();
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// Format ISO date string menjadi format lokal yang readable
  String _formatTanggal(String? isoString) {
    if (isoString == null || isoString == '-') return '-';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final tgl = dt.day.toString().padLeft(2, '0');
      final bln = bulan[dt.month];
      final thn = dt.year;
      final jam = dt.hour.toString().padLeft(2, '0');
      final mnt = dt.minute.toString().padLeft(2, '0');
      return '$tgl $bln $thn, $jam:$mnt WIB';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Daftar Ujian (CBT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: Consumer<CbtProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildSkeletonLoading();
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final daftarUjian = provider.daftarUjian;
          if (daftarUjian.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  ),
                  const SizedBox(height: 24),
                  const Text('Hore! Tidak ada ujian aktif saat ini.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: daftarUjian.length,
              itemBuilder: (context, index) {
                final ujian = daftarUjian[index];
                final statusPeserta = ujian['status_peserta'] as String?;
                final skorPeserta = ujian['skor_peserta'];
                final sudahSelesai = statusPeserta == 'selesai' || statusPeserta == 'timeout';
                final sedangMengerjakan = statusPeserta == 'mengerjakan';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: sudahSelesai
                          ? Colors.green.shade200
                          : sedangMengerjakan
                              ? Colors.orange.shade200
                              : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header Ticket
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: sudahSelesai
                              ? Colors.green.shade50
                              : sedangMengerjakan
                                  ? Colors.orange.shade50
                                  : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: sudahSelesai
                                    ? Colors.green.shade100
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                sudahSelesai ? Icons.check_circle_rounded : Icons.description_rounded,
                                color: sudahSelesai ? Colors.green.shade600 : const Color(0xFF2F58E5),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ujian['judul'] ?? 'Ujian Tanpa Judul',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (ujian['mode'] == 'resmi')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text('RESMI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange.shade200),
                                        ),
                                        child: Text(
                                          '${ujian['durasi'] ?? 0} Menit',
                                          style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (sudahSelesai) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.shade200),
                                          ),
                                          child: Text(
                                            'Selesai âœ“',
                                            style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                      if (sedangMengerjakan) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange.shade200),
                                          ),
                                          child: Text(
                                            'â³ Sedang Dikerjakan',
                                            style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
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

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
                      ),

                      // Body Ticket
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.green.shade400),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Mulai: ${_formatTanggal(ujian['waktu_mulai'])}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.stop_circle_rounded, size: 18, color: Colors.red.shade400),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Batas: ${_formatTanggal(ujian['waktu_selesai'])}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Tampilkan skor jika sudah selesai
                            if (sudahSelesai && skorPeserta != null && (ujian['tampilkan_hasil'] == 1 || ujian['tampilkan_hasil'] == true)) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade400, Colors.green.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Nilai Kamu', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                        Text(
                                          (skorPeserta as num).toStringAsFixed(1),
                                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Tombol aksi
                            SizedBox(
                              width: double.infinity,
                              child: sudahSelesai
                                  ? ((ujian['tampilkan_hasil'] == 1 || ujian['tampilkan_hasil'] == true) 
                                      ? ElevatedButton.icon(
                                          onPressed: () async {
                                            // Tampilkan loading
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => const Center(child: CircularProgressIndicator()),
                                            );
                                            
                                            final navigator = Navigator.of(context);
                                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                                            final provider = Provider.of<CbtProvider>(context, listen: false);
                                            
                                            final hasil = await provider.fetchHasil(ujian['id'] as int);
                                            
                                            navigator.pop(); // tutup loading spinner
  
                                            if (hasil != null) {
                                              final soalList = (hasil['soal'] as List<dynamic>?) ?? [];
                                              final skor = (hasil['skor'] as num?)?.toDouble();
  
                                              final Map<int, int?> jawabanMap = {};
                                              for (final s in soalList) {
                                                final bankSoalId = (s['bank_soal'] as Map<String, dynamic>?)?['id'] as int? ?? 0;
                                                final opsiId = s['cbt_opsi_jawaban_id'] as int?;
                                                jawabanMap[bankSoalId] = opsiId;
                                              }
  
                                              navigator.push(
                                                MaterialPageRoute(
                                                  builder: (_) => CbtHasilScreen(
                                                    skor: skor,
                                                    soalList: soalList,
                                                    jawaban: jawabanMap,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(provider.errorMessage ?? 'Gagal memuat hasil ujian'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.bar_chart_rounded),
                                          label: const Text('LIHAT HASIL & PEMBAHASAN'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Text(
                                            'HASIL UJIAN DISEMBUNYIKAN',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                          ),
                                        ))
                                  : ElevatedButton(
                                      onPressed: () async {
                                        final token = ujian['token'];
                                        if (token != null && token.toString().trim().isNotEmpty) {
                                          final TextEditingController tokenController = TextEditingController();
                                          final bool? proceed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Token Ujian Required', style: TextStyle(fontWeight: FontWeight.bold)),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text('Ujian ini dilindungi oleh Token. Silakan masukkan token yang valid untuk memulai.'),
                                                  const SizedBox(height: 16),
                                                  TextField(
                                                    controller: tokenController,
                                                    decoration: InputDecoration(
                                                      hintText: 'Masukkan Token',
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Batal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (tokenController.text.trim() == token.toString().trim()) {
                                                      Navigator.pop(context, true);
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Token tidak valid!'), backgroundColor: Colors.red),
                                                      );
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F58E5), foregroundColor: Colors.white),
                                                  child: const Text('Verifikasi'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (proceed != true) return;
                                        }
                                        
                                        if (!context.mounted) return;
                                        
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CbtExamScreen(ujianId: ujian['id']),
                                          ),
                                        );
                                        _refresh();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: sedangMengerjakan
                                            ? Colors.orange.shade600
                                            : const Color(0xFF2F58E5),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: Text(
                                        sedangMengerjakan ? 'LANJUTKAN UJIAN' : 'KERJAKAN SEKARANG',
                                        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
