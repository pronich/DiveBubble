import receive_sharing_intent

// shouldAutoRedirect defaults to true — no compose UI here, the extension just hands the
// shared content straight to DiveBubble (see ChooseBubblePage, which is the real "pick a
// destination" step, Telegram-style).
class ShareViewController: RSIShareViewController {
}
