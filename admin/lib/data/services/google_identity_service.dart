import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_identity_services_web/loader.dart' as gis_loader;
import 'package:web/web.dart' as web;

/// Replaces google_sign_in/google_sign_in_web (removed 2026-07-20): those packages' plugin is constructed by Flutter's web plugin registration before our code runs and its constructor eagerly kicks off loadWebSdk() in the background, which was observed hanging the app in production — this class only loads the GIS script when [ensureLoaded] is explicitly called.
class GoogleIdentityService {
  static const _viewType = 'divebubble_google_signin_button';
  static bool _viewFactoryRegistered = false;

  Future<void>? _loadFuture;
  bool _initialized = false;

  Future<void> ensureLoaded() => _loadFuture ??= gis_loader.loadWebSdk();

  /// Per GIS's own docs, initialize() must only be called once per page — guarded here in case a caller invokes it more than once.
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

  /// Idempotent — safe to call from every CustomGoogleButton build.
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
