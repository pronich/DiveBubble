import '../../../../data/repositories/chat_repository.dart';
import '../../../../domain/entities/chat_link.dart';
import '../../../../domain/entities/media_item.dart';

/// Backs Chat Info's Media/Files/Links tabs (main trip chat only — v1 scope, see the backend's
/// own endpoints). Each tab loads its first page independently and lazily from ChatInfoPage;
/// no shared mutable state, so a plain class is enough — nothing here needs ChangeNotifier.
class ChatInfoViewModel {
  ChatInfoViewModel({required ChatRepository repository, required this.tripId}) : _repository = repository;

  final ChatRepository _repository;
  final String tripId;

  Future<List<MediaItem>> loadMedia() => _repository.getMediaAttachments(tripId);
  Future<List<MediaItem>> loadFiles() => _repository.getFileAttachments(tripId);
  Future<List<ChatLink>> loadLinks() => _repository.getLinks(tripId);
}
