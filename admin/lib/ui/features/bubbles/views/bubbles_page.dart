import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import '../view_models/bubbles_view_model.dart';

/// Body-only (embedded in AdminShell). Named "Bubbles" (not "Messages") to match the app's
/// own branding — a joined trip *is* its chat there too (see CLAUDE.md's Navigation / IA
/// section), so this screen is literally the same concept from the organization's side.
class BubblesPage extends StatefulWidget {
  const BubblesPage({
    super.key,
    required this.tripRepository,
    required this.messageRepository,
    required this.profileRepository,
    required this.diveCenterId,
    required this.getCurrentUserId,
  });

  final TripRepository tripRepository;
  final MessageRepository messageRepository;
  final ProfileRepository profileRepository;
  final String diveCenterId;
  final Future<String?> Function() getCurrentUserId;

  @override
  State<BubblesPage> createState() => _BubblesPageState();
}

class _BubblesPageState extends State<BubblesPage> {
  BubblesViewModel? _viewModel;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final userId = await widget.getCurrentUserId();
    final vm = BubblesViewModel(
      tripRepository: widget.tripRepository,
      messageRepository: widget.messageRepository,
      profileRepository: widget.profileRepository,
      diveCenterId: widget.diveCenterId,
      currentUserId: userId ?? '',
    );
    await vm.loadTrips();
    if (!mounted) return;
    setState(() => _viewModel = vm);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _selectTrip(String tripId) async {
    await _viewModel!.selectTrip(tripId);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final body = _messageController.text;
    if (body.trim().isEmpty) return;
    _messageController.clear();
    final error = await _viewModel!.send(body);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Row(
          children: [
            SizedBox(width: 320, child: _Inbox(viewModel: vm, onSelect: _selectTrip)),
            VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Expanded(child: _Conversation(viewModel: vm, controller: _messageController, scrollController: _scrollController, onSend: _send)),
          ],
        );
      },
    );
  }
}

class _Inbox extends StatefulWidget {
  const _Inbox({required this.viewModel, required this.onSelect});

  final BubblesViewModel viewModel;
  final ValueChanged<String> onSelect;

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;
    final query = _search.trim().toLowerCase();
    final trips = query.isEmpty ? viewModel.trips : viewModel.trips.where((t) => t.title.toLowerCase().contains(query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INBOX',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text('Bubbles', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (viewModel.trips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search trips', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
        Expanded(
          child: viewModel.isLoadingTrips
              ? const Center(child: CircularProgressIndicator())
              : viewModel.trips.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No trips yet — create one to start a conversation with your divers.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : trips.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('No matches.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        )
                      : ListView(
                          children: [
                            for (final trip in trips)
                              _InboxRow(trip: trip, selected: trip.id == viewModel.selectedTripId, onTap: () => widget.onSelect(trip.id)),
                          ],
                        ),
        ),
      ],
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.trip, required this.selected, required this.onTap});

  final Trip trip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = trip.title.trim().isEmpty ? '?' : trip.title.trim().substring(0, 1).toUpperCase();
    return Material(
      color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(initials, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatShortDate(trip.startTime)} · ${trip.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (trip.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    trip.unreadCount > 9 ? '9+' : '${trip.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({required this.viewModel, required this.controller, required this.scrollController, required this.onSend});

  final BubblesViewModel viewModel;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = viewModel.selectedTrip;
    if (trip == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bubble_chart_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Select a Bubble to view its conversation.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final cancelled = trip.bookingStatus == 'cancelled';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant))),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  trip.title.trim().isEmpty ? '?' : trip.title.trim().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '${formatShortDate(trip.startTime)} · ${trip.location}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: viewModel.isLoadingMessages
              ? const Center(child: CircularProgressIndicator())
              : viewModel.messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [for (final m in viewModel.messages) _MessageBubble(message: m, viewModel: viewModel)],
                    ),
        ),
        if (cancelled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              'This trip has been cancelled — the conversation is read-only.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
            child: Row(
              children: [
                Expanded(
                  // Enter alone sends (and is swallowed here so it never lands as a
                  // newline first); Shift+Enter falls through to the TextField and
                  // inserts a newline normally — needs keyboardType: multiline, since a
                  // single-line field never lets Enter produce a newline to begin with.
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        onSend();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: 'Message ${trip.title} as organization'),
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: viewModel.isSending ? null : onSend,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.viewModel});

  final ChatMessage message;
  final BubblesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwn = message.userId == viewModel.currentUserId;
    final senderName = isOwn ? 'You' : (viewModel.senderProfiles[message.userId]?.displayName ?? 'Diver');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(senderName, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwn ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(message.body, style: TextStyle(color: isOwn ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              TimeOfDay.fromDateTime(message.createdAt.toLocal()).format(context),
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
