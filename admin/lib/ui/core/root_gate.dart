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

/// The whole app's routing decision, in one place: signed out -> Login; a brand-new account
/// (isNewUser — from a fresh Google completeSignIn, or a just-consumed magic link, see
/// [initialIsNewUser]) always gets a personal-info step first, since they have no personal
/// profile at all yet — this used to be gated on *also* having zero dive-center memberships,
/// which silently skipped it for a brand-new account that was auto-joined to a dive center
/// via a staff invitation (see divecenter.Service.AcceptInvitations) before ever reaching
/// this check. After that step (or immediately, for a returning account): zero dive-center
/// memberships -> Onboarding (create one); at least one -> the dashboard.
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

  // Only ever true right after MagicLinkGate just consumed a fresh magic-link sign-in that
  // turned out to be a brand-new account — a cold start with an existing session has no such
  // signal available, so it always constructs this false (matching _recheck's own default).
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

  /// [isNewUser] only ever arrives true right after LoginPage's own completeSignIn call, or
  /// RootGate's own initState relaying MagicLinkGate's result — every other caller
  /// (sign-out recovery) omits it, since those are rechecks of a session that (if valid)
  /// already existed before this call.
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
          // Invited staff already have a dive-center membership (auto-joined on sign-in,
          // see AcceptInvitations) by the time this loaded — they skip straight to the
          // dashboard instead of Onboarding's "create a dive center" flow, which isn't
          // meant for them.
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
