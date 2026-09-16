/// Needed because url_launcher can't open a schemeless string (silently fails, no error surfaced), and website/booking URLs are entered as plain text with no format enforcement.
Uri externalUri(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Uri.parse(trimmed);
  }
  return Uri.parse('https://$trimmed');
}
