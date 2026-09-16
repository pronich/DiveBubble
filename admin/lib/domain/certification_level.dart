/// Mirrors app/'s kCertificationLevels, kept in sync manually since admin/ and app/ don't share code yet.
const List<String> kCertificationLevels = [
  'Open Water',
  'Advanced Open Water',
  'Rescue Diver',
  'Master Scuba Diver',
  'Divemaster',
  'Instructor',
];

const Map<String, String> _certificationLevelAbbreviations = {
  'Open Water': 'OWD',
  'Advanced Open Water': 'AOWD',
  'Rescue Diver': 'Rescue',
  'Master Scuba Diver': 'MSD',
  'Divemaster': 'Dive Master',
  'Instructor': 'Instructor',
};

/// Compact form for read-only display only — selection UI keeps the full canonical name since that's what's actually stored/matched; falls back to "Open to all" for a null/empty level.
String certificationLevelAbbreviation(String? level) {
  if (level == null || level.isEmpty) return 'Open to all';
  return _certificationLevelAbbreviations[level] ?? level;
}
