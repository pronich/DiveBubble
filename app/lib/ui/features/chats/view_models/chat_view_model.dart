import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/error_codes.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/attachment_upload_result.dart';
import '../../../../domain/entities/chat_attachment.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/chat_reaction.dart';
import '../../../../domain/entities/picked_attachment.dart';
import '../../../../domain/entities/profile.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required ChatRepository repository,
    required RealtimeService realtimeService,
    required this.profileRepository,
    required this.tripRepository,
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
  final TripRepository tripRepository;
  final String tripId;
  final String currentUserId;

  // Neither set = the trip's main chat; offerId = a car offer's chat; buddyRequestId = a buddy group's chat. Mutually exclusive.
  final String? offerId;
  final String? buddyRequestId;

  // Fired when the realtime "dissolved" sentinel arrives (offer/buddy chats only) so the view can bounce back to the list.
  final VoidCallback? onDissolved;

  centrifuge.Subscription? _subscription;
  StreamSubscription<centrifuge.PublicationEvent>? _publicationListener;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // The REST message list is already filtered server-side; this set's real job is filtering the realtime append path, which bypasses that filter.
  Set<String> blockedUserIds = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  bool _isUploadingAttachment = false;
  bool get isUploadingAttachment => _isUploadingAttachment;

  String? _error;
  String? get error => _error;

  // Deliberately not the same as _profiles (lazy, per-sender) — the @-mention list needs every participant, including ones who haven't posted yet.
  List<Profile> _participants = [];
  List<Profile> get participants => _participants;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _repository.getMessages(tripId, offerId: offerId, buddyRequestId: buddyRequestId);
      try {
        blockedUserIds = (await profileRepository.getBlockedUserIds()).toSet();
      } catch (_) {
        // Best-effort — the realtime filter this feeds is a nicety, not worth blocking the chat load over.
      }
      await _subscribeToRealtime();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    // Fire-and-forget, off the critical path for the chat appearing — the mention list just stays empty until this resolves.
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final ids = await tripRepository.getParticipantUserIds(tripId);
      final profiles = await Future.wait(ids.map(_fetchProfileOrNull));
      _participants = profiles.whereType<Profile>().toList();
      notifyListeners();
    } catch (_) {
      // Best-effort — worst case the mention list just stays empty (or partial).
    }
  }

  Future<Profile?> _fetchProfileOrNull(String userId) async {
    try {
      return await profileRepository.getPublicProfile(userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _subscribeToRealtime() async {
    final channel = offerId != null
        ? 'transport_offer:$offerId'
        : buddyRequestId != null
            ? 'buddy_request:$buddyRequestId'
            : 'trip:$tripId';
    _subscription = await _realtimeService.subscribe(channel);
    // The channel Subscription may be shared with other screens (e.g. the Bubbles list also watches trip:$id) — cancel only this listener, not the whole channel.
    _publicationListener = _subscription!.publication.listen((event) {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      // Checked first so a dissolved-offer sentinel is never mistaken for a real message.
      if (json['event'] == 'dissolved') {
        onDissolved?.call();
        return;
      }
      // Only per-emoji Count travels over the wire; ReactedByMe is per-viewer and never correct in a shared broadcast, so it's merged in locally instead.
      if (json['event'] == 'reaction_update') {
        _applyReactionUpdate(json);
        return;
      }
      // Only meaningful to MyTripsViewModel/TripConversationPage's pill-dot listeners sharing this channel; the main chat must skip it or the cast below would throw on missing fields.
      if (json['event'] == 'sub_chat_activity') return;
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
        // Hand-decoded, not via ChatMessageApiModel.fromJson — easy to forget when adding a new message field.
        attachments: ((json['attachments'] as List<dynamic>?) ?? [])
            .map((raw) {
              final a = raw as Map<String, dynamic>;
              return ChatAttachment(
                url: a['url'] as String?,
                type: a['type'] as String,
                filename: a['filename'] as String?,
                sizeBytes: a['sizeBytes'] as int?,
                durationSeconds: a['durationSeconds'] as int?,
              );
            })
            .toList(),
        replyToId: json['replyToId'] as String?,
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        reactions: ((json['reactions'] as Map<String, dynamic>?) ?? {}).map((emoji, raw) {
          final r = raw as Map<String, dynamic>;
          return MapEntry(emoji, ChatReaction(count: r['count'] as int, reactedByMe: r['reactedByMe'] as bool? ?? false));
        }),
      );
      if (blockedUserIds.contains(message.userId)) return;
      // An id already present means this is a re-publish (currently only happens on delete) — patch it in place rather than ignore it, or the redaction could be silently dropped.
      if (_messages.any((m) => m.id == message.id)) {
        _messages = [for (final m in _messages) if (m.id == message.id) message else m];
        notifyListeners();
        return;
      }
      _reconcilePending(message);
      notifyListeners();
    });
  }

  void _applyReactionUpdate(Map<String, dynamic> json) {
    final messageId = json['messageId'] as String;
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final message = _messages[index];
    final counts = (json['counts'] as Map<String, dynamic>? ?? {});
    final updated = {
      for (final entry in counts.entries)
        entry.key: ChatReaction(
          count: entry.value as int,
          reactedByMe: message.reactions[entry.key]?.reactedByMe ?? false,
        ),
    };
    _messages = [for (final m in _messages) if (m.id == messageId) m.copyWith(reactions: updated) else m];
    notifyListeners();
  }

  // Tapping the same emoji already reacted with removes it (Messenger semantics); a different one replaces it.
  Future<String?> reactToMessage(String messageId, String emoji) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return null;
    final removing = _messages[index].reactions[emoji]?.reactedByMe ?? false;
    try {
      final reactions = removing
          ? await _repository.removeReaction(tripId, messageId)
          : await _repository.setReaction(tripId, messageId, emoji);
      _messages = [
        for (final m in _messages) if (m.id == messageId) m.copyWith(reactions: reactions) else m,
      ];
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<String?> reportMessage(String messageId, String reason, {String? details}) async {
    try {
      await _repository.reportMessage(tripId, messageId, reason, details: details);
      return null;
    } catch (e) {
      return friendlyError(e);
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
      return friendlyError(e);
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
      return friendlyError(e);
    }
  }

  int _pendingCounter = 0;

  // Owning the pending state here (instead of a separate composer spinner) avoids the old bug where a "sending" chip and the real realtime bubble briefly showed at once.
  ChatMessage _buildPendingMessage({
    required String tempId,
    required String body,
    List<PickedAttachment> attachments = const [],
    String? replyToId,
  }) => ChatMessage(
    id: tempId,
    tripId: tripId,
    userId: currentUserId,
    body: body,
    createdAt: DateTime.now(),
    isPending: true,
    attachments: [
      for (final a in attachments)
        ChatAttachment(
          type: a.type,
          filename: a.filename,
          sizeBytes: a.sizeBytes,
          durationSeconds: a.durationSeconds,
          localPath: a.path,
          isUploaded: false,
        ),
    ],
    replyToId: replyToId,
  );

  // Called from both the HTTP response and the realtime publication, whichever arrives first (Centrifugo usually beats the HTTP round trip); matches by "oldest pending from this sender" since no client id round-trips through the realtime payload.
  void _reconcilePending(ChatMessage real) {
    final pending = _messages.where((m) => m.isPending && m.userId == real.userId);
    final pendingId = pending.isEmpty ? real.id : pending.first.id;
    _messages = [
      for (final m in _messages)
        if (m.id != pendingId && m.id != real.id) m,
      real,
    ];
  }

  Future<void> send(String body, {bool mentionsDiveCenter = false, String? replyToId}) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final tempId = 'pending-${_pendingCounter++}';
    _messages = [..._messages, _buildPendingMessage(tempId: tempId, body: trimmed, replyToId: replyToId)];
    _isSending = true;
    notifyListeners();

    try {
      final sent = await _repository.sendMessage(
        tripId,
        trimmed,
        offerId: offerId,
        buddyRequestId: buddyRequestId,
        mentionsDiveCenter: mentionsDiveCenter,
        replyToId: replyToId,
      );
      _reconcilePending(sent);
    } catch (e) {
      _messages = _messages.where((m) => m.id != tempId).toList();
      _error = friendlyError(e);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Fail-fast: any single upload failing aborts the whole send and removes the pending bubble, letting the composer's own try/catch keep the picked files staged and show a SnackBar.
  Future<void> uploadMultipleAndSend(
    List<PickedAttachment> attachments, {
    String caption = '',
    bool mentionsDiveCenter = false,
    String? replyToId,
  }) async {
    final tempId = 'pending-${_pendingCounter++}';
    final trimmedCaption = caption.trim();
    _messages = [
      ..._messages,
      _buildPendingMessage(tempId: tempId, body: trimmedCaption, attachments: attachments, replyToId: replyToId),
    ];
    _isUploadingAttachment = true;
    notifyListeners();
    try {
      final results = await Future.wait(
        attachments.map((a) => _uploadAndPatch(tempId: tempId, picked: a)),
      );
      _isUploadingAttachment = false;
      _isSending = true;
      notifyListeners();
      final sent = await _repository.sendMessage(
        tripId,
        trimmedCaption,
        offerId: offerId,
        buddyRequestId: buddyRequestId,
        mentionsDiveCenter: mentionsDiveCenter,
        attachments: results,
        replyToId: replyToId,
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

  // Compression happens at upload/Send time, not at pick time — picking used to compress immediately, leaving the composer looking frozen for however long a clip took.
  Future<String> _compressedVideoPathOrFallback(String originalPath) async {
    try {
      final compressed = await VideoCompress.compressVideo(
        originalPath,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
      );
      return compressed?.path ?? originalPath;
    } catch (_) {
      // Falls back to the uncompressed original (still capped by the backend's size limit) — video_compress is thinly-maintained, so this is expected occasionally.
      return originalPath;
    }
  }

  Future<AttachmentUploadResult> _uploadAndPatch({required String tempId, required PickedAttachment picked}) async {
    final uploadPath = picked.type == 'video' ? await _compressedVideoPathOrFallback(picked.path) : picked.path;
    final uploaded = await _repository.uploadAttachment(tripId, uploadPath);
    // The server can't know a video's duration; it's only ever knowable client-side at pick time, so it's threaded through here rather than trusted from the upload response.
    final result = picked.durationSeconds == null
        ? uploaded
        : AttachmentUploadResult(
            url: uploaded.url,
            type: uploaded.type,
            filename: uploaded.filename,
            sizeBytes: uploaded.sizeBytes,
            durationSeconds: picked.durationSeconds,
          );
    // Matched by local path (unique per picked item) so this cell's spinner clears independently of any siblings still uploading.
    _messages = [
      for (final m in _messages)
        if (m.id == tempId)
          m.copyWith(
            attachments: [
              for (final a in m.attachments)
                if (a.localPath == picked.path) a.copyWith(url: result.url, isUploaded: true) else a,
            ],
          )
        else
          m,
    ];
    notifyListeners();
    return result;
  }

  /// Author-only, enforced server-side regardless of what the UI gates on.
  Future<String?> deleteMessage(String messageId) async {
    try {
      final deleted = await _repository.deleteMessage(tripId, messageId);
      _messages = [for (final m in _messages) if (m.id == messageId) deleted else m];
      notifyListeners();
      return null;
    } catch (e) {
      return friendlyError(e);
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
