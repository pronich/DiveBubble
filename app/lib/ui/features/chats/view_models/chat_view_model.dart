import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
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

  // Full trip roster, loaded once — feeds the @-mention autocomplete list (see ChatView's
  // composer). Deliberately not the same as _profiles (populated lazily, per-sender, only for
  // names already seen in the message list) since the mention list needs to offer *every*
  // participant, including ones who haven't posted yet.
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
    // Fire-and-forget, off the critical path for the chat itself appearing — the mention list
    // just stays empty until this resolves.
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
      // Reaction changes get their own small sentinel (see publishReactionUpdate) instead of a
      // full message republish — a Centrifugo publish is one shared payload for every
      // subscriber, and ReactedByMe is per-viewer, so it can never be correct in a broadcast.
      // Only per-emoji Count travels over the wire; _applyReactionUpdate merges that in while
      // leaving each emoji's locally-known ReactedByMe untouched (it only ever changes via this
      // viewer's own reactToMessage call, never via someone else's reaction).
      if (json['event'] == 'reaction_update') {
        _applyReactionUpdate(json);
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
      // An id already present means this is a re-publish of an existing message (currently
      // only happens on delete — see ChatApiService.deleteMessage's own realtime republish) —
      // patch it in place rather than the old "already have this id, ignore" no-op, which would
      // silently drop the redaction for anyone not looking at the screen at the exact moment
      // their own deleteMessage() REST response happened to land first.
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

  // Toggles the caller's own reaction — tapping the same emoji already reacted with removes it
  // (Messenger semantics), tapping a different one replaces it. Returns an error string on
  // failure (same shape as reportMessage/deleteMessage), null on success.
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
      return e.toString();
    }
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
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Uploads every picked attachment in parallel, then sends one message carrying all of them
  /// (with an optional caption) — the composer's entry point once files are picked. The
  /// pending bubble (with a per-item loader — see ChatView's _AttachmentGrid) appears
  /// immediately; each attachment's own upload completing patches just that one entry
  /// (see _patchPendingAttachment) so its cell's spinner clears independently of any siblings
  /// still in flight. Any single upload failing aborts the whole send (fail-fast, same as the
  /// old single-attachment behavior) — errors remove the pending bubble and propagate so the
  /// composer's own try/catch can keep the picked files staged and show a SnackBar.
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

  // Compression happens here — at upload time, once Send is actually tapped — not at pick
  // time. Picking used to run compression immediately, which left the composer looking like
  // nothing had happened for however many seconds a longer clip took to compress; the pending
  // bubble's per-item spinner (isUploaded: false, set the instant this item's attachment entry
  // is built — see _buildPendingMessage) already covers this whole window, compression
  // included, since it doesn't flip to true until this function returns.
  Future<String> _compressedVideoPathOrFallback(String originalPath) async {
    try {
      final compressed = await VideoCompress.compressVideo(
        originalPath,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
      );
      return compressed?.path ?? originalPath;
    } catch (_) {
      // Falls back to the uncompressed original — still capped by the backend's video size
      // limit, just larger than ideal. video_compress is a thinly-maintained plugin (see the
      // chat-richness plan's note on smoke-testing it), so this failure mode is expected to be
      // hit occasionally rather than treated as fatal.
      return originalPath;
    }
  }

  Future<AttachmentUploadResult> _uploadAndPatch({required String tempId, required PickedAttachment picked}) async {
    final uploadPath = picked.type == 'video' ? await _compressedVideoPathOrFallback(picked.path) : picked.path;
    final uploaded = await _repository.uploadAttachment(tripId, uploadPath);
    // The upload endpoint sniffs content-type/size/filename server-side but has no way to know
    // a video's duration — that was only ever knowable client-side, at pick time (see
    // pick_attachment.dart's getMediaInfo call) — so it's threaded through here rather than
    // trusted from the upload response.
    final result = picked.durationSeconds == null
        ? uploaded
        : AttachmentUploadResult(
            url: uploaded.url,
            type: uploaded.type,
            filename: uploaded.filename,
            sizeBytes: uploaded.sizeBytes,
            durationSeconds: picked.durationSeconds,
          );
    // Patch just this one attachment (matched by local path — unique per picked item) within
    // the still-pending message, independent of any siblings still uploading.
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

  /// Soft-deletes one of the current user's own messages — author-only, enforced server-side
  /// regardless of what the UI gates on. Splices the server's redacted response straight into
  /// the local list; the realtime republish will land moments later and just re-confirm the
  /// same state (see _subscribeToRealtime's upsert-by-id handling).
  Future<String?> deleteMessage(String messageId) async {
    try {
      final deleted = await _repository.deleteMessage(tripId, messageId);
      _messages = [for (final m in _messages) if (m.id == messageId) deleted else m];
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
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
