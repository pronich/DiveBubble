import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../../data/services/google_identity_service.dart';

/// A "Continue with Google" button that actually looks like the rest of this screen's
/// buttons — our brand-tinted FilledButton.tonal style — instead of Google's own
/// stock-rendered widget, which read as visually mismatched next to "Dive in with email".
///
/// Google's Identity Services deliberately doesn't allow restyling its own button (brand
/// guidelines — see https://developers.google.com/identity/branding-guidelines) or
/// redirecting its click to an arbitrary element; the click has to land on Google's own
/// real button. So this renders the real button (via [GoogleIdentityService], see its own
/// doc comment for why that's a direct `google_identity_services_web` call rather than
/// `google_sign_in_web`), sized to match, but made almost fully transparent
/// (`opacity: 0.01` — not 0, since some browsers treat a fully-invisible element's click
/// as untrusted/synthetic and Google's own SDK rejects it) and stacks it on TOP of a
/// purely decorative, `IgnorePointer`-wrapped copy of our own button style underneath.
/// Every real click still lands on Google's real button and goes through the same OAuth
/// flow; only the paint layer is ours. Same technique foreignreader_public's own web
/// login page uses for its Google button (an invisible real `GoogleLogin` widget stacked
/// under a custom-styled div there).
class CustomGoogleButton extends StatelessWidget {
  const CustomGoogleButton({super.key, required this.googleIdentity});

  final GoogleIdentityService googleIdentity;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // GIS's own minimumWidth caps out at 400px — clamp so a wide parent doesn't just
        // silently get a narrower real button than the fake one drawn on top of it.
        final width = constraints.maxWidth.clamp(1.0, 400.0);

        return SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A real FilledButton.tonal (not a hand-rolled Container) so it picks up this
              // theme's actual colors/radius/font automatically — including any future
              // theme change — rather than a second, separately-maintained copy of that
              // styling. onPressed is non-null purely so it *paints* enabled; IgnorePointer
              // below is what actually stops it from ever receiving the click.
              IgnorePointer(
                child: FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.g_mobiledata, size: 26),
                  label: const Text('Continue with Google'),
                ),
              ),
              Opacity(
                opacity: 0.01,
                child: HtmlElementView(
                  viewType: GoogleIdentityService.buildButtonViewType(),
                  onPlatformViewCreated: (int viewId) {
                    final element = ui_web.platformViewRegistry.getViewById(viewId);
                    if (element is web.Element) googleIdentity.renderButton(element, width: width);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
