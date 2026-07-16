import 'package:centrifuge/centrifuge.dart' as centrifuge;

// One shared Centrifugo connection for admin/'s lifetime; channels are subscribed per-Bubble.
// Same shape as app/'s RealtimeService (see CLAUDE.md: admin/ and app/ don't share code
// yet) — ref-counted shared Subscription per channel, in-flight-Future de-duplication for
// overlapping subscribe() calls.
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

  Future<centrifuge.Subscription> subscribe(String channel) async {
    final existing = _subscriptions[channel];
    if (existing != null) {
      _refCounts[channel] = (_refCounts[channel] ?? 1) + 1;
      return existing;
    }

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
