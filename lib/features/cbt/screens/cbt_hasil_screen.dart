import 'package:flutter/material.dart';

class CbtHasilScreen extends StatefulWidget {
  final double? skor;
  final List<dynamic> soalList;
  final Map<int, int?> jawaban; // bankSoalId -> opsiId yang dipilih user

  const CbtHasilScreen({
    super.key,
    required this.skor,
    required this.soalList,
    required this.jawaban,
  });

  @override
  State<CbtHasilScreen> createState() => _CbtHasilScreenState();
}

class _CbtHasilScreenState extends State<CbtHasilScreen> {
  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final skor = widget.skor ?? 0.0;
    final theme = Theme.of(context);

    // Hitung statistik
    int benar = 0, salah = 0, tidakDijawab = 0;
    for (final soal in widget.soalList) {
      final bankSoal = soal['bank_soal'] as Map<String, dynamic>? ?? {};
      final soalId = bankSoal['id'] as int? ?? 0;
      final opsiList = (bankSoal['opsi_jawabans'] as List<dynamic>?) ?? [];
      final kunciId = opsiList
          .where((o) => o['is_benar'] == true || o['is_benar'] == 1)
          .map((o) => o['id'] as int?)
          .firstOrNull;

      final userAnswer = widget.jawaban[soalId];
      if (userAnswer == null) {
        tidakDijawab++;
      } else if (userAnswer == kunciId) {
        benar++;
      } else {
        salah++;
      }
    }

    String skorLabel;
    if (skor >= 80) {
      skorLabel = 'Sangat Baik! 🎉';
    } else if (skor >= 60) {
      skorLabel = 'Cukup Baik 👍';
    } else {
      skorLabel = 'Perlu Belajar Lagi 📚';
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: const Text('Hasil Ujian', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewPadding.bottom),
          child: Column(
            children: [
              // ── Kartu Skor Utama ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Ujian Selesai!', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    Text(
                      skor.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(skorLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Statistik ──
              Row(
                children: [
                  _statCard('Benar', benar, Colors.green, Icons.check_circle_rounded),
                  const SizedBox(width: 12),
                  _statCard('Salah', salah, Colors.red, Icons.cancel_rounded),
                  const SizedBox(width: 12),
                  _statCard('Kosong', tidakDijawab, Colors.grey, Icons.radio_button_unchecked),
                ],
              ),

              const SizedBox(height: 24),

              // ── Pembahasan ──
              Row(
                children: [
                  const Text('Pembahasan Soal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const Spacer(),
                  Text('${widget.soalList.length} soal', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 12),

              ...widget.soalList.asMap().entries.map((entry) {
                final index = entry.key;
                final soal = entry.value;
                final bankSoal = soal['bank_soal'] as Map<String, dynamic>? ?? {};
                final soalId = bankSoal['id'] as int? ?? 0;
                final opsiList = (bankSoal['opsi_jawabans'] as List<dynamic>?) ?? [];
                // Pembahasan ada di relasi cbt_pembahasans (HasOne)
                final pembahasanRelasi = bankSoal['pembahasan'] as Map<String, dynamic>?;
                final pembahasan = pembahasanRelasi?['teks_pembahasan'] as String?;

                final kunci = opsiList.where((o) => o['is_benar'] == true || o['is_benar'] == 1).firstOrNull;
                final kunciId = kunci?['id'] as int?;
                final userAnswer = widget.jawaban[soalId];

                final isBenar = userAnswer != null && userAnswer == kunciId;
                final isDijawab = userAnswer != null;
                final isExpanded = _expandedIndex == index;

                Color statusColor = isDijawab ? (isBenar ? Colors.green : Colors.red) : Colors.grey;
                IconData statusIcon = isDijawab ? (isBenar ? Icons.check_circle : Icons.cancel) : Icons.remove_circle_outline;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header soal
                      InkWell(
                        onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  bankSoal['pertanyaan'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(statusIcon, color: statusColor, size: 22),
                              const SizedBox(width: 4),
                              Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),

                      // Detail pembahasan (collapsed/expanded)
                      if (isExpanded) ...[
                        Divider(height: 1, color: Colors.grey.shade100),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Opsi jawaban
                              ...opsiList.map((opsi) {
                                final opsiId = opsi['id'] as int?;
                                final isKunci = opsiId == kunciId;
                                final isUserPilih = opsiId == userAnswer;

                                Color bgColor = Colors.transparent;
                                Color borderColor = Colors.grey.shade200;
                                Color textColor = const Color(0xFF475569);

                                if (isKunci) {
                                  bgColor = Colors.green.shade50;
                                  borderColor = Colors.green.shade300;
                                  textColor = Colors.green.shade800;
                                } else if (isUserPilih && !isKunci) {
                                  bgColor = Colors.red.shade50;
                                  borderColor = Colors.red.shade300;
                                  textColor = Colors.red.shade800;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(opsi['teks_opsi'] ?? '', style: TextStyle(fontSize: 13, color: textColor))),
                                      if (isKunci) Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                                      if (isUserPilih && !isKunci) Icon(Icons.cancel, size: 16, color: Colors.red.shade600),
                                    ],
                                  ),
                                );
                              }),

                              // Pembahasan
                              if (pembahasan != null && pembahasan.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.lightbulb_rounded, size: 14, color: Color(0xFF0284C7)),
                                          SizedBox(width: 4),
                                          Text('Pembahasan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(pembahasan, style: const TextStyle(fontSize: 13, color: Color(0xFF0C4A6E), height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Kembali ke Beranda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
