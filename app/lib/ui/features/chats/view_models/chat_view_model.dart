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
    this.buddyRequestId,
    this.onDissolved,
  })  : _repository = repository,
        _realtimeService = realtimeService;

  final ChatRepository _repository;
  final RealtimeService _realtimeService;
  final ProfileRepository profileRepository;
  final String tripId;
  final String currentUserId;

  // Neither set = the trip's main chat; offerId = a car offer's own chat; buddyRequestId = a
  // buddy group's own chat. Threaded through to the repository (which swaps the REST path)
  // and the realtime channel name. Mutually exclusive, mirroring the backend's own scope.
  final String? offerId;
  final String? buddyRequestId;

  // Fired when the realtime "dissolved" sentinel arrives (offer/buddy chats only) — the
  // creator cancelled this car/group; the view uses this to bounce back to the list.
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

  bool _isUploadingAttachment = false;
  bool get isUploadingAttachment => _isUploadingAttachment;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getMessages(tripId, offerId: offerId, buddyRequestId: buddyRequestId);
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
    final channel = offerId != null
        ? 'transport_offer:$offerId'
        : buddyRequestId != null
            ? 'buddy_request:$buddyRequestId'
            : 'trip:$tripId';
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
        // Hand-decoded like every other field above, not via ChatMessageApiModel.fromJson —
        // easy to forget when adding a new message field, so don't skip these on the next one.
        attachmentUrl: json['attachmentUrl'] as String?,
        attachmentType: json['attachmentType'] as String?,
        attachmentFilename: json['attachmentFilename'] as String?,
        attachmentSizeBytes: json['attachmentSizeBytes'] as int?,
      );
      if (blockedUserIds.contains(message.userId)) return;
      if (_messages.any((m) => m.id == message.id)) return;
      _reconcilePending(message);
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

  int _pendingCounter = 0;

  // A pending bubble appears the instant send is tapped, keyed by a temp id local to this
  // session — swapped for the server's real message (same content, real id) once the POST
  // response comes back. Previously the "sending" state lived on the composer (a separate
  // chip with its own spinner) while the real bubble came in via realtime — those two could
  // both be on screen at once for a moment. Owning the pending state here instead means only
  // ever one visual: the list bubble itself, loader over its attachment until it resolves.
  ChatMessage _buildPendingMessage({
    required String tempId,
    required String body,
    String? localAttachmentPath,
    String? attachmentType,
    String? attachmentFilename,
    int? attachmentSizeBytes,
  }) => ChatMessage(
    id: tempId,
    tripId: tripId,
    userId: currentUserId,
    body: body,
    createdAt: DateTime.now(),
    isPending: true,
    localAttachmentPath: localAttachmentPath,
    attachmentType: attachmentType,
    attachmentFilename: attachmentFilename,
    attachmentSizeBytes: attachmentSizeBytes,
  );

  // Swaps the oldest still-pending bubble from the same sender for a server-confirmed
  // message. Called from both the HTTP response and the realtime publication — whichever
  // arrives first does the swap; the backend publishes to Centrifugo as soon as the row is
  // written, which regularly beats the HTTP response finishing its own round trip back to
  // this same client, so waiting on the HTTP path alone left a window where the realtime
  // listener's naive append and the still-present pending bubble were both on screen. No
  // client-supplied id round-trips through the realtime payload to match on directly, so
  // "oldest pending from this sender" is the correlation — good enough since a given sender's
  // own messages are delivered in the order they were sent.
  void _reconcilePending(ChatMessage real) {
    final pending = _messages.where((m) => m.isPending && m.userId == real.userId);
    final pendingId = pending.isEmpty ? real.id : pending.first.id;
    _messages = [
      for (final m in _messages)
        if (m.id != pendingId && m.id != real.id) m,
      real,
    ];
  }

  Future<void> send(String body, {bool mentionsDiveCenter = false}) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final tempId = 'pending-${_pendingCounter++}';
    _messages = [..._messages, _buildPendingMessage(tempId: tempId, body: trimmed)];
    _isSending = true;
    notifyListeners();

    try {
      final sent = await _repository.sendMessage(
        tripId,
        trimmed,
        offerId: offerId,
        buddyRequestId: buddyRequestId,
        mentionsDiveCenter: mentionsDiveCenter,
      );
      _reconcilePending(sent);
    } catch (e) {
      _messages = _messages.where((m) => m.id != tempId).toList();
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Uploads a picked attachment, then sends it (with an optional caption) — the composer's
  /// entry point once a file is picked. The pending bubble (with a loader over the attachment,
  /// see ChatView's _AttachmentPreview) appears immediately; errors remove it and propagate so
  /// the composer's own try/catch can keep the picked file staged and show a SnackBar, instead
  /// of the attachment silently vanishing on failure.
  Future<void> uploadAndSend(
    String filePath, {
    required String attachmentType,
    required String attachmentFilename,
    String caption = '',
    bool mentionsDiveCenter = false,
  }) async {
    final tempId = 'pending-${_pendingCounter++}';
    final trimmedCaption = caption.trim();
    _messages = [
      ..._messages,
      _buildPendingMessage(
        tempId: tempId,
        body: trimmedCaption,
        localAttachmentPath: filePath,
        attachmentType: attachmentType,
        attachmentFilename: attachmentFilename,
      ),
    ];
    _isUploadingAttachment = true;
    notifyListeners();
    try {
      final result = await _repository.uploadAttachment(tripId, filePath);
      _isUploadingAttachment = false;
      _isSending = true;
      notifyListeners();
      final sent = await _repository.sendMessage(
        tripId,
        trimmedCaption,
        offerId: offerId,
        buddyRequestId: buddyRequestId,
        mentionsDiveCenter: mentionsDiveCenter,
        attachmentUrl: result.url,
        attachmentType: result.type,
        attachmentFilename: result.filename,
        attachmentSizeBytes: result.sizeBytes,
      );
      _reconcilePending(sent);
    } catch (e) {
      _messages = _messages.where((m) => m.id != tempId).toList();
      rethrow;
    } finally {
      _isUploadingAttachment = false;
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
