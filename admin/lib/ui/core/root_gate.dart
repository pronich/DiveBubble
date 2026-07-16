import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dive_center_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/entities/dive_center.dart';
import '../features/auth/views/login_page.dart';
import '../features/dashboard/views/dashboard_page.dart';
import '../features/onboarding/views/onboarding_page.dart';

enum _GateState { loading, loggedOut, needsOnboarding, ready }

/// The whole app's routing decision, in one place: signed out -> Login; signed in with zero
/// dive-center memberships -> Onboarding (create one); signed in with at least one -> the
/// dashboard. Unlike app/'s isNewUser check, this gate isn't about account age — an
/// existing individual diver who's never had a business hits Onboarding exactly the same
/// way a brand-new account would (see CLAUDE.md's Business/dive centers section).
class RootGate extends StatefulWidget {
  const RootGate({
    super.key,
    required this.authRepository,
    required this.diveCenterRepository,
    required this.tripRepository,
  });

  final AuthRepository authRepository;
  final DiveCenterRepository diveCenterRepository;
  final TripRepository tripRepository;

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

  Future<void> _recheck() async {
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
        _state = diveCenters.isEmpty ? _GateState.needsOnboarding : _GateState.ready;
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
      case _GateState.needsOnboarding:
        return OnboardingPage(
          diveCenterRepository: widget.diveCenterRepository,
          onCreated: (dc) => setState(() {
            _diveCenters = [dc];
            _state = _GateState.ready;
          }),
        );
      case _GateState.ready:
        return DashboardPage(
          diveCenter: _diveCenters.first,
          diveCenterRepository: widget.diveCenterRepository,
          tripRepository: widget.tripRepository,
          authRepository: widget.authRepository,
          onSignedOut: _recheck,
        );
    }
  }
}
