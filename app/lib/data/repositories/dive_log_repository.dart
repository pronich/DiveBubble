import '../../domain/entities/dive_log_entry.dart';
import '../services/dive_log_api_service.dart';

class DiveLogRepository {
  DiveLogRepository({required DiveLogApiService service}) : _service = service;

  final DiveLogApiService _service;

  Future<List<DiveLogEntry>> getEntries() => _service.fetchEntries();

  Future<DiveLogEntry> createEntry({
    required DateTime divedAt,
    double? maxDepthM,
    int? durationMinutes,
    double? minTemperatureC,
    String? siteName,
    String? notes,
  }) => _service.createEntry(
    divedAt: divedAt,
    maxDepthM: maxDepthM,
    durationMinutes: durationMinutes,
    minTemperatureC: minTemperatureC,
    siteName: siteName,
    notes: notes,
  );

  Future<DiveLogEntry> updateEntry(
    String id, {
    required DateTime divedAt,
    double? maxDepthM,
    int? durationMinutes,
    double? minTemperatureC,
    String? siteName,
    String? notes,
  }) => _service.updateEntry(
    id,
    divedAt: divedAt,
    maxDepthM: maxDepthM,
    durationMinutes: durationMinutes,
    minTemperatureC: minTemperatureC,
    siteName: siteName,
    notes: notes,
  );

  Future<DiveLogImportResult> importUDDF(String filePath) => _service.importUDDF(filePath);

  Future<void> deleteEntry(String id) => _service.deleteEntry(id);
}
