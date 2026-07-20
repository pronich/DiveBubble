import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dive_center_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/transport_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/services/realtime_service.dart';
import '../../domain/entities/dive_center.dart';
import '../features/auth/views/login_page.dart';
import '../features/onboarding/views/onboarding_page.dart';
import '../features/onboarding/views/personal_info_page.dart';
import 'navigation/admin_shell.dart';

enum _GateState { loading, loggedOut, needsPersonalInfo, needsOnboarding, ready }

/// The whole app's routing decision, in one place: signed out -> Login; signed in with zero
/// dive-center memberships -> Onboarding (create one); signed in with at least one -> the
/// dashboard. A brand-new Google identity (isNewUser, only known right after a fresh
/// completeSignIn — never on a cold-start recheck of an existing session) additionally
/// gets a personal-info step *before* Onboarding, since they have no personal profile at
/// all yet; an existing account signing into admin/ for the first time (already has a
/// profile from app/, or was added as staff via email) skips straight to Onboarding, per
/// explicit product decision — this is the one thing that *is* about account age, layered
/// on top of the dive-center-membership check described above (see CLAUDE.md's Business/
/// dive centers section for that original, still-unchanged rule).
class RootGate extends StatefulWidget {
  const RootGate({
    super.key,
    required this.authRepository,
    required this.diveCenterRepository,
    required this.tripRepository,
    required this.profileRepository,
    required this.messageRepository,
    required this.transportRepository,
    required this.realtimeService,
  });

  final AuthRepository authRepository;
  final DiveCenterRepository diveCenterRepository;
  final TripRepository tripRepository;
  final ProfileRepository profileRepository;
  final MessageRepository messageRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  _GateState _state = _GateState.loading;
  List<DiveCenter> _diveCenters = [];

  @override
  void initState() {
    super.initState();
    _recheck();
  }

  /// [isNewUser] only ever arrives true right after LoginPage's own completeSignIn call —
  /// every other caller (initState's cold start, sign-out recovery) omits it, since those
  /// are rechecks of a session that (if valid) already existed before this call.
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
        _state = diveCenters.isNotEmpty
            ? _GateState.ready
            : (isNewUser ? _GateState.needsPersonalInfo : _GateState.needsOnboarding);
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
          onDone: () => setState(() => _state = _GateState.needsOnboarding),
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
          messageRepository: widget.messageRepository,
          transportRepository: widget.transportRepository,
          realtimeService: widget.realtimeService,
          authRepository: widget.authRepository,
          onSignedOut: _recheck,
        );
    }
  }
}
