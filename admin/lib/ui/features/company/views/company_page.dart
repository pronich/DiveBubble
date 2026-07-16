import 'package:flutter/material.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../core/widgets/coming_soon_section.dart';

class CompanyPage extends StatelessWidget {
  const CompanyPage({super.key, required this.diveCenter, required this.diveCenterRepository});

  final DiveCenter diveCenter;
  final DiveCenterRepository diveCenterRepository;

  @override
  Widget build(BuildContext context) {
    return const ComingSoonSection(
      title: 'Company',
      subtitle: 'Edit your organization\'s public profile — coming soon.',
    );
  }
}
