import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/landing_screen.dart';
import 'edit_profile_screen.dart';
import '../../../core/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      if (provider.userProfile == null) provider.fetchProfile();
    });
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardTheme.color,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Keluar dari Akun?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Anda akan keluar dari aplikasi. Silakan login kembali untuk mengakses fitur.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LandingScreen()),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      if (!mounted) return;
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await provider.updateProfilePhoto(pickedFile.path);
      if (mounted && !success && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
      } else if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui!')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = provider.userProfile;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 52, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Gagal memuat profil', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchProfile(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }

          final namaUser = user['name'] ?? 'Nama Pengguna';
          final email = user['email'] ?? '-';

          String? getPhotoUrl() {
            if (user['photo'] == null || user['photo'].toString().isEmpty) return null;
            final photo = user['photo'].toString();
            if (photo.startsWith('http')) return '$photo?v=${provider.photoVersion}';
            
            final baseUrl = ApiClient.baseUrl.replaceAll('/api', '');
            return '$baseUrl/storage/$photo?v=${provider.photoVersion}';
          }
          final photoUrl = getPhotoUrl();

          return RefreshIndicator(
            onRefresh: () => provider.fetchProfile(),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: theme.colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: kToolbarHeight), // Prevents overlap with title
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.3),
                                    ),
                                    child: CircleAvatar(
                                      radius: 46,
                                      backgroundColor: theme.colorScheme.surface,
                                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                      child: photoUrl == null
                                          ? Text(namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'S',
                                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))
                                          : null,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(namaUser, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildBadge((user['level'] ?? 'Siswa').toUpperCase(), Colors.white.withValues(alpha: 0.2), Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  title: const Text('Profil Saya', style: TextStyle(color: Colors.white)),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                      tooltip: 'Edit Profil',
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(initialData: user))),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    child: Column(
                      children: [
                        // Info Section
                        _buildSection('Informasi Akun', [
                          _buildInfoTile(Icons.person_outline_rounded, 'Nama Lengkap', namaUser, theme),
                          _buildInfoTile(Icons.email_outlined, 'Email', email, theme),
                          _buildInfoTile(Icons.phone_outlined, 'No. Telepon', user['no_telp'] ?? '-', theme),
                          _buildInfoTile(Icons.location_on_outlined, 'Alamat', user['alamat'] ?? '-', theme),
                        ], theme),
                        const SizedBox(height: 24),

                        // Logout
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutConfirm,
                            icon: const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('Keluar dari Akun', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSection(String title, List<Widget> children, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5))),
        subtitle: Text(value, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
      ),
    );
  }

}
