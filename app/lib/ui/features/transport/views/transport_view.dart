import 'package:flutter/material.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/transport_offer.dart';
import '../../../core/auth/ensure_signed_in.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../chats/view_models/chat_view_model.dart';
import '../../chats/views/chat_view.dart';
import '../../profile/views/diver_id_card.dart';
import '../view_models/transport_view_model.dart';

const _typeLabels = {
  'offer_ride': 'Offering a ride',
  'share_rental': 'Sharing a rental',
};

const _typeIcons = {
  'offer_ride': Icons.directions_car,
  'share_rental': Icons.car_rental,
};

class TransportView extends StatefulWidget {
  const TransportView({
    super.key,
    required this.viewModel,
    required this.chatRepository,
    required this.realtimeService,
    this.isCancelled = false,
    this.businessName,
  });

  final TransportViewModel viewModel;

  /// Needed only once the diver is in a car (see myOffer) — builds that car's own ChatView,
  /// reusing the exact same repository/service the main Bubble chat uses.
  final ChatRepository chatRepository;
  final RealtimeService realtimeService;

  /// See ChatView.isCancelled — same source of truth (TripConversationPage), same idea:
  /// existing offers/joins stay visible, but nothing new can be created or joined.
  final bool isCancelled;

  /// Same "Name | Dive Center" attribution precedent as ChatView.businessName — only ever
  /// combined with offer.isDiveCenterStaff, so a regular diver's own offer never looks like
  /// it came from the organization.
  final String? businessName;

  @override
  State<TransportView> createState() => _TransportViewState();
}

class _TransportViewState extends State<TransportView> with AutomaticKeepAliveClientMixin {
  // Same reasoning as ChatView — TabBarView disposes offscreen tabs by default, which
  // otherwise re-triggers a full offer reload every time this tab scrolls back into view.
  @override
  bool get wantKeepAlive => true;

  // Cached purely so the same ChatViewModel (and its realtime subscription) survives
  // rebuilds triggered by the shared TransportViewModel's notifyListeners() while showing
  // the same car — NOT a disposal owner. ChatView.dispose() already disposes whatever
  // ChatViewModel it's given (see chat_view_model.dart) whenever its Element unmounts, which
  // happens automatically on every transition away from it (back to the list, to a different
  // car, or this whole page going away) since that's always a widget-type change at this
  // position in the tree. Disposing it again here would double-dispose and crash.
  ChatViewModel? _carChatViewModel;
  String? _carChatOfferId;

  @override
  void initState() {
    super.initState();
    // Deferred a tick: TabBarView builds both tabs eagerly up front, so calling load()
    // (whose first line is a synchronous notifyListeners()) straight from initState here
    // fires while the *sibling* Chat tab's build is still in flight, tripping "setState
    // called during build". A microtask lets the current build pass finish first.
    Future.microtask(widget.viewModel.load);
  }

  ChatViewModel _ensureCarChatViewModel(TransportOffer offer) {
    if (_carChatOfferId != offer.id) {
      _carChatOfferId = offer.id;
      _carChatViewModel = ChatViewModel(
        repository: widget.chatRepository,
        realtimeService: widget.realtimeService,
        profileRepository: widget.viewModel.profileRepository,
        tripId: offer.tripId,
        currentUserId: widget.viewModel.currentUserId,
        offerId: offer.id,
        onDissolved: _onCarDissolved,
      );
    }
    return _carChatViewModel!;
  }

