import 'package:flutter/material.dart';

// Placeholder until diver profile features land.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: Theme.of(context).textTheme.headlineSmall)),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
