import 'package:flutter/foundation.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../domain/entities/chat_message.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required ChatRepository repository,
    required this.tripId,
    required this.currentUserId,
  }) : _repository = repository;

  final ChatRepository _repository;
  final String tripId;
  final String currentUserId;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getMessages(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> send(String body) async {
    if (body.trim().isEmpty) return;
    _isSending = true;
    notifyListeners();

    try {
      await _repository.sendMessage(tripId, body);
      _messages = await _repository.getMessages(tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
