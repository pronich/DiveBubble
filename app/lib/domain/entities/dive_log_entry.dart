/// One dive in the diver's personal log — entirely separate from Profile.diveCount (the
/// self-reported "unlogged dives" number, see EditProfilePage) — the two are simply summed
/// in the UI, never reconciled against each other.
class DiveLogEntry {
  const DiveLogEntry({
    required this.id,
    this.tripId,
    required this.source,
    required this.divedAt,
    this.maxDepthM,
    this.durationMinutes,
    this.minTemperatureC,
    this.siteName,
    this.latitude,
    this.longitude,
    this.notes,
    this.profileSamples = const [],
    required this.createdAt,
  });

  final String id;
  final String? tripId;
  final String source; // 'manual' | 'imported'
  final DateTime divedAt;
  final double? maxDepthM;
  final int? durationMinutes;
  final double? minTemperatureC;
  final String? siteName;
  final double? latitude;
  final double? longitude;
  final String? notes;
  // Only ever non-empty for source == 'imported' — a manual entry has no instrument data to
  // draw a graph from, gated by source in the UI rather than by this being empty (an import
  // with a sparse/missing waypoint section is still "imported", just without a chart).
  final List<DiveProfileSample> profileSamples;
  final DateTime createdAt;

  bool get isImported => source == 'imported';

  factory DiveLogEntry.fromJson(Map<String, dynamic> json) => DiveLogEntry(
    id: json['id'] as String,
    tripId: json['tripId'] as String?,
    source: json['source'] as String,
    divedAt: DateTime.parse(json['divedAt'] as String),
    maxDepthM: (json['maxDepthM'] as num?)?.toDouble(),
    durationMinutes: json['durationMinutes'] as int?,
    minTemperatureC: (json['minTemperatureC'] as num?)?.toDouble(),
    siteName: json['siteName'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
    profileSamples: (json['profileSamples'] as List<dynamic>? ?? [])
        .map((e) => DiveProfileSample.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class DiveProfileSample {
  const DiveProfileSample({required this.offsetSeconds, required this.depthM, this.temperatureC});

  final int offsetSeconds;
  final double depthM;
  final double? temperatureC;

  factory DiveProfileSample.fromJson(Map<String, dynamic> json) => DiveProfileSample(
    offsetSeconds: json['offsetSeconds'] as int,
    depthM: (json['depthM'] as num).toDouble(),
    temperatureC: (json['temperatureC'] as num?)?.toDouble(),
  );
}

/// What an UDDF import actually did — surfaced as "N new, M already logged" rather than
/// assuming every dive in the file was fresh (see the backend's dedup-by-dived_at).
class DiveLogImportResult {
  const DiveLogImportResult({required this.imported, required this.skipped});

  final int imported;
  final int skipped;

  factory DiveLogImportResult.fromJson(Map<String, dynamic> json) =>
      DiveLogImportResult(imported: json['imported'] as int, skipped: json['skipped'] as int);
}
