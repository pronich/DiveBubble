// Single switch gating both the store badges and the /app_launch redirect — flip via the Vercel env var once Apple approves, so both platforms launch together rather than trickling out.
export const APP_LINKS_LIVE = process.env.APP_LINKS_LIVE === "true";

export const APP_STORE_URL = "https://apps.apple.com/app/id6792323983";
export const GOOGLE_PLAY_URL = "https://play.google.com/store/apps/details?id=io.divebubble.app";
export const APP_LAUNCH_URL = "https://divebubble.io/app_launch";
