import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchConversations();
    });
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return DateFormat('HH:mm').format(date);
      }
      return DateFormat('dd MMM').format(date);
    } catch (e) {
      return '';
    }
  }

  void _showNewChatDialog() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.fetchContacts();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2F58E5)),
                      SizedBox(width: 12),
                      Text('Pilih Kontak Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading && provider.contacts.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: provider.contacts.length,
                        itemBuilder: (context, i) {
                          final contact = provider.contacts[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2F58E5).withValues(alpha: 0.1),
                              child: const Icon(Icons.person, color: Color(0xFF2F58E5)),
                            ),
                            title: Text(contact['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(contact['role']),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    userId: contact['id'],
                                    userName: contact['name'],
                                  ),
                                ),
                              ).then((_) => provider.fetchConversations());
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Obrolan', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada pesan', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Mulai obrolan dengan teman atau guru', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchConversations,
            child: ListView.separated(
              itemCount: provider.conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final conv = provider.conversations[index];
                final otherUser = conv['other_user'] ?? {};
                final lastMsg = conv['latest_message'] ?? {};
                final unread = conv['unread_count'] ?? 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (otherUser['name'] ?? '?')[0].toUpperCase(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUser['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conv['updated_at']),
                        style: TextStyle(fontSize: 12, color: unread > 0 ? const Color(0xFF2F58E5) : Colors.grey.shade500, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg['body'] ?? 'Memulai percakapan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFF2F58E5), shape: BoxShape.circle),
                          child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          userId: otherUser['id'],
                          userName: otherUser['name'],
                        ),
                      ),
                    ).then((_) => provider.fetchConversations());
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: const Color(0xFF2F58E5),
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }
}
