/// Plain class, not freezed — same precedent as MyProfile. Photo upload isn't ported to
/// admin/'s simplified Account page (see AccountPage's own doc comment), so photoUrl/
/// verified are read-only display fields with no client-side mutation path here.
class SpecialtyCertification {
  const SpecialtyCertification({
    required this.id,
    required this.specialty,
    this.customLabel,
    this.agency,
    this.certNumber,
    this.photoUrl,
    this.verified = false,
  });

  final String id;
  final String specialty;
  final String? customLabel;
  final String? agency;
  final String? certNumber;
  final String? photoUrl;
  final bool verified;

  factory SpecialtyCertification.fromJson(Map<String, dynamic> json) => SpecialtyCertification(
        id: json['id'] as String,
        specialty: json['specialty'] as String,
        customLabel: json['customLabel'] as String?,
        agency: json['agency'] as String?,
        certNumber: json['certNumber'] as String?,
        photoUrl: json['photoUrl'] as String?,
        verified: json['verified'] as bool? ?? false,
      );

  /// "Other" pairs with customLabel as the real display name; every other type's own name
  /// is already the label.
  String get displayLabel => specialty == 'Other' && (customLabel?.isNotEmpty ?? false) ? customLabel! : specialty;
}
