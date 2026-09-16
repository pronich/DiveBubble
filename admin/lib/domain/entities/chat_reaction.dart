// reactedByMe is per-viewer and never travels over the realtime channel — only ever set from this viewer's own REST calls (see BubblesViewModel._applyReactionUpdate).
class ChatReaction {
  const ChatReaction({required this.count, required this.reactedByMe});

  final int count;
  final bool reactedByMe;

  factory ChatReaction.fromJson(Map<String, dynamic> json) =>
      ChatReaction(count: json['count'] as int, reactedByMe: json['reactedByMe'] as bool? ?? false);
}
