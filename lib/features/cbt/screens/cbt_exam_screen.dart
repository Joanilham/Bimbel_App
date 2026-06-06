import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/cbt_provider.dart';
import '../../../core/utils/custom_toast.dart';
import 'cbt_hasil_screen.dart';

class CbtExamScreen extends StatefulWidget {
  final int ujianId;
  const CbtExamScreen({super.key, required this.ujianId});

  @override
  State<CbtExamScreen> createState() => _CbtExamScreenState();
}

class _CbtExamScreenState extends State<CbtExamScreen> {
  int _currentIndex = 0;
  Timer? _timer;
  Duration _remainingTime = const Duration(seconds: 0);
  final Map<int, int?> _jawaban = {}; // bank_soal_id -> opsi_id
  final Map<int, bool> _raguRagu = {}; // bank_soal_id -> isRagu

  @override
  void initState() {
    super.initState();
    _secureScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSoal();
    });
  }

  Future<void> _loadSoal() async {
    final provider = Provider.of<CbtProvider>(context, listen: false);
    final success = await provider.fetchSoal(widget.ujianId);
    if (success) {
      _setupTimer();
      // Inisialisasi jawaban jika sudah ada (bisa dikembangkan jika API mengembalikan riwayat jawaban)
    } else {
      if (mounted) {
        CustomToast.showError(context, provider.errorMessage ?? 'Gagal memuat ujian');
        Navigator.pop(context);
      }
    }
  }

  void _setupTimer() {
    final provider = Provider.of<CbtProvider>(context, listen: false);
    final peserta = provider.activePeserta;
    final ujian = provider.activeUjian;
    if (peserta == null || ujian == null) return;

    DateTime waktuMulai = DateTime.parse(peserta['waktu_mulai']).toLocal();
    int durasiMenit = ujian['durasi'] ?? 0;
    DateTime waktuSelesai = waktuMulai.add(Duration(minutes: durasiMenit));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(waktuSelesai)) {
        timer.cancel();
        _selesaiUjian(otomatis: true);
      } else {
        setState(() {
          _remainingTime = waktuSelesai.difference(now);
        });
      }
    });
  }

  Future<void> _secureScreen() async {
    try {
      await const MethodChannel('com.example.cbt_app/secure').invokeMethod('secure');
    } catch (_) {}
  }

  Future<void> _unsecureScreen() async {
    try {
      await const MethodChannel('com.example.cbt_app/secure').invokeMethod('unsecure');
    } catch (_) {}
  }

  @override
  void dispose() {
    _unsecureScreen();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pilihJawaban(int bankSoalId, int opsiId) async {
    setState(() {
      _jawaban[bankSoalId] = opsiId;
    });
    // Simpan ke server di background
    Provider.of<CbtProvider>(context, listen: false).submitJawaban(
      widget.ujianId,
      bankSoalId,
      opsiId,
      raguRagu: _raguRagu[bankSoalId] ?? false,
    );
  }

  void _toggleRaguRagu(int bankSoalId) {
    setState(() {
      _raguRagu[bankSoalId] = !(_raguRagu[bankSoalId] ?? false);
    });
    Provider.of<CbtProvider>(context, listen: false).submitJawaban(
      widget.ujianId,
      bankSoalId,
      _jawaban[bankSoalId],
      raguRagu: _raguRagu[bankSoalId] ?? false,
    );
  }

  Future<void> _selesaiUjian({bool otomatis = false}) async {
    if (!otomatis) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selesai Ujian?'),
          content: const Text('Pastikan semua soal telah terjawab. Anda tidak dapat mengubah jawaban setelah menyelesaikan ujian.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('SELESAI'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    _timer?.cancel();
    if (!mounted) return;
    final provider = Provider.of<CbtProvider>(context, listen: false);
    // Simpan soalList sebelum di-reset oleh provider
    final soalSnapshot = List<dynamic>.from(provider.soalList);
    final jawabanSnapshot = Map<int, int?>.from(_jawaban);

    final result = await provider.selesaiUjian(widget.ujianId);
    if (mounted) {
      if (result != null) {
        // Navigasi ke halaman hasil & pembahasan
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CbtHasilScreen(
              skor: result['skor'] as double?,
              soalList: result['soal'] as List<dynamic>? ?? soalSnapshot,
              jawaban: jawabanSnapshot,
            ),
          ),
        );
      } else {
        CustomToast.showError(context, 'Gagal menyelesaikan ujian, coba lagi.');
      }
    }
  }

  void _showGridSoal() {
    final provider = Provider.of<CbtProvider>(context, listen: false);
    final soalList = provider.soalList;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Navigasi Soal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: soalList.length,
                  itemBuilder: (context, index) {
                    final soalId = soalList[index]['bank_soal']['id'];
                    final isAnswered = _jawaban[soalId] != null;
                    final isRagu = _raguRagu[soalId] == true;

                    Color bgColor = Colors.white;
                    Color textColor = Colors.black;
                    Color borderColor = Colors.grey.shade300;

                    if (index == _currentIndex) {
                      borderColor = Theme.of(context).colorScheme.primary;
                      bgColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
                    } else if (isRagu) {
                      bgColor = Colors.orange;
                      textColor = Colors.white;
                      borderColor = Colors.orange;
                    } else if (isAnswered) {
                      bgColor = Colors.green;
                      textColor = Colors.white;
                      borderColor = Colors.green;
                    }

                    return InkWell(
                      onTap: () {
                        setState(() => _currentIndex = index);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: borderColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CbtProvider>(context);
    final theme = Theme.of(context);

    if (provider.isLoading && provider.soalList.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    if (provider.soalList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('CBT Ujian')),
        body: Center(child: Text(provider.errorMessage ?? 'Soal tidak tersedia')),
      );
    }

    final currentSoal = provider.soalList[_currentIndex];
    final bankSoal = currentSoal['bank_soal'] as Map<String, dynamic>? ?? {};
    // Laravel mengirim relasi sebagai 'opsi_jawabans' (snake_case dari opsiJawabans)
    final opsiJawaban = (bankSoal['opsi_jawabans'] as List<dynamic>?) ?? [];
    final soalId = bankSoal['id'] as int? ?? 0;

    String duaDigit(int n) => n.toString().padLeft(2, "0");
    String sisaWaktu = "${duaDigit(_remainingTime.inHours)}:${duaDigit(_remainingTime.inMinutes.remainder(60))}:${duaDigit(_remainingTime.inSeconds.remainder(60))}";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        CustomToast.showWarning(context, 'Silakan klik Selesai Ujian terlebih dahulu');
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(sisaWaktu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                onPressed: _showGridSoal,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Indikator Progress
            LinearProgressIndicator(
              value: (_currentIndex + 1) / provider.soalList.length,
              backgroundColor: Colors.grey.shade200,
              color: theme.colorScheme.secondary,
              minHeight: 6,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Soal ${_currentIndex + 1} dari ${provider.soalList.length}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () => _toggleRaguRagu(soalId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (_raguRagu[soalId] == true) ? Colors.orange.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.flag_rounded, size: 16, color: (_raguRagu[soalId] == true) ? Colors.orange : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('Ragu-ragu', style: TextStyle(color: (_raguRagu[soalId] == true) ? Colors.orange : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Text(
                        bankSoal['pertanyaan'] ?? '',
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Opsi Jawaban
                    ...opsiJawaban.map((opsi) {
                      bool isSelected = _jawaban[soalId] == opsi['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _pilihJawaban(soalId, opsi['id']),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                    border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400, width: 2),
                                  ),
                                  child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    opsi['teks_opsi'] ?? '',
                                    style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation
            Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentIndex--),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('SEBELUMNYA'),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                    
                  const SizedBox(width: 16),
                  
                  if (_currentIndex < provider.soalList.length - 1)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _currentIndex++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('SELANJUTNYA'),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selesaiUjian(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('SELESAI'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
