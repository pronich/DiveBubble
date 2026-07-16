// Plain class, not freezed — same pragmatic call as ChatMessage/TransportOffer.
class TripPhoto {
  const TripPhoto({required this.id, required this.url, required this.position});

  final String id;
  final String url;
  final int position;

  factory TripPhoto.fromJson(Map<String, dynamic> json) => TripPhoto(
        id: json['id'] as String,
        url: json['url'] as String,
        position: json['position'] as int,
      );
}
