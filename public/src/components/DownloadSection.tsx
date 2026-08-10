import { AppQrCode } from "@/components/AppQrCode";
import { StoreBadge } from "@/components/StoreBadge";
import { APP_LINKS_LIVE, APP_STORE_URL, GOOGLE_PLAY_URL } from "@/config/appLaunch";

export function DownloadSection() {
  return (
    <div>
      {/* Desktop/tablet: a QR code reads better than store badges when you can't tap them
          straight from your phone anyway. Always points at /app_launch — see
          src/config/appLaunch.ts for how that page behaves before/after launch. */}
      <div className="hidden items-center gap-4 md:flex">
        <div className="rounded-2xl bg-white p-3">
          <AppQrCode size={96} />
        </div>
        <p className="max-w-[14rem] text-sm text-white/70">Scan with your phone to get DiveBubble.</p>
      </div>

      {/* Mobile browser: badges are the useful affordance here, a QR code pointing at the
          same page you're already on isn't. */}
      <div className="flex items-center gap-3 md:hidden">
        <StoreBadge
          href={APP_STORE_URL}
          live={APP_LINKS_LIVE}
          src="/images/app-store-badge.svg"
          alt="Download on the App Store"
          width={120}
          height={40}
        />
        <StoreBadge
          href={GOOGLE_PLAY_URL}
          live={APP_LINKS_LIVE}
          src="/images/google-play-badge.svg"
          alt="Get it on Google Play"
          width={135}
          height={40}
          tag="Beta"
        />
      </div>
    </div>
  );
}
