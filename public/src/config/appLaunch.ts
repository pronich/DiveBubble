// Single switch for the whole app-store launch: while off, store badges render
// inert (no href) and the /app_launch User-Agent redirects in next.config.ts stay
// off, so every visitor lands on the QR/badges page regardless of device. Flip via
// the APP_LINKS_LIVE env var (Vercel: Settings -> Environment Variables, then
// redeploy — no code change needed) once Apple approves the App Store listing.
// Android already cleared Open Testing, but both platforms launch together rather
// than trickling Android out early. Server-only on purpose (no NEXT_PUBLIC_
// prefix): it's read in next.config.ts and server components, never in the
// browser, and this keeps it out of the client bundle. Unset/anything but
// "true" defaults to off, so preview deploys stay dormant unless set explicitly.
export const APP_LINKS_LIVE = process.env.APP_LINKS_LIVE === "true";

export const APP_STORE_URL = "https://apps.apple.com/app/id6792323983";
export const GOOGLE_PLAY_URL = "https://play.google.com/store/apps/details?id=io.divebubble.app";
export const APP_LAUNCH_URL = "https://divebubble.io/app_launch";
