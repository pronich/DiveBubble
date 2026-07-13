import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../trips/view_models/trip_view_model.dart';
import '../../trips/views/trip_page.dart';
import '../view_models/chat_view_model.dart';

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.viewModel,
    required this.tripTitle,
    required this.tripRepository,
  });

  final ChatViewModel viewModel;
  final String tripTitle;
  final TripRepository tripRepository;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _textController.dispose();
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(onTap: _openTripPage, child: Text(widget.tripTitle)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                if (widget.viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final error = widget.viewModel.error;
                if (error != null) {
                  return Center(child: Text('Error: $error'));
                }

                final messages = widget.viewModel.messages;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: messages[index], isMine: messages[index].userId == widget.viewModel.currentUserId),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = _textController.text;
                      _textController.clear();
                      widget.viewModel.send(text);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTripPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: widget.tripRepository,
            tripId: widget.viewModel.tripId,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine ? colorScheme.primary : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.body,
          style: TextStyle(color: isMine ? colorScheme.onPrimary : colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
