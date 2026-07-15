import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/chat_message.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required ChatRepository repository,
    required RealtimeService realtimeService,
    required this.profileRepository,
    required this.tripId,
    required this.currentUserId,
  })  : _repository = repository,
        _realtimeService = realtimeService;

  final ChatRepository _repository;
  final RealtimeService _realtimeService;
  final ProfileRepository profileRepository;
  final String tripId;
  final String currentUserId;

  centrifuge.Subscription? _subscription;
  StreamSubscription<centrifuge.PublicationEvent>? _publicationListener;

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
      await _subscribeToRealtime();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeToRealtime() async {
    _subscription = await _realtimeService.subscribe('trip:$tripId');
    // The channel Subscription can now be shared with other screens (e.g. the Bubbles
    // list also watches trip:$id) — cancel just this listener in dispose(), not the
    // whole channel, or a later reopen would stack a second listener on top of it.
    _publicationListener = _subscription!.publication.listen((event) {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final message = ChatMessage(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        userId: json['userId'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
      if (_messages.any((m) => m.id == message.id)) return;
      _messages = [..._messages, message];
      notifyListeners();
    });
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

  @override
  void dispose() {
    _publicationListener?.cancel();
    final sub = _subscription;
    if (sub != null) {
      _realtimeService.unsubscribe(sub);
    }
    super.dispose();
  }
}
