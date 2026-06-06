import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keuangan_provider.dart';
import '../../../core/utils/custom_toast.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({super.key});

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<KeuanganProvider>(context, listen: false);
      if (provider.tagihan == null) provider.fetchTagihan();
      if (provider.riwayat.isEmpty) provider.fetchRiwayat();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          title: const Text('Keuangan'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_rounded, size: 20), SizedBox(width: 8), Text('Tagihan', style: TextStyle(fontWeight: FontWeight.bold))])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_rounded, size: 20), SizedBox(width: 8), Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold))])),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _TagihanTab(),
            _RiwayatTab(),
          ],
        ),
      ),
    );
  }
}

class _TagihanTab extends StatelessWidget {
  const _TagihanTab();

  String formatRupiah(dynamic amount) {
    if (amount == null) return '0';
    String str = amount.toString().replaceAll(RegExp(r'\D'), '');
    if (str.isEmpty) return '0';
    return str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<KeuanganProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingTagihan) {
          return _buildSkeletonLoading();
        }
        if (provider.errorTagihan != null) {
          return Center(child: Text(provider.errorTagihan!));
        }

        final tagihan = provider.tagihan;
        if (tagihan == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                ),
                const SizedBox(height: 24),
                const Text('Hore! Tidak ada tagihan aktif.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        final lunas = tagihan['lunas'] == true;

        return RefreshIndicator(
          onRefresh: () => provider.fetchTagihan(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
                ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total Tagihan SPP',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${formatRupiah((tagihan['kekurangan'] ?? 0) - (tagihan['total_menunggu'] ?? 0))}',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDetailRow('Total Biaya', 'Rp ${formatRupiah(tagihan['total_harus_dibayar'])}', theme),
                      Divider(height: 24, color: Colors.white.withValues(alpha: 0.05)),
                      _buildDetailRow('Telah Dibayar', 'Rp ${formatRupiah(tagihan['total_terbayar'])}', theme),
                      if ((tagihan['total_menunggu'] ?? 0) > 0) ...[
                        Divider(height: 24, color: Colors.white.withValues(alpha: 0.05)),
                        _buildDetailRow('Menunggu Konfirmasi', 'Rp ${formatRupiah(tagihan['total_menunggu'])}', theme),
                      ],
                      Divider(height: 24, color: Colors.white.withValues(alpha: 0.05)),
                      _buildDetailRow('Batas Waktu', tagihan['batas_waktu'] ?? 'Tidak ada', theme),
                      
                      const SizedBox(height: 32),
                      if (!lunas && ((tagihan['kekurangan'] ?? 0) - (tagihan['total_menunggu'] ?? 0)) > 0)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => _PembayaranBottomSheet(tagihan: tagihan),
                            );
                          },
                          child: const Text('BAYAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        )
                      else if ((tagihan['total_menunggu'] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_empty_rounded, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('MENUNGGU KONFIRMASI ADMIN', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green),
                              SizedBox(width: 8),
                              Text('STATUS: LUNAS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 14)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
      ],
    );
  }
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 1,
      itemBuilder: (context, index) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _RiwayatTab extends StatelessWidget {
  const _RiwayatTab();

  String formatRupiah(dynamic amount) {
    if (amount == null) return '0';
    String str = amount.toString().replaceAll(RegExp(r'\D'), '');
    if (str.isEmpty) return '0';
    return str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> item) {
    String rawDate = item['tanggal'] ?? item['created_at'] ?? '';
    String displayDate = rawDate;
    if (rawDate.length >= 10) {
      displayDate = rawDate.substring(0, 10);
    }
    String noKwitansi = item['no_kwitansi'] ?? 'INV-${item['id'] ?? '000'}';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              const Text('Struk Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('No. Kwitansi', style: TextStyle(color: Colors.grey)),
                Text(noKwitansi, style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tanggal', style: TextStyle(color: Colors.grey)),
                Text(displayDate, style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Metode', style: TextStyle(color: Colors.grey)),
                Text(item['tipe_pembayaran'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Penerima', style: TextStyle(color: Colors.grey)),
                Text(item['penerima'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const Divider(height: 32),
              const Text('TOTAL BAYAR', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text('Rp ${formatRupiah(item['nominal'])}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('SELESAI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectionDialog(BuildContext context, Map<String, dynamic> item) {
    String alasan = item['alasan_penolakan'] ?? item['catatan_siswa'] ?? 'Tidak ada keterangan/alasan dari admin.';
    if (alasan.startsWith('Ditolak: ')) {
      alasan = alasan.replaceFirst('Ditolak: ', '');
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Pembayaran Ditolak', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 24),
              const Text('Alasan Penolakan:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(alasan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('MENGERTI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KeuanganProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingRiwayat) {
          return _buildSkeletonLoading();
        }
        if (provider.errorRiwayat != null) {
          return Center(child: Text(provider.errorRiwayat!));
        }

        final riwayat = provider.riwayat;
        if (riwayat.isEmpty) {
          return const Center(child: Text('Belum ada riwayat pembayaran.'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchRiwayat(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: riwayat.length,
          itemBuilder: (context, index) {
            final item = riwayat[index];
            final statusStr = item['status'] ?? '';
            final isConfirmed = statusStr == 'SUKSES';
            final isDitolak = statusStr == 'DITOLAK' || statusStr == 'BATAL';
            
            Color statusColor = isConfirmed ? Colors.green : (isDitolak ? Colors.red : Colors.orange);
            IconData statusIcon = isConfirmed ? Icons.check_circle_rounded : (isDitolak ? Icons.cancel_rounded : Icons.access_time_filled_rounded);

            // Format date correctly
            String rawDate = item['tanggal'] ?? item['created_at'] ?? '';
            String displayDate = rawDate;
            if (rawDate.length >= 10) {
              displayDate = rawDate.substring(0, 10);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ListTile(
                onTap: () {
                  if (isConfirmed) {
                    _showReceiptDialog(context, item);
                  } else if (isDitolak) {
                    _showRejectionDialog(context, item);
                  } else {
                    CustomToast.showInfo(context, 'Pembayaran masih berstatus $statusStr');
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(statusIcon, color: statusColor),
                ),
                title: Text('Rp ${formatRupiah(item['nominal'])}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$displayDate â€¢ ${item['tipe_pembayaran'] ?? ''}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 12)),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    statusStr,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
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
}

class _PembayaranBottomSheet extends StatefulWidget {
  final Map<String, dynamic> tagihan;
  const _PembayaranBottomSheet({required this.tagihan});

  @override
  State<_PembayaranBottomSheet> createState() => _PembayaranBottomSheetState();
}

class _PembayaranBottomSheetState extends State<_PembayaranBottomSheet> {
  final TextEditingController _nominalController = TextEditingController();
  int? _selectedBankId;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;  // For reliable preview
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final sisa = (widget.tagihan['kekurangan'] ?? 0) - (widget.tagihan['total_menunggu'] ?? 0);
    String initialText = sisa.toString();
    _nominalController.text = initialText.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KeuanganProvider>(context, listen: false).fetchBanks();
    });
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Sumber Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6366F1)),
              title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF6366F1)),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = File(image.path);
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedBankId == null || _selectedImage == null || _nominalController.text.isEmpty) {
      CustomToast.showWarning(context, 'Harap lengkapi semua data dan bukti transfer!');
      return;
    }

    final provider = Provider.of<KeuanganProvider>(context, listen: false);
    final kekurangan = provider.tagihan?['kekurangan'];
    final menunggu = provider.tagihan?['total_menunggu'] ?? 0;
    if (kekurangan != null) {
      final sisaBolehDibayar = kekurangan - menunggu;
      final cleanNominalStr = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final parsedNominal = int.tryParse(cleanNominalStr) ?? 0;
      if (parsedNominal > sisaBolehDibayar) {
        final formattedSisa = sisaBolehDibayar.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
        CustomToast.showError(context, 'Nominal tidak boleh melebihi sisa tagihan (Maks: Rp $formattedSisa).');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    final success = await provider.submitPembayaran(_nominalController.text, _selectedBankId!, _selectedImage!.path);
    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) Navigator.pop(context);
      if (mounted) CustomToast.showSuccess(context, 'Pengajuan pembayaran berhasil dikirim!');
    } else {
      final errMsg = provider.submitError ?? 'Gagal mengirim pengajuan. Coba lagi.';
      if (mounted) CustomToast.showError(context, errMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeuanganProvider>(context);
    final banks = provider.banks;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pengajuan Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Anda juga dapat melakukan pembayaran secara tunai langsung ke kantor Bimbingan Belajar.', style: TextStyle(fontSize: 12, color: Colors.blue))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text('Sisa Tagihan Anda', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${((widget.tagihan['kekurangan'] ?? 0) - (widget.tagihan['total_menunggu'] ?? 0)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', 
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 24)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nominal Pembayaran (Rp)', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                GestureDetector(
                  onTap: () {
                    final sisa = (widget.tagihan['kekurangan'] ?? 0) - (widget.tagihan['total_menunggu'] ?? 0);
                    _nominalController.text = sisa.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Bayar Lunas', style: TextStyle(color: Colors.indigo, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                hintText: 'Contoh: 150.000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Text('Bank Tujuan Transfer', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 12),
            provider.isLoadingBanks
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: banks.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final bank = banks[index];
                        final isSelected = _selectedBankId == bank['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedBankId = bank['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo.withValues(alpha: 0.05) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.indigo : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(bank['nama_bank'] ?? 'Bank', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.indigo : Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(bank['nomor_rekening'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 16),
            Text('Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 130),
                decoration: BoxDecoration(
                  color: _selectedImageBytes != null ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedImageBytes != null ? Colors.indigo.shade300 : Colors.grey.shade300,
                    width: _selectedImageBytes != null ? 2 : 1,
                  ),
                ),
                child: _selectedImageBytes != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 24),
                          Icon(Icons.add_photo_alternate_rounded, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Ketuk untuk Upload Bukti Transfer', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(height: 24),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('KIRIM PENGAJUAN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Remove all non-digits
    String cleanString = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Add dots every 3 digits from the right
    String formattedString = cleanString.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    // Calculate the offset
    int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
    
    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length - selectionIndexFromTheRight),
    );
  }
}
