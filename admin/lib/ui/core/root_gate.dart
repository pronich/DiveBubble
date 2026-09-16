import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dive_center_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/specialty_repository.dart';
import '../../data/repositories/transport_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/services/realtime_service.dart';
import '../../domain/entities/dive_center.dart';
import '../features/auth/views/login_page.dart';
import '../features/onboarding/views/onboarding_page.dart';
import '../features/onboarding/views/personal_info_page.dart';
import 'navigation/admin_shell.dart';

enum _GateState { loading, loggedOut, needsPersonalInfo, needsOnboarding, ready }

/// isNewUser always routes through a personal-info step first, regardless of dive-center memberships — gating it on zero memberships too used to silently skip that step for a staff invitee auto-joined to a dive center before ever reaching this check.
class RootGate extends StatefulWidget {
  const RootGate({
    super.key,
    required this.authRepository,
    required this.diveCenterRepository,
    required this.tripRepository,
    required this.profileRepository,
    required this.specialtyRepository,
    required this.messageRepository,
    required this.transportRepository,
    required this.realtimeService,
    this.initialIsNewUser = false,
  });

  final AuthRepository authRepository;
  final DiveCenterRepository diveCenterRepository;
  final TripRepository tripRepository;
  final ProfileRepository profileRepository;
  final SpecialtyRepository specialtyRepository;
  final MessageRepository messageRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;

  // Only ever true right after MagicLinkGate consumed a fresh magic-link sign-in that turned out to be a brand-new account.
  final bool initialIsNewUser;

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  _GateState _state = _GateState.loading;
  List<DiveCenter> _diveCenters = [];

  @override
  void initState() {
    super.initState();
    _recheck(widget.initialIsNewUser);
  }

  /// [isNewUser] only ever arrives true right after a fresh sign-in (Google or magic link) — every other caller omits it since it's rechecking a session that already existed.
  Future<void> _recheck([bool isNewUser = false]) async {
    final userId = await widget.authRepository.currentUserId();
    if (userId == null) {
      if (mounted) setState(() => _state = _GateState.loggedOut);
      return;
    }
    try {
      final diveCenters = await widget.diveCenterRepository.getMine();
      if (!mounted) return;
      setState(() {
        _diveCenters = diveCenters;
        _state = isNewUser
            ? _GateState.needsPersonalInfo
            : (diveCenters.isNotEmpty ? _GateState.ready : _GateState.needsOnboarding);
      });
    } catch (_) {
      // Best-effort — an expired/invalid session reads as logged-out, prompting a fresh login.
      if (mounted) setState(() => _state = _GateState.loggedOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _GateState.loggedOut:
        return LoginPage(authRepository: widget.authRepository, onSignedIn: _recheck);
      case _GateState.needsPersonalInfo:
        return PersonalInfoPage(
          profileRepository: widget.profileRepository,
          // Invited staff already have a dive-center membership (auto-joined on sign-in) by now, so they skip straight to the dashboard instead of Onboarding's "create a dive center" flow.
          onDone: () => setState(() => _state = _diveCenters.isNotEmpty ? _GateState.ready : _GateState.needsOnboarding),
        );
      case _GateState.needsOnboarding:
        return OnboardingPage(
          diveCenterRepository: widget.diveCenterRepository,
          onCreated: (dc) => setState(() {
            _diveCenters = [dc];
            _state = _GateState.ready;
          }),
        );
      case _GateState.ready:
        return AdminShell(
          diveCenter: _diveCenters.first,
          diveCenterRepository: widget.diveCenterRepository,
          tripRepository: widget.tripRepository,
          profileRepository: widget.profileRepository,
          specialtyRepository: widget.specialtyRepository,
          messageRepository: widget.messageRepository,
          transportRepository: widget.transportRepository,
          realtimeService: widget.realtimeService,
          authRepository: widget.authRepository,
          onSignedOut: _recheck,
        );
    }
  }
}
