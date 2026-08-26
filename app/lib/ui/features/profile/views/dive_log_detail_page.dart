import 'package:flutter/material.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/dive_log_entry.dart';
import '../../../core/formatting/date_format.dart';
import '../view_models/profile_view_model.dart';
import 'add_edit_dive_log_entry_page.dart';
import 'dive_profile_chart.dart';

class DiveLogDetailPage extends StatelessWidget {
  const DiveLogDetailPage({
    super.key,
    required this.viewModel,
    required this.entry,
    required this.tripRepository,
    required this.chatRepository,
  });

  final ProfileViewModel viewModel;
  final DiveLogEntry entry;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(formatShortDateWithYear(entry.divedAt)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share to Bubble',
            onPressed: () => _openShareSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditDiveLogEntryPage(viewModel: viewModel, existing: entry),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (entry.isImported && entry.profileSamples.length >= 2) ...[
            DiveProfileChart(samples: entry.profileSamples),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              Expanded(
                child: _StatTile(label: 'Max depth', value: _depthText(entry.maxDepthM)),
              ),
              Expanded(
                child: _StatTile(label: 'Avg depth', value: _depthText(entry.avgDepthM)),
              ),
              Expanded(
                child: _StatTile(label: 'Duration', value: _durationText(entry.durationMinutes)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(label: 'Min temp', value: _tempText(entry.minTemperatureC)),
              ),
              Expanded(
                child: _StatTile(label: 'Max temp', value: _tempText(entry.maxTemperatureC)),
              ),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Location', value: entry.locationText ?? '—'),
                const Divider(height: 1),
                _InfoRow(label: 'Source', value: entry.isImported ? 'Imported' : 'Manual'),
              ],
            ),
          ),
          if (entry.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            Text('Notes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(entry.notes!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Future<void> _openShareSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ShareToBubbleSheet(
        entry: entry,
        tripRepository: tripRepository,
        chatRepository: chatRepository,
      ),
    );
  }
}

String _depthText(double? m) => m == null ? '—' : '${m.toStringAsFixed(1)}m';
String _durationText(int? minutes) => minutes == null ? '—' : '$minutes min';
String _tempText(double? c) => c == null ? '—' : '${c.toStringAsFixed(1)}°C';

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picks a joined trip and posts a short text summary of this dive into its Bubble chat —
/// no attachment/rich-card, just a formatted message using the same sendMessage endpoint
/// every other chat message goes through, so the other participants see it exactly like any
/// text message (no special rendering needed on the receiving end).
class _ShareToBubbleSheet extends StatefulWidget {
  const _ShareToBubbleSheet({
    required this.entry,
    required this.tripRepository,
    required this.chatRepository,
  });

  final DiveLogEntry entry;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;

  @override
  State<_ShareToBubbleSheet> createState() => _ShareToBubbleSheetState();
}

class _ShareToBubbleSheetState extends State<_ShareToBubbleSheet> {
  bool _isLoading = true;
  String? _error;
  List<({String id, String title})> _trips = [];
  String? _sendingTripId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final trips = await widget.tripRepository.getMyTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips.map((t) => (id: t.id, title: t.title)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _shareTo(String tripId) async {
    setState(() => _sendingTripId = tripId);
    final e = widget.entry;
    final parts = <String>[
      'Dive on ${formatShortDateWithYear(e.divedAt)}',
      if (e.locationText != null) e.locationText!,
      if (e.maxDepthM != null) 'Max depth: ${_depthText(e.maxDepthM)}',
      if (e.durationMinutes != null) 'Duration: ${_durationText(e.durationMinutes)}',
      if (e.minTemperatureC != null) 'Min temp: ${_tempText(e.minTemperatureC)}',
    ];
    try {
      await widget.chatRepository.sendMessage(tripId, parts.join('\n'));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared to Bubble')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingTripId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 360,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Share to Bubble', style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _trips.isEmpty
                  ? const Center(child: Text('You haven\'t joined any Bubbles yet.'))
                  : ListView.builder(
                      itemCount: _trips.length,
                      itemBuilder: (context, index) {
                        final trip = _trips[index];
                        return ListTile(
                          title: Text(trip.title),
                          trailing: _sendingTripId == trip.id
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                          onTap: _sendingTripId != null ? null : () => _shareTo(trip.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
