import 'package:flutter/material.dart';

import '../../../../domain/entities/specialty_certification.dart';
import 'specialty_card.dart';

/// 0 items -> AddSpecialtyCard tile. 1 item -> a single card. 2+ items -> a tappable
/// deck (front card full, the next few peeking as thin slivers to one side) that unfurls
/// into a horizontal scroll of full cards.
///
/// expanded/onToggle are controlled by the parent (rather than owned as local State) so
/// ProfileView can force-collapse the stack when the Profile tab goes inactive — RootShell's
/// IndexedStack keeps this widget alive across tab switches, so local state alone wouldn't reset.
class SpecialtiesSection extends StatelessWidget {
  const SpecialtiesSection({
    super.key,
    required this.specialties,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
    required this.onPhotoTap,
    this.uploadingPhotoId,
  });

  final List<SpecialtyCertification> specialties;
  final bool expanded;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;
  final void Function(String id) onPhotoTap;
  final String? uploadingPhotoId;

  @override
  Widget build(BuildContext context) {
    if (specialties.isEmpty) {
      return AddSpecialtyCard(onTap: onAdd);
    }

    if (specialties.length == 1) {
      final specialty = specialties.first;
      return SpecialtyCard(
        specialty: specialty,
        onRemove: () => onRemove(specialty.id),
        onPhotoTap: () => onPhotoTap(specialty.id),
        isUploadingPhoto: uploadingPhotoId == specialty.id,
      );
    }

    return _SpecialtyDeck(
      specialties: specialties,
      expanded: expanded,
      onToggle: onToggle,
      onRemove: onRemove,
      onPhotoTap: onPhotoTap,
      uploadingPhotoId: uploadingPhotoId,
    );
  }
}

/// Every card lives in one Stack for the whole widget's life — only each card's `left`
/// (via AnimatedPositioned) and the container's width (via AnimatedContainer) change when
/// `expanded` flips, so Flutter can interpolate smoothly instead of swapping layouts.
class _SpecialtyDeck extends StatelessWidget {
  const _SpecialtyDeck({
    required this.specialties,
    required this.expanded,
    required this.onToggle,
    required this.onRemove,
    required this.onPhotoTap,
    this.uploadingPhotoId,
  });

  final List<SpecialtyCertification> specialties;
  final bool expanded;
  final ValueChanged<bool> onToggle;
  final void Function(String id) onRemove;
  final void Function(String id) onPhotoTap;
  final String? uploadingPhotoId;

  static const double _cardHeight = 150;
  static const double _peekOffset = 16;
  static const double _rowGap = 12;
  static const int _maxPeek = 4;
  static const _duration = Duration(milliseconds: 320);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = specialties.length;
    final peekCount = n > _maxPeek ? _maxPeek : n;
    final collapsedWidth = kSpecialtyCardWidth + (peekCount - 1) * _peekOffset;
    final expandedWidth = n * kSpecialtyCardWidth + (n - 1) * _rowGap;

    double collapsedLeft(int i, double centerOffset) =>
        centerOffset + (i < peekCount ? i * _peekOffset : (peekCount - 1) * _peekOffset);
    double expandedLeft(int i) => i * (kSpecialtyCardWidth + _rowGap);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawCenterOffset = (constraints.maxWidth - collapsedWidth) / 2;
        final centerOffset = rawCenterOffset > 0 ? rawCenterOffset : 0.0;
        final contentWidth = expanded ? expandedWidth : constraints.maxWidth;

        return GestureDetector(
          onTap: expanded ? null : () => onToggle(true),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: expanded ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
            child: AnimatedContainer(
              duration: _duration,
              curve: _curve,
              width: contentWidth,
              height: _cardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Painted back-to-front so the front card (i=0) always ends up on top
                  // while collapsed; order stops mattering once cards no longer overlap.
                  for (var i = n - 1; i >= 0; i--)
                    AnimatedPositioned(
                      key: ValueKey(specialties[i].id),
                      duration: _duration,
                      curve: _curve,
                      top: 0,
                      left: expanded ? expandedLeft(i) : collapsedLeft(i, centerOffset),
                      child: SizedBox(
                        width: kSpecialtyCardWidth,
                        height: _cardHeight,
                        child: SpecialtyCard(
                          specialty: specialties[i],
                          onRemove: expanded ? () => onRemove(specialties[i].id) : null,
                          onPhotoTap: expanded ? () => onPhotoTap(specialties[i].id) : null,
                          isUploadingPhoto: uploadingPhotoId == specialties[i].id,
                        ),
                      ),
                    ),
                  if (!expanded)
                    Positioned(
                      left: centerOffset + collapsedWidth - 34,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '$n',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
