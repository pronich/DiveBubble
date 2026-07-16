/// Same list as app/'s kCertificationLevels — kept in sync manually (see CLAUDE.md:
/// admin/ and app/ don't share code yet, a deliberate MVP choice).
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

/// Compact form for read-only display (badges, tiles, table cells) — dropdowns and other
/// selection UI keep the full canonical name from kCertificationLevels above, since that's
/// what's actually stored/matched. Falls back to "Open to all" for a null/empty level
/// (e.g. a trip with no minimum set).
String certificationLevelAbbreviation(String? level) {
  if (level == null || level.isEmpty) return 'Open to all';
  return _certificationLevelAbbreviations[level] ?? level;
}
