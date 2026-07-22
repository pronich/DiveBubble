/// Dive centers enter their own website (and a trip's own booking URL) as plain text with
/// no format enforcement, client or backend — "northcurrent.dk" is just as valid an entry as
/// "https://northcurrent.dk". url_launcher can't open a schemeless string (silently fails,
/// no error surfaced), so every external link built from user-entered text goes through this
/// first — already-qualified URLs pass through untouched.
Uri externalUri(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Uri.parse(trimmed);
  }
  return Uri.parse('https://$trimmed');
}
