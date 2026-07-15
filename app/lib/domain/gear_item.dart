/// Fixed "Essential" gear catalogue — items without which a dive isn't possible at all.
/// Anything beyond this (torch, action camera, buoy, ...) goes in the free-text
/// "Additional" list instead of growing this fixed set further.
class GearItem {
  final String key;
  final String label;

  const GearItem(this.key, this.label);
}

const List<GearItem> kEssentialGearItems = [
  GearItem('boots', 'Boots'),
  GearItem('fins', 'Fins'),
  GearItem('bcd', 'BCD'),
  GearItem('wetsuit_shorty_5mm', 'Wetsuit shorty 5mm'),
  GearItem('wetsuit_5mm', 'Wetsuit 5mm'),
  GearItem('wetsuit_7mm', 'Wetsuit 7mm'),
  GearItem('wetsuit_9mm', 'Wetsuit 9mm'),
  GearItem('semidry_suit', 'Semidry suit'),
  GearItem('dry_suit', 'Dry suit'),
  GearItem('helmet', 'Helmet'),
  GearItem('gloves', 'Gloves'),
  GearItem('regulator', 'Regulator'),
  GearItem('computer', 'Computer'),
  GearItem('mask', 'Mask'),
];

/// Matches the backend's free-text `status` column — validated here, not with a DB CHECK,
/// same pattern as certification_level/languages.
enum GearStatus {
  owned('owned'),
  missing('missing'),
  rents('rents');

  final String value;
  const GearStatus(this.value);

  static GearStatus fromValue(String value) => GearStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => GearStatus.missing,
      );
}
