import 'package:flutter/material.dart';

import '../view_models/trip_view_model.dart';

class TripPage extends StatefulWidget {
  const TripPage({super.key, required this.viewModel});

  final TripViewModel viewModel;

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = widget.viewModel.error;
          if (error != null) {
            return Center(child: Text('Error: $error'));
          }

          final trip = widget.viewModel.trip;
          if (trip == null) {
            return const SizedBox.shrink();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(trip.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(trip.location, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text('${trip.startTime.toLocal()}'),
              const SizedBox(height: 24),
              if (trip.joined)
                const Chip(label: Text('Joined'))
              else
                ElevatedButton(
                  onPressed: widget.viewModel.isJoining ? null : widget.viewModel.join,
                  child: widget.viewModel.isJoining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join'),
                ),
            ],
          );
        },
      ),
    );
  }
}
