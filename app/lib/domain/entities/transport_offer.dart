import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_offer.freezed.dart';

@freezed
abstract class TransportOffer with _$TransportOffer {
  const factory TransportOffer({
    required String id,
    required String tripId,
    required String userId,
    required String type,
    int? seats,
    String? details,
    required DateTime createdAt,
    @Default(0) int joinedCount,
    @Default(false) bool joined,
    // Mirrors ChatMessage.isDiveCenterStaff's "Name | Dive Center" attribution precedent.
    @Default(false) bool isDiveCenterStaff,
    // Distinct from TransportViewModel.hasAlert (a dissolved car you'd joined) — this is ordinary new activity in a chat you're still part of.
    @Default(false) bool hasUnreadMessages,
  }) = _TransportOffer;
}