  // The creator cancelled this car while we were viewing it — the offer's gone server-side.
  // Just refresh the list; myOffer will be null after, which swaps ChatView out for the
  // offers list on the next build and disposes the car ChatViewModel via its own dispose().
  void _onCarDissolved() {
    widget.viewModel.load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This car was cancelled by the organizer.')),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final error = widget.viewModel.error;
        if (error != null) {
          return Scaffold(body: Center(child: Text('Error: $error')));
        }

        final myOffer = widget.viewModel.myOffer;
        if (myOffer != null) {
          // No FAB while in a car — "Add transport info" doesn't apply once you're already
          // committed to one (a diver can only book one ride per trip).
          return Scaffold(body: ChatView(viewModel: _ensureCarChatViewModel(myOffer), isCancelled: widget.isCancelled));
        }

        // No active car right now — whatever ChatView was showing one (if any) has already
        // unmounted and disposed its ChatViewModel by rendering here instead (see the myOffer
        // branch above). Clearing the cache means the *next* time a car chat renders — even
        // for the very same offer, e.g. leave then rejoin — _ensureCarChatViewModel builds a
        // fresh instance instead of handing back the stale disposed one (matching offer.id
        // alone isn't enough to know the old ChatViewModel is still alive).
        _carChatOfferId = null;
        _carChatViewModel = null;

        final offers = widget.viewModel.offers;
        return Scaffold(
          body: offers.isEmpty
              ? EmptyStateView(
                  icon: Icons.directions_car_outlined,
                  title: widget.isCancelled ? 'No transport was arranged' : 'Be the first to share transport',
                  subtitle: widget.isCancelled
                      ? 'This trip has been cancelled.'
                      : 'Offer a ride or share a rental so others can join you.',
                  ctaLabel: widget.isCancelled ? null : 'Add transport info',
                  onCtaPressed: widget.isCancelled ? null : () => _openAddSheet(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _OfferTile(
                    offer: offers[index],
                    onTap: () => _openDetailSheet(context, offers[index]),
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
      builder: (_) => _AddTransportOfferSheet(viewModel: widget.viewModel),
    );
  }

  void _openDetailSheet(BuildContext context, TransportOffer offer) {
    showTransportOfferDetailSheet(
      context,
      offerId: offer.id,
      viewModel: widget.viewModel,
      isCancelled: widget.isCancelled,
      businessName: widget.businessName,
    );
  }
}

/// Public entry point so the ⓘ affordance on the Transport tab itself (TripConversationPage)
/// can open the same sheet a diver already in a car would reach by tapping its row in the
/// list — that's the same sheet, just also reachable one level higher up once you're in it
/// and the list is replaced by the chat.
void showTransportOfferDetailSheet(
  BuildContext context, {
  required String offerId,
  required TransportViewModel viewModel,
  bool isCancelled = false,
  String? businessName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TransportOfferDetailSheet(
      offerId: offerId,
      viewModel: viewModel,
      isCancelled: isCancelled,
      businessName: businessName,
    ),
  );
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, required this.onTap});

  final TransportOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = offer.seats != null && offer.joinedCount >= offer.seats!;

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
              _typeIcons[offer.type] ?? Icons.directions_car,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabels[offer.type] ?? offer.type,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (offer.seats != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${offer.joinedCount} of ${offer.seats} seats taken',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (offer.details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      offer.details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (offer.joined) ...[
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

class _TransportOfferDetailSheet extends StatefulWidget {
  const _TransportOfferDetailSheet({
    required this.offerId,
    required this.viewModel,
    this.isCancelled = false,
    this.businessName,
  });

  final String offerId;
  final TransportViewModel viewModel;
  final bool isCancelled;
  final String? businessName;

  @override
  State<_TransportOfferDetailSheet> createState() =>
      _TransportOfferDetailSheetState();
}

class _TransportOfferDetailSheetState
    extends State<_TransportOfferDetailSheet> {
  List<String>? _joinedUserIds;
  final Map<String, Profile> _profiles = {};
  String? _error;
  String? _joinError;
  String? _actionError;
  bool _isActing = false;

  // Null once the offer's gone from the list — dissolved (by us or the creator, live via
  // realtime while this sheet was open) or, for a joiner, left. The old firstWhere(orElse:
  // () => offers.first) fallback this replaces would throw on an empty list instead.
  TransportOffer? get _offer {
    final offers = widget.viewModel.offers;
    final index = offers.indexWhere((o) => o.id == widget.offerId);
    return index == -1 ? null : offers[index];
  }

  @override
  void initState() {
    super.initState();
    _loadJoinedUserIds();
    final offer = _offer;
    if (offer != null) _loadProfile(offer.userId);
  }

  // Best-effort, one-at-a-time — a profile fetch failing just leaves that row on the
  // generic "Diver" fallback rather than blocking the rest of the sheet.
  Future<void> _loadProfile(String userId) async {
    if (_profiles.containsKey(userId)) return;
    try {
      final p = await widget.viewModel.profileRepository.getPublicProfile(userId);
      if (mounted) setState(() => _profiles[userId] = p);
    } catch (_) {
      // ignore — row falls back to "Diver"
    }
  }

  Future<void> _loadJoinedUserIds() async {
    try {
      final ids = await widget.viewModel.getJoinedUserIds(widget.offerId);
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

  Future<void> _join(TransportOffer offer) async {
    final userId = await ensureSignedIn(
      context,
      widget.viewModel.authRepository,
      widget.viewModel.profileRepository,
      widget.viewModel.pushRepository,
    );
    if (userId == null || !mounted) return;

    setState(() => _joinError = null);
    final error = await widget.viewModel.join(offer.id);
    if (!mounted) return;
    if (error != null) {
      setState(() => _joinError = error);
    } else {
      _loadJoinedUserIds();
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
            final offer = _offer;
            if (offer == null) {
              // Gone (dissolved, or we just left it) while this sheet was open — close it
              // next frame rather than rendering against a missing offer.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }
            final isFull =
                offer.seats != null && offer.joinedCount >= offer.seats!;
            final isOrganizer = offer.userId == widget.viewModel.currentUserId;
            // A diver can only book one ride per trip — don't offer a Join button
            // on other offers once they've already joined one.
            final hasBookingElsewhere = !offer.joined &&
                widget.viewModel.offers.any((o) => o.joined);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_typeIcons[offer.type] ?? Icons.directions_car),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _typeLabels[offer.type] ?? offer.type,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (offer.joined)
                      const _StatusPill(
                        label: 'Joined',
                        kind: _StatusKind.success,
                      )
                    else if (isFull)
                      const _StatusPill(label: 'Full', kind: _StatusKind.info),
                  ],
                ),
                if (offer.details != null) ...[
                  const SizedBox(height: 8),
                  Text(offer.details!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Builder(builder: (context) {
                  final organizerProfile = _profiles[offer.userId];
                  final baseOrganizerName = (organizerProfile?.displayName?.isNotEmpty ?? false)
                      ? organizerProfile!.displayName!
                      : 'Organizer';
                  final organizerName = (offer.isDiveCenterStaff && (widget.businessName?.isNotEmpty ?? false))
                      ? '$baseOrganizerName | ${widget.businessName}'
                      : baseOrganizerName;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openProfile(offer.userId),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          backgroundImage: (organizerProfile?.avatarUrl?.isNotEmpty ?? false)
                              ? NetworkImage(organizerProfile!.avatarUrl!)
                              : null,
                          child: (organizerProfile?.avatarUrl?.isNotEmpty ?? false)
                              ? null
                              : Icon(Icons.person, color: theme.colorScheme.onSecondaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(organizerName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              isOrganizer ? 'Organizer · You' : 'Organizer',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text('Joined divers', style: theme.textTheme.labelLarge),
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
                    final name = (diverProfile?.displayName?.isNotEmpty ?? false)
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
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              backgroundImage: (diverProfile?.avatarUrl?.isNotEmpty ?? false)
                                  ? NetworkImage(diverProfile!.avatarUrl!)
                                  : null,
                              child: (diverProfile?.avatarUrl?.isNotEmpty ?? false)
                                  ? null
                                  : Icon(Icons.person, size: 18, color: theme.colorScheme.onSecondaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Text(name, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    );
                  }),
                if (!offer.joined && !isFull && !hasBookingElsewhere && !widget.isCancelled) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _JoinButton(
                      offer: offer,
                      viewModel: widget.viewModel,
                      onPressed: () => _join(offer),
                    ),
                  ),
                  if (_joinError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _joinError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ] else if (!widget.isCancelled && (isOrganizer || offer.joined)) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isActing ? null : (isOrganizer ? () => _dissolve(offer) : () => _leave(offer)),
                      style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      child: _isActing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isOrganizer ? 'Cancel car offer' : 'Leave car'),
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

  Future<void> _leave(TransportOffer offer) async {
    setState(() {
      _isActing = true;
      _actionError = null;
    });
    final error = await widget.viewModel.leave(offer.id);
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

  Future<void> _dissolve(TransportOffer offer) async {
    setState(() {
      _isActing = true;
      _actionError = null;
    });
    final error = await widget.viewModel.dissolve(offer.id);
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
    required this.offer,
    required this.viewModel,
    required this.onPressed,
  });

  final TransportOffer offer;
  final TransportViewModel viewModel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isJoining = viewModel.isJoining(offer.id);
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

class _AddTransportOfferSheet extends StatefulWidget {
  const _AddTransportOfferSheet({required this.viewModel});

  final TransportViewModel viewModel;

  @override
  State<_AddTransportOfferSheet> createState() =>
      _AddTransportOfferSheetState();
}

class _AddTransportOfferSheetState extends State<_AddTransportOfferSheet> {
  String _type = 'offer_ride';
  final _seatsController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _seatsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

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
              'Add transport info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeLabels.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: _type == entry.key,
                  onSelected: (_) => setState(() => _type = entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seatsController,
              decoration: const InputDecoration(labelText: 'Seats (optional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Details — time, pickup point (optional)',
              ),
              maxLines: 2,
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
                    : const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final seats = int.tryParse(_seatsController.text.trim());
    final details = _detailsController.text.trim();
    final ok = await widget.viewModel.submit(
      type: _type,
      seats: seats,
      details: details.isEmpty ? null : details,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}
