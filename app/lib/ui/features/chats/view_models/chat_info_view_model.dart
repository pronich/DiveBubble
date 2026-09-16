import '../../../../data/repositories/chat_repository.dart';
import '../../../../domain/entities/chat_link.dart';
import '../../../../domain/entities/media_item.dart';

/// A plain class, not a ChangeNotifier — each tab loads its own page independently and lazily, with no shared mutable state.
class ChatInfoViewModel {
  ChatInfoViewModel({required ChatRepository repository, required this.tripId}) : _repository = repository;

  final ChatRepository _repository;
  final String tripId;

  Future<List<MediaItem>> loadMedia() => _repository.getMediaAttachments(tripId);
  Future<List<MediaItem>> loadFiles() => _repository.getFileAttachments(tripId);
  Future<List<ChatLink>> loadLinks() => _repository.getLinks(tripId);
}
