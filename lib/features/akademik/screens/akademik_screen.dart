import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/akademik_provider.dart';

// ignore: library_private_types_in_public_api
final GlobalKey<_AkademikScreenState> akademikScreenKey = GlobalKey<_AkademikScreenState>();

class AkademikScreen extends StatefulWidget {
  const AkademikScreen({super.key});

  @override
  State<AkademikScreen> createState() => _AkademikScreenState();
}

class _AkademikScreenState extends State<AkademikScreen> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AkademikProvider>(context, listen: false);
      if (provider.jadwal.isEmpty) provider.fetchJadwal();
      if (provider.absensi.isEmpty) provider.fetchAbsensi();
    });
  }

  void switchToTab(int index) {
    if (mounted && index >= 0 && index < 2) {
      _tabController.animateTo(index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('Akademik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Slate 100
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF2F58E5), // Primary EdTech Blue
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2F58E5).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Jadwal Kelas'),
                Tab(text: 'Riwayat Absensi'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _JadwalTab(),
          _AbsensiTab(),
        ],
      ),
    );
  }
}

class _JadwalTab extends StatelessWidget {
  const _JadwalTab();

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<AkademikProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingJadwal) {
          return _buildSkeletonLoading();
        }
        if (provider.errorJadwal != null) {
          return Center(child: Text(provider.errorJadwal!));
        }

        final jadwal = provider.jadwal;
        if (jadwal.isEmpty) {
          return const Center(child: Text('Tidak ada jadwal tersedia.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchJadwal(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jadwal.keys.length,
            itemBuilder: (context, index) {
              String hari = jadwal.keys.elementAt(index);
              List<dynamic> listMapel = jadwal[hari];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(hari, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                      initiallyExpanded: true,
                      iconColor: const Color(0xFF2F58E5),
                      children: listMapel.map((mapel) {
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2F58E5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mapel['mata_pelajaran']?['nama'] ?? 'Mata Pelajaran',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            mapel['guru'] != null ? '${mapel['guru']['name'] ?? mapel['guru']['nama'] ?? '-'}' : (mapel['rombel'] != null ? 'Kelas: ${mapel['rombel']['nama_kelompok'] ?? mapel['rombel']['nama'] ?? '-'}' : '-'),
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  '${mapel['jam_mulai']?.substring(0,5) ?? ''} - ${mapel['jam_selesai']?.substring(0,5) ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
            },
          ),
        );
      },
    );
  }
}

class _AbsensiTab extends StatelessWidget {
  const _AbsensiTab();

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AkademikProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingAbsensi) {
          return _buildSkeletonLoading();
        }
        if (provider.errorAbsensi != null) {
          return Center(child: Text(provider.errorAbsensi!));
        }

        final absensi = provider.absensi;
        if (absensi.isEmpty) {
          return const Center(child: Text('Tidak ada riwayat absensi.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAbsensi(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: absensi.length,
            itemBuilder: (context, index) {
              final item = absensi[index];
              final status = item['status_masuk'] ?? item['status'] ?? '';
              final jamMasuk = item['jam_masuk'] != null ? item['jam_masuk'].toString().substring(0, 5) : '-';
              final jamPulang = item['jam_pulang'] != null ? item['jam_pulang'].toString().substring(0, 5) : '-';
              
              Color statusColor;
              IconData statusIcon;
              if (status == 'hadir') { statusColor = Colors.green; statusIcon = Icons.check_circle_rounded; }
              else if (status == 'izin') { statusColor = Colors.blue; statusIcon = Icons.info_rounded; }
              else if (status == 'sakit') { statusColor = Colors.orange; statusIcon = Icons.local_hospital_rounded; }
              else { statusColor = Colors.red; statusIcon = Icons.cancel_rounded; }

              return InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 28),
                          const SizedBox(width: 8),
                          const Text('Detail Absensi', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Tanggal', item['tanggal'] != null ? item['tanggal'].toString().split('T')[0] : '-'),
                          _buildDetailRow('Status', status.toUpperCase()),
                          _buildDetailRow('Jam Masuk', jamMasuk),
                          _buildDetailRow('Jam Pulang', jamPulang),
                          _buildDetailRow('Catatan', item['keterangan'] ?? '-'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(statusIcon, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['tanggal'] != null ? item['tanggal'].toString().split('T')[0] : 'Tanggal tidak diketahui', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Masuk: $jamMasuk | Pulang: $jamPulang', 
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          const Text(': '),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }
}
