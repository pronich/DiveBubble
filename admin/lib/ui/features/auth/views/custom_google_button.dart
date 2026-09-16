import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../../data/services/google_identity_service.dart';

/// Since GIS forbids restyling or redirecting clicks off its real button, this stacks GIS's real button on top at opacity 0.01 (not 0, since some browsers reject a fully-invisible element's click as untrusted) over a purely decorative IgnorePointer-wrapped copy of our own button style, so every click still lands on Google's button but the paint layer is ours.
class CustomGoogleButton extends StatelessWidget {
  const CustomGoogleButton({super.key, required this.googleIdentity});

  final GoogleIdentityService googleIdentity;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // GIS's own minimumWidth caps out at 400px — clamp so a wide parent doesn't get a narrower real button than the fake one on top of it.
        final width = constraints.maxWidth.clamp(1.0, 400.0);

        return SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A real FilledButton.tonal (not a hand-rolled Container) so it tracks theme changes automatically; onPressed is non-null only so it paints enabled, IgnorePointer stops it receiving clicks.
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
