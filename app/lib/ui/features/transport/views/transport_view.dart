import 'package:flutter/material.dart';

import '../../../../data/services/error_codes.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/transport_offer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/auth/ensure_signed_in.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../chats/view_models/chat_view_model.dart';
import '../../chats/views/chat_view.dart';
import '../../profile/views/diver_id_card.dart';
import '../view_models/transport_view_model.dart';

// Canonical backend values, never translated — only the displayed label goes through _typeLabel below.
const _transportTypes = ['offer_ride', 'share_rental'];

const _typeIcons = {
  'offer_ride': Icons.directions_car,
  'share_rental': Icons.car_rental,
};

String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
  'offer_ride' => l10n.typeOfferRide,
  'share_rental' => l10n.typeShareRental,
  _ => type,
};

class TransportView extends StatefulWidget {
  const TransportView({
    super.key,
    required this.viewModel,
    required this.chatRepository,
    required this.realtimeService,
    required this.tripRepository,
    this.isCancelled = false,
    this.businessName,
  });

  final TransportViewModel viewModel;

  /// Needed only once the diver is in a car, to build that car's own ChatView.
  final ChatRepository chatRepository;
  final RealtimeService realtimeService;
  final TripRepository tripRepository;

  /// Mirrors ChatView.isCancelled: existing offers/joins stay visible, but nothing new can be created or joined.
  final bool isCancelled;

  /// Only ever combined with offer.isDiveCenterStaff, so a regular diver's own offer never looks like it came from the organization.
  final String? businessName;

  @override
  State<TransportView> createState() => _TransportViewState();
}

