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
    this.offerId,
    this.onDissolved,
  })  : _repository = repository,
        _realtimeService = realtimeService;

  final ChatRepository _repository;
  final RealtimeService _realtimeService;
  final ProfileRepository profileRepository;
  final String tripId;
  final String currentUserId;

  // Null = the trip's main chat; set = this car offer's own chat. Threaded through to the
  // repository (which swaps the REST path) and the realtime channel name.
  final String? offerId;

  // Fired when the realtime "dissolved" sentinel arrives (offer chats only) — the creator
  // cancelled this car; the view uses this to bounce back to the offers list.
  final VoidCallback? onDissolved;

  centrifuge.Subscription? _subscription;
  StreamSubscription<centrifuge.PublicationEvent>? _publicationListener;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // Populated on load() from ProfileRepository.getBlockedUserIds() — the REST message list is
  // already filtered server-side, so this set's real job is filtering the realtime append path
  // below, which bypasses that REST endpoint entirely.
  Set<String> blockedUserIds = {};

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
      _messages = await _repository.getMessages(tripId, offerId: offerId);
      try {
        blockedUserIds = (await profileRepository.getBlockedUserIds()).toSet();
      } catch (_) {
        // Best-effort — the realtime filter this feeds is a nicety, not something that
        // should block the chat itself from loading.
      }
      await _subscribeToRealtime();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeToRealtime() async {
    final channel = offerId != null ? 'transport_offer:$offerId' : 'trip:$tripId';
    _subscription = await _realtimeService.subscribe(channel);
    // The channel Subscription can now be shared with other screens (e.g. the Bubbles
    // list also watches trip:$id) — cancel just this listener in dispose(), not the
    // whole channel, or a later reopen would stack a second listener on top of it.
    _publicationListener = _subscription!.publication.listen((event) {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      // Sentinel published by the backend right before a dissolved offer's chat disappears —
      // distinct shape from a real message (see handleDissolveTransportOffer), checked first
      // so it's never mistaken for one.
      if (json['event'] == 'dissolved') {
        onDissolved?.call();
        return;
      }
      final message = ChatMessage(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        userId: json['userId'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isDiveCenterStaff: json['isDiveCenterStaff'] as bool? ?? false,
        mentionsDiveCenter: json['mentionsDiveCenter'] as bool? ?? false,
        kind: json['kind'] as String? ?? 'user',
        feedbackProvided: json['feedbackProvided'] as bool? ?? false,
      );
      if (blockedUserIds.contains(message.userId)) return;
      if (_messages.any((m) => m.id == message.id)) return;
      _messages = [..._messages, message];
      notifyListeners();
    });
  }

  Future<String?> reportMessage(String messageId, String reason, {String? details}) async {
    try {
      await _repository.reportMessage(tripId, messageId, reason, details: details);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> blockUser(String userId) async {
    try {
      await profileRepository.blockUser(userId);
      blockedUserIds = {...blockedUserIds, userId};
      _messages = _messages.where((m) => m.userId != userId).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> submitFeedback(
    String messageId,
    int rating,
    List<String> helpedWith,
    String? comment,
    bool contactOk,
  ) async {
    try {
      await _repository.submitFeedback(tripId, rating, helpedWith, comment, contactOk);
      _messages = [
        for (final m in _messages)
          if (m.id == messageId) m.copyWith(feedbackProvided: true) else m,
      ];
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> send(String body, {bool mentionsDiveCenter = false}) async {
    if (body.trim().isEmpty) return;
    _isSending = true;
    notifyListeners();

    try {
      await _repository.sendMessage(tripId, body, offerId: offerId, mentionsDiveCenter: mentionsDiveCenter);
      _messages = await _repository.getMessages(tripId, offerId: offerId);
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
