/// Fixed rather than free text, so values can be compared/filtered consistently later ("AOW" vs "Advanced Open Water" vs "advanced open water").
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

/// For read-only display only — selection UI keeps the full canonical name, since that's what's actually stored/matched. Falls back to "Open to all" for a null/empty level.
String certificationLevelAbbreviation(String? level) {
  if (level == null || level.isEmpty) return 'Open to all';
  return _certificationLevelAbbreviations[level] ?? level;
}