class _TransportViewState extends State<TransportView>
    with AutomaticKeepAliveClientMixin {
  // Prevents TabBarView from disposing this offscreen tab, which would otherwise re-trigger a full offer reload every time it scrolls back into view.
  @override
  bool get wantKeepAlive => true;

  // Cache only, NOT a disposal owner — ChatView.dispose() already disposes it on every unmount, so disposing it again here would double-dispose and crash.
  ChatViewModel? _carChatViewModel;
  String? _carChatOfferId;

  // No load() call here: TripConversationPage.initState already loads this ViewModel eagerly, and a second load here could unmount a live ChatView mid-flash without resetting _carChatOfferId.

  ChatViewModel _ensureCarChatViewModel(TransportOffer offer) {
    if (_carChatOfferId != offer.id) {
      _carChatOfferId = offer.id;
      _carChatViewModel = ChatViewModel(
        repository: widget.chatRepository,
        realtimeService: widget.realtimeService,
        profileRepository: widget.viewModel.profileRepository,
        tripRepository: widget.tripRepository,
        tripId: offer.tripId,
        currentUserId: widget.viewModel.currentUserId,
        offerId: offer.id,
        onDissolved: _onCarDissolved,
      );
    }
    return _carChatViewModel!;
  }

  // Refreshing makes myOffer null, which swaps ChatView out for the offers list and disposes the car ChatViewModel via its own dispose().
  void _onCarDissolved() {
    widget.viewModel.load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).carCancelledByOrganizer),
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
        final l10n = AppLocalizations.of(context);
        // Only the very first load shows the full-screen spinner: a background refresh while a car chat is open must not swap it out, or ChatView would end up disposed without resetting _carChatOfferId.
        if (widget.viewModel.isLoading && widget.viewModel.offers.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final error = widget.viewModel.error;
        if (error != null) {
          return Scaffold(body: Center(child: Text(l10n.errorWithMessage(error))));
        }

        final myOffer = widget.viewModel.myOffer;
        if (myOffer != null) {
          // No FAB while in a car — a diver can only book one ride per trip.
          return Scaffold(
            body: ChatView(
              viewModel: _ensureCarChatViewModel(myOffer),
              isCancelled: widget.isCancelled,
            ),
          );
        }

        // Clearing the cache here ensures the next car chat (even a rejoin of the same offer.id) gets a fresh ChatViewModel instead of the one already disposed above.
        _carChatOfferId = null;
        _carChatViewModel = null;

        final offers = widget.viewModel.offers;
        return Scaffold(
          body: offers.isEmpty
              ? EmptyStateView(
                  icon: Icons.directions_car_outlined,
                  title: widget.isCancelled
                      ? l10n.noTransportWasArranged
                      : l10n.beFirstToShareTransport,
                  subtitle: widget.isCancelled
                      ? l10n.tripCancelledSimple
                      : l10n.offerRideOrShareRental,
                  ctaLabel: widget.isCancelled ? null : l10n.addTransportInfo,
                  onCtaPressed: widget.isCancelled
                      ? null
                      : () => _openAddSheet(context),
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

/// Lets the ⓘ affordance on TripConversationPage open the same sheet a diver in a car would reach via the list, which is otherwise replaced by the chat.
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
    final l10n = AppLocalizations.of(context);
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
                    _typeLabel(l10n, offer.type),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (offer.seats != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.seatsTakenLabel(offer.joinedCount, offer.seats!),
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
              _StatusPill(label: l10n.joinedStatus, kind: _StatusKind.success),
            ] else if (isFull) ...[
              const SizedBox(width: 12),
              _StatusPill(label: l10n.fullStatus, kind: _StatusKind.info),
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

  // Null once the offer's gone from the list — dissolved or left, possibly live via realtime while this sheet is open.
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

  // Best-effort — a failed fetch just leaves that row on the generic "Diver" fallback rather than blocking the rest of the sheet.
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
      final ids = await widget.viewModel.getJoinedUserIds(widget.offerId);
      if (mounted) setState(() => _joinedUserIds = ids);
      for (final id in ids) {
        _loadProfile(id);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
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
      // Close the sheet so the now-joined car's chat, swapped in automatically via TransportView's ListenableBuilder, is immediately visible.
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
            final l10n = AppLocalizations.of(context);
            final offer = _offer;
            if (offer == null) {
              // Gone while this sheet was open — close it next frame rather than rendering against a missing offer.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop())
                  Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }
            final isFull =
                offer.seats != null && offer.joinedCount >= offer.seats!;
            final isOrganizer = offer.userId == widget.viewModel.currentUserId;
            // A diver can only book one ride per trip, so hide Join once they've joined one.
            final hasBookingElsewhere =
                !offer.joined && widget.viewModel.offers.any((o) => o.joined);

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
                        _typeLabel(l10n, offer.type),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (offer.joined)
                      _StatusPill(
                        label: l10n.joinedStatus,
                        kind: _StatusKind.success,
                      )
                    else if (isFull)
                      _StatusPill(label: l10n.fullStatus, kind: _StatusKind.info),
                  ],
                ),
                if (offer.details != null) ...[
                  const SizedBox(height: 8),
                  Text(offer.details!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final organizerProfile = _profiles[offer.userId];
                    final baseOrganizerName =
                        (organizerProfile?.displayName?.isNotEmpty ?? false)
                        ? organizerProfile!.displayName!
                        : l10n.organizerLabel;
                    final organizerName =
                        (offer.isDiveCenterStaff &&
                            (widget.businessName?.isNotEmpty ?? false))
                        ? '$baseOrganizerName | ${widget.businessName}'
                        : baseOrganizerName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openProfile(offer.userId),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            backgroundImage:
                                (organizerProfile?.avatarUrl?.isNotEmpty ??
                                    false)
                                ? NetworkImage(organizerProfile!.avatarUrl!)
                                : null,
                            child:
                                (organizerProfile?.avatarUrl?.isNotEmpty ??
                                    false)
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
                                organizerName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isOrganizer ? l10n.organizerYou : l10n.organizerLabel,
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
                Text(l10n.joinedDivers, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (_error != null)
                  Text(
                    l10n.errorWithMessage(_error!),
                    style: TextStyle(color: theme.colorScheme.error),
                  )
                else if (_joinedUserIds == null)
                  const Center(child: CircularProgressIndicator())
                else if (_joinedUserIds!.isEmpty)
                  Text(
                    l10n.noOneHasJoinedYet,
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
                        : (isMe ? l10n.you : l10n.diver);
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
                if (!isOrganizer &&
                    !offer.joined &&
                    !isFull &&
                    !hasBookingElsewhere &&
                    !widget.isCancelled) ...[
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
                ] else if (!widget.isCancelled &&
                    (isOrganizer || offer.joined)) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isActing
                          ? null
                          : (isOrganizer
                                ? () => _dissolve(offer)
                                : () => _leave(offer)),
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
                              isOrganizer ? l10n.cancelCarOffer : l10n.leaveCar,
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
          : Text(AppLocalizations.of(context).join),
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
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _seatsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              l10n.addTransportInfo,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _transportTypes.map((type) {
                return ChoiceChip(
                  label: Text(_typeLabel(l10n, type)),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seatsController,
              decoration: InputDecoration(labelText: l10n.seatsOptional),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.detailsTimePickupOptional,
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final seats = int.tryParse(_seatsController.text.trim());
    final details = _detailsController.text.trim();
    final error = await widget.viewModel.submit(
      type: _type,
      seats: seats,
      details: details.isEmpty ? null : details,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSubmitting = false;
        _error = error;
      });
    }
  }
}
