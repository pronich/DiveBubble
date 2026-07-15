import 'package:centrifuge/centrifuge.dart' as centrifuge;

// One shared Centrifugo connection for the app's lifetime; channels are subscribed per-screen.
class RealtimeService {
  RealtimeService({required this.wsUrl, required this.getToken});

  final String wsUrl;
  final Future<String> Function() getToken;
  centrifuge.Client? _client;

  final Map<String, centrifuge.Subscription> _subscriptions = {};
  final Map<String, int> _refCounts = {};
  final Map<String, Future<centrifuge.Subscription>> _pendingSubscribes = {};

  Future<centrifuge.Client> _ensureConnected() async {
    final existing = _client;
    if (existing != null) return existing;

    final client = centrifuge.createClient(
      wsUrl,
      centrifuge.ClientConfig(getToken: (_) => getToken()),
    );
    await client.connect();
    _client = client;
    return client;
  }

  // Multiple screens can now want the same trip channel at once (e.g. the Bubbles list
  // and an open chat both watching trip:$id) — centrifuge's client throws if you try to
  // create a second Subscription for a channel it already has one for, so callers share
  // one Subscription per channel here, ref-counted. PublicationEvent's stream is broadcast
  // internally, so every caller can safely .listen() on the same shared Subscription.
  Future<centrifuge.Subscription> subscribe(String channel) async {
    final existing = _subscriptions[channel];
    if (existing != null) {
      _refCounts[channel] = (_refCounts[channel] ?? 1) + 1;
      return existing;
    }

    // Two overlapping callers for the same not-yet-subscribed channel (e.g. MyTripsViewModel
    // getting load() called twice back to back — initState plus an auth-change listener
    // firing right after) would otherwise both race past the check above and each call
    // client.newSubscription() themselves, which centrifuge rejects the second time with
    // "Subscription to a channel already exists". Everything above is synchronous (no
    // await before this point), so by the time a second caller actually runs, the first
    // caller has already recorded its in-flight future here for the second to await instead.
    final pending = _pendingSubscribes[channel];
    if (pending != null) {
      final sub = await pending;
      _refCounts[channel] = (_refCounts[channel] ?? 1) + 1;
      return sub;
    }

    final future = _createSubscription(channel);
    _pendingSubscribes[channel] = future;
    try {
      final sub = await future;
      _subscriptions[channel] = sub;
      _refCounts[channel] = 1;
      return sub;
    } finally {
      _pendingSubscribes.remove(channel);
    }
  }

  Future<centrifuge.Subscription> _createSubscription(String channel) async {
    final client = await _ensureConnected();
    final sub = client.newSubscription(channel);
    await sub.subscribe();
    return sub;
  }

  Future<void> unsubscribe(centrifuge.Subscription sub) async {
    final channel = sub.channel;
    final remaining = (_refCounts[channel] ?? 1) - 1;
    if (remaining > 0) {
      _refCounts[channel] = remaining;
      return;
    }

    _refCounts.remove(channel);
    _subscriptions.remove(channel);
    await _client?.removeSubscription(sub);
  }
}
