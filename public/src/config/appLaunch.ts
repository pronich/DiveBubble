// Single switch for the whole app-store launch: while false, store badges render
// inert (no href) and the /app_launch User-Agent redirects in next.config.ts stay
// off, so every visitor lands on the QR/badges page regardless of device. Flip to
// true once Apple approves the App Store listing — Android already cleared Open
// Testing, but both platforms launch together rather than trickling Android out
// early.
export const APP_LINKS_LIVE = false;

export const APP_STORE_URL = "https://apps.apple.com/app/id6792323983";
export const GOOGLE_PLAY_URL = "https://play.google.com/store/apps/details?id=io.divebubble.app";
export const APP_LAUNCH_URL = "https://divebubble.io/app_launch";
