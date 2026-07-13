import 'package:centrifuge/centrifuge.dart' as centrifuge;

// One shared Centrifugo connection for the app's lifetime; channels are subscribed per-screen.
class RealtimeService {
  RealtimeService({required this.wsUrl, required this.getToken});

  final String wsUrl;
  final Future<String> Function() getToken;
  centrifuge.Client? _client;

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
    final client = await _ensureConnected();
    final sub = client.newSubscription(channel);
    await sub.subscribe();
    return sub;
  }

  Future<void> unsubscribe(centrifuge.Subscription sub) async {
    await _client?.removeSubscription(sub);
  }
}
