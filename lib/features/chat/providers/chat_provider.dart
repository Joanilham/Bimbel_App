import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/services/notification_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _contacts = [];
  List<dynamic> _conversations = [];
  List<dynamic> _messages = [];
  bool _isLoading = false;
  String? _error;
  
  Timer? _pollingTimer;
  Timer? _globalPollingTimer;
  int? _activeUserId;
  int? _myUserId;
  Map<int, String> _lastSeenMessages = {};

  List<dynamic> get contacts => _contacts;
  List<dynamic> get conversations => _conversations;
  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchContacts() async {
    _setLoading(true);
    try {
      final response = await _apiClient.dio.get('/chat/contacts');
      if (response.statusCode == 200) {
        _contacts = response.data['data'] ?? [];
        _error = null;
      } else {
        _error = 'Failed to load contacts';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchConversations({bool silent = false}) async {
    if (!silent) _setLoading(true);
    try {
      final response = await _apiClient.dio.get('/chat');
      if (response.statusCode == 200) {
        _conversations = response.data['data'] ?? [];
        _error = null;
        
        // Cek notifikasi baru (hanya jika silent/dari global polling)
        if (silent) {
          for (var conv in _conversations) {
            final int convId = conv['id'];
            final unreadCount = conv['unread_count'] ?? 0;
            final latestMsg = conv['latest_message'];
            
            if (latestMsg != null && unreadCount > 0) {
              final String msgDate = latestMsg['created_at'];
              final String? previousDate = _lastSeenMessages[convId];
              
              if (previousDate == null || previousDate != msgDate) {
                // Ada pesan baru!
                if (_myUserId == null || latestMsg['sender_id'] != _myUserId) {
                  final senderName = conv['other_user']?['name'] ?? 'Seseorang';
                  final msgBody = latestMsg['body'] ?? 'Pesan baru';
                  
                  // Jangan tampilkan notifikasi jika user sedang buka chat dengan orang ini
                  if (_activeUserId != conv['other_user']?['id']) {
                    NotificationService().showNotification(
                      id: convId,
                      title: 'Pesan dari $senderName',
                      body: msgBody,
                    );
                  }
                }
              }
              _lastSeenMessages[convId] = msgDate;
            }
          }
        } else {
          // Initialize last seen
          for (var conv in _conversations) {
            final latestMsg = conv['latest_message'];
            if (latestMsg != null) {
              _lastSeenMessages[conv['id']] = latestMsg['created_at'];
            }
          }
        }
      } else {
        if (!silent) _error = 'Failed to load conversations';
      }
    } catch (e) {
      if (!silent) _error = 'Network error: $e';
    } finally {
      if (!silent) _setLoading(false);
      notifyListeners();
    }
  }

  void startGlobalPolling(int myUserId) {
    _myUserId = myUserId;
    if (_globalPollingTimer != null) return;
    
    // Initial fetch
    fetchConversations(silent: true);
    
    // Poll every 10 seconds
    _globalPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchConversations(silent: true);
    });
  }

  void stopGlobalPolling() {
    _globalPollingTimer?.cancel();
    _globalPollingTimer = null;
  }

  Future<void> fetchMessages(int userId) async {
    _activeUserId = userId;
    _setLoading(true);
    await _getMessagesData(userId);
    _setLoading(false);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_activeUserId == userId) {
        _getMessagesData(userId, silent: true);
      }
    });
  }

  Future<void> _getMessagesData(int userId, {bool silent = false}) async {
    try {
      final response = await _apiClient.dio.get('/chat/$userId');
      if (response.statusCode == 200) {
        _messages = response.data['data']['messages'] ?? [];
        if (!silent) _error = null;
        notifyListeners();
      }
    } catch (e) {
      if (!silent) _error = 'Network error: $e';
    }
  }

  void stopPolling() {
    _activeUserId = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> sendMessage(int receiverId, String message) async {
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'sender_id': -1,
      'body': message,
      'created_at': DateTime.now().toIso8601String(),
      'is_sending': true,
    };
    _messages.add(tempMessage);
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/chat',
        data: {
          'receiver_id': receiverId,
          'message': message,
        },
      );

      if (response.statusCode == 200) {
        final realMsg = response.data['data'];
        final index = _messages.indexWhere((m) => m['id'] == tempMessage['id']);
        if (index != -1) {
          _messages[index] = realMsg;
        } else {
          _messages.add(realMsg);
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      _messages.removeWhere((m) => m['id'] == tempMessage['id']);
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _globalPollingTimer?.cancel();
    super.dispose();
  }
}
