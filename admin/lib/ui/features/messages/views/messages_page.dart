import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon_section.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonSection(
      title: 'Messages',
      subtitle: 'Chat with divers on your trips, sending as your organization — coming next.',
    );
  }
}
