import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_identity_services_web/loader.dart' as gis_loader;
import 'package:web/web.dart' as web;

/// Thin wrapper directly over `package:google_identity_services_web` — a plain Dart
/// JS-interop library, not a Flutter *plugin* — deliberately used instead of
/// `google_sign_in`/`google_sign_in_web` (removed 2026-07-20, see AuthRepository's own
/// doc comment). Those packages' `GoogleSignInPlugin` is constructed automatically by
/// Flutter's web plugin registration, before any of our own code runs, and its
/// constructor eagerly kicks off `loadWebSdk()` in the background — that was observed
/// hanging the whole app in production. This class is a normal object we construct and
/// call ourselves, so the GIS script only ever loads when *we* decide to call
/// [ensureLoaded] (LoginPage, on mount) — no framework-level side effect tied to the
/// dependency merely existing.
class GoogleIdentityService {
  static const _viewType = 'divebubble_google_signin_button';
  static bool _viewFactoryRegistered = false;

  Future<void>? _loadFuture;
  bool _initialized = false;

  Future<void> ensureLoaded() => _loadFuture ??= gis_loader.loadWebSdk();

  /// Per GIS's own docs, initialize() should only be called once per page — callers
  /// (LoginPage) are expected to only call this once per widget lifetime (initState).
  void initialize({required String clientId, required void Function(String idToken) onCredential}) {
    if (_initialized) return;
    _initialized = true;
    gis.id.initialize(
      gis.IdConfiguration(
        client_id: clientId,
        callback: (gis.CredentialResponse response) {
          final credential = response.credential;
          if (credential != null) onCredential(credential);
        },
      ),
    );
  }

  /// Registers the platform-view factory backing [buildButtonViewType] — idempotent,
  /// safe to call from every CustomGoogleButton build.
  static String buildButtonViewType() {
    if (!_viewFactoryRegistered) {
      _viewFactoryRegistered = true;
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final element = web.document.createElement('div');
        element.setAttribute('style', 'width: 100%; height: 100%;');
        return element;
      });
    }
    return _viewType;
  }

  void renderButton(web.Element parent, {double? width}) {
    gis.id.renderButton(parent, gis.GsiButtonConfiguration(size: gis.ButtonSize.large, width: width));
  }
}
