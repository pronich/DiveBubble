import 'package:flutter/material.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/buddy_request.dart';
import '../../../../domain/entities/profile.dart';
import '../../../core/auth/ensure_signed_in.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../chats/view_models/chat_view_model.dart';
import '../../chats/views/chat_view.dart';
import '../../profile/views/diver_id_card.dart';
import '../view_models/buddy_view_model.dart';

class BuddyView extends StatefulWidget {
  const BuddyView({
    super.key,
    required this.viewModel,
    required this.chatRepository,
    required this.realtimeService,
    this.isCancelled = false,
  });

  final BuddyViewModel viewModel;

  /// Needed only once the diver is in a group (see myRequest) — builds that group's own
  /// ChatView, reusing the exact same repository/service the main Bubble chat uses.
  final ChatRepository chatRepository;
  final RealtimeService realtimeService;

  /// See ChatView.isCancelled — same source of truth (TripConversationPage), same idea:
  /// existing requests/joins stay visible, but nothing new can be created or joined.
  final bool isCancelled;

  @override
  State<BuddyView> createState() => _BuddyViewState();
}

class _BuddyViewState extends State<BuddyView>
    with AutomaticKeepAliveClientMixin {
  // Same reasoning as ChatView/TransportView — TabBarView disposes offscreen tabs by
  // default, which otherwise re-triggers a full request reload every time this tab scrolls
  // back into view.
  @override
  bool get wantKeepAlive => true;

  // Cached purely so the same ChatViewModel (and its realtime subscription) survives
  // rebuilds triggered by the shared BuddyViewModel's notifyListeners() while showing the
  // same group — NOT a disposal owner. ChatView.dispose() already disposes whatever
  // ChatViewModel it's given (see chat_view_model.dart) whenever its Element unmounts, which
  // happens automatically on every transition away from it (back to the list, to a different
  // group, or this whole page going away) since that's always a widget-type change at this
  // position in the tree. Disposing it again here would double-dispose and crash — see the
  // same bug hit (and fixed) in transport_view.dart's _ensureCarChatViewModel.
  ChatViewModel? _buddyChatViewModel;
  String? _buddyChatRequestId;

  @override
  void initState() {
    super.initState();
    // Deferred a tick: TabBarView builds all tabs eagerly up front, so calling load() (whose
    // first line is a synchronous notifyListeners()) straight from initState here fires
    // while a *sibling* tab's build is still in flight, tripping "setState called during
    // build". A microtask lets the current build pass finish first.
    Future.microtask(widget.viewModel.load);
  }

  ChatViewModel _ensureBuddyChatViewModel(BuddyRequest request) {
    if (_buddyChatRequestId != request.id) {
      _buddyChatRequestId = request.id;
      _buddyChatViewModel = ChatViewModel(
        repository: widget.chatRepository,
        realtimeService: widget.realtimeService,
        profileRepository: widget.viewModel.profileRepository,
        tripId: request.tripId,
        currentUserId: widget.viewModel.currentUserId,
        buddyRequestId: request.id,
        onDissolved: _onBuddyDissolved,
      );
    }
    return _buddyChatViewModel!;
  }

  // The creator cancelled this group while we were viewing it — the request's gone
  // server-side. Just refresh the list; myRequest will be null after, which swaps ChatView
  // out for the requests list on the next build and disposes the ChatViewModel via its own
  // dispose().
  void _onBuddyDissolved() {
    widget.viewModel.load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This buddy group was cancelled by the organizer.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final error = widget.viewModel.error;
        if (error != null) {
          return Scaffold(body: Center(child: Text('Error: $error')));
        }

        final myRequest = widget.viewModel.myRequest;
        if (myRequest != null) {
          // No FAB while in a group — "Request a buddy" doesn't apply once you're already
          // committed to one (a diver can only be in one buddy group per trip).
          return Scaffold(
            body: ChatView(
              viewModel: _ensureBuddyChatViewModel(myRequest),
              isCancelled: widget.isCancelled,
            ),
          );
        }

        // No active group right now — whatever ChatView was showing one (if any) has already
        // unmounted and disposed its ChatViewModel by rendering here instead (see the
        // myRequest branch above). Clearing the cache means the *next* time a group chat
        // renders — even for the very same request, e.g. leave then rejoin —
        // _ensureBuddyChatViewModel builds a fresh instance instead of handing back the stale
        // disposed one (matching request.id alone isn't enough to know the old ChatViewModel
        // is still alive).
        _buddyChatRequestId = null;
        _buddyChatViewModel = null;

        final requests = widget.viewModel.requests;
        return Scaffold(
          body: requests.isEmpty
              ? EmptyStateView(
                  icon: Icons.people_outline,
                  title: widget.isCancelled
                      ? 'No buddy requests were made'
                      : 'Be the first to look for a buddy',
                  subtitle: widget.isCancelled
                      ? 'This trip has been cancelled.'
                      : 'Request a buddy so others can join you for this dive.',
                  ctaLabel: widget.isCancelled ? null : 'Request a buddy',
                  onCtaPressed: widget.isCancelled
                      ? null
                      : () => _openAddSheet(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _RequestTile(
                    request: requests[index],
                    onTap: () => _openDetailSheet(context, requests[index]),
                  ),
                ),
          floatingActionButton: widget.isCancelled
              ? null
              : FloatingActionButton(
                  onPressed: () => _openAddSheet(context),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddBuddyRequestSheet(viewModel: widget.viewModel),
    );
  }

  void _openDetailSheet(BuildContext context, BuddyRequest request) {
    showBuddyRequestDetailSheet(
      context,
      requestId: request.id,
      viewModel: widget.viewModel,
      isCancelled: widget.isCancelled,
    );
  }
}

/// Public entry point so the ⓘ affordance on the Buddy tab itself (TripConversationPage) can
/// open the same sheet a diver already in a group would reach by tapping its row in the
/// list — that's the same sheet, just also reachable one level higher up once you're in it
/// and the list is replaced by the chat.
void showBuddyRequestDetailSheet(
  BuildContext context, {
  required String requestId,
  required BuddyViewModel viewModel,
  bool isCancelled = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BuddyRequestDetailSheet(
      requestId: requestId,
      viewModel: viewModel,
      isCancelled: isCancelled,
    ),
  );
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.onTap});

  final BuddyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // +1 for the creator — maxMembers is the whole group's size, not just joiners.
    final isFull = 1 + request.joinedCount >= request.maxMembers;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.creatorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (request.creatorLevel?.isNotEmpty ?? false)
                        request.creatorLevel!,
                      '${request.creatorDiveCount} dives',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (request.joined) ...[
              const SizedBox(width: 12),
              const _StatusPill(label: 'Joined', kind: _StatusKind.success),
            ] else if (isFull) ...[
              const SizedBox(width: 12),
              const _StatusPill(label: 'Full', kind: _StatusKind.info),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuddyRequestDetailSheet extends StatefulWidget {
  const _BuddyRequestDetailSheet({
    required this.requestId,
    required this.viewModel,
    this.isCancelled = false,
  });

  final String requestId;
  final BuddyViewModel viewModel;
  final bool isCancelled;

  @override
  State<_BuddyRequestDetailSheet> createState() =>
      _BuddyRequestDetailSheetState();
}

class _BuddyRequestDetailSheetState extends State<_BuddyRequestDetailSheet> {
  List<String>? _joinedUserIds;
  final Map<String, Profile> _profiles = {};
  String? _error;
  String? _joinError;
  String? _actionError;
  bool _isActing = false;

  // Null once the request's gone from the list — dissolved (by us or the creator, live via
  // realtime while this sheet was open) or, for a joiner, left.
  BuddyRequest? get _request {
    final requests = widget.viewModel.requests;
    final index = requests.indexWhere((r) => r.id == widget.requestId);
    return index == -1 ? null : requests[index];
  }

  @override
  void initState() {
    super.initState();
    _loadJoinedUserIds();
    final request = _request;
    if (request != null) _loadProfile(request.userId);
  }

  // Best-effort, one-at-a-time — a profile fetch failing just leaves that row on the
  // generic "Diver" fallback rather than blocking the rest of the sheet.
  Future<void> _loadProfile(String userId) async {
    if (_profiles.containsKey(userId)) return;
    try {
      final p = await widget.viewModel.profileRepository.getPublicProfile(
        userId,
      );
      if (mounted) setState(() => _profiles[userId] = p);
    } catch (_) {
      // ignore — row falls back to "Diver"
    }
  }

  Future<void> _loadJoinedUserIds() async {
    try {
      final ids = await widget.viewModel.getJoinedUserIds(widget.requestId);
      if (mounted) setState(() => _joinedUserIds = ids);
      for (final id in ids) {
        _loadProfile(id);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _openProfile(String userId) {
    showDiverIdCard(
      context,
      userId: userId,
      currentUserId: widget.viewModel.currentUserId,
      profileRepository: widget.viewModel.profileRepository,
    );
  }

  Future<void> _join(BuddyRequest request) async {
    final userId = await ensureSignedIn(
      context,
      widget.viewModel.authRepository,
      widget.viewModel.profileRepository,
      widget.viewModel.pushRepository,
    );
    if (userId == null || !mounted) return;

    setState(() => _joinError = null);
    final error = await widget.viewModel.join(request.id);
    if (!mounted) return;
    if (error != null) {
      setState(() => _joinError = error);
    } else {
      // Close the sheet so the now-joined group's chat (myRequest swaps in automatically via
      // BuddyView's ListenableBuilder) is immediately visible, instead of leaving this sheet
      // sitting on top of it.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final request = _request;
            if (request == null) {
              // Gone (dissolved, or we just left it) while this sheet was open — close it
              // next frame rather than rendering against a missing request.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop())
                  Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }
            // +1 for the creator — maxMembers is the whole group's size, not just joiners.
            final isFull = 1 + request.joinedCount >= request.maxMembers;
            final isCreator = request.userId == widget.viewModel.currentUserId;
            // A diver can only be in one buddy group per trip — don't offer a Join button
            // on other requests once they've already joined one.
            final hasGroupElsewhere =
                !request.joined &&
                widget.viewModel.requests.any((r) => r.joined);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Buddy request',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (request.joined)
                      const _StatusPill(
                        label: 'Joined',
                        kind: _StatusKind.success,
                      )
                    else if (isFull)
                      const _StatusPill(label: 'Full', kind: _StatusKind.info),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final creatorProfile = _profiles[request.userId];
                    final creatorName =
                        (creatorProfile?.displayName?.isNotEmpty ?? false)
                        ? creatorProfile!.displayName!
                        : request.creatorName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openProfile(request.userId),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            backgroundImage:
                                (creatorProfile?.avatarUrl?.isNotEmpty ?? false)
                                ? NetworkImage(creatorProfile!.avatarUrl!)
                                : null,
                            child:
                                (creatorProfile?.avatarUrl?.isNotEmpty ?? false)
                                ? null
                                : Icon(
                                    Icons.person,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                creatorName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isCreator ? 'Creator · You' : 'Creator',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('Group', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (_error != null)
                  Text(
                    'Error: $_error',
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                else if (_joinedUserIds == null)
                  const Center(child: CircularProgressIndicator())
                else if (_joinedUserIds!.isEmpty)
                  Text(
                    'No one has joined yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ..._joinedUserIds!.map((userId) {
                    final isMe = userId == widget.viewModel.currentUserId;
                    final diverProfile = _profiles[userId];
                    final name =
                        (diverProfile?.displayName?.isNotEmpty ?? false)
                        ? diverProfile!.displayName!
                        : (isMe ? 'You' : 'Diver');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openProfile(userId),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              backgroundImage:
                                  (diverProfile?.avatarUrl?.isNotEmpty ?? false)
                                  ? NetworkImage(diverProfile!.avatarUrl!)
                                  : null,
                              child:
                                  (diverProfile?.avatarUrl?.isNotEmpty ?? false)
                                  ? null
                                  : Icon(
                                      Icons.person,
                                      size: 18,
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Text(name, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    );
                  }),
                if (!isCreator &&
                    !request.joined &&
                    !isFull &&
                    !hasGroupElsewhere &&
                    !widget.isCancelled) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _JoinButton(
                      request: request,
                      viewModel: widget.viewModel,
                      onPressed: () => _join(request),
                    ),
                  ),
                  if (_joinError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _joinError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ] else if (!widget.isCancelled &&
                    (isCreator || request.joined)) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isActing
                          ? null
                          : (isCreator
                                ? () => _dissolve(request)
                                : () => _leave(request)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: _isActing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isCreator
                                  ? 'Cancel buddy request'
                                  : 'Leave buddy group',
                            ),
                    ),
                  ),
                  if (_actionError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _actionError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _leave(BuddyRequest request) async {
    setState(() {
      _isActing = true;
      _actionError = null;
    });
    final error = await widget.viewModel.leave(request.id);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isActing = false;
        _actionError = error;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _dissolve(BuddyRequest request) async {
    setState(() {
      _isActing = true;
      _actionError = null;
    });
    final error = await widget.viewModel.dissolve(request.id);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isActing = false;
        _actionError = error;
      });
    } else {
      Navigator.of(context).pop();
    }
  }
}

enum _StatusKind { success, info }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.kind});

  final String label;
  final _StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>()!;
    final theme = Theme.of(context);
    final background = kind == _StatusKind.success
        ? semantic.successContainer
        : semantic.infoContainer;
    final foreground = kind == _StatusKind.success
        ? semantic.onSuccessContainer
        : semantic.onInfoContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.request,
    required this.viewModel,
    required this.onPressed,
  });

  final BuddyRequest request;
  final BuddyViewModel viewModel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isJoining = viewModel.isJoining(request.id);
    return ElevatedButton(
      onPressed: isJoining ? null : onPressed,
      child: isJoining
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Join'),
    );
  }
}

/// No fields to fill in — just a one-tap confirmation, same "tap FAB → sheet → confirm"
/// convention as everywhere else in the app, guarding against an accidental tap at near-zero
/// extra cost since there's nothing to fill in.
class _AddBuddyRequestSheet extends StatefulWidget {
  const _AddBuddyRequestSheet({required this.viewModel});

  final BuddyViewModel viewModel;

  @override
  State<_AddBuddyRequestSheet> createState() => _AddBuddyRequestSheetState();
}

class _AddBuddyRequestSheetState extends State<_AddBuddyRequestSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request a buddy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Other divers on this trip will see your request and can join you.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ? null : _submit,
                child: widget.viewModel.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final ok = await widget.viewModel.submit();
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}
