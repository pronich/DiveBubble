import Image from "next/image";
import { StoreBadge } from "@/components/StoreBadge";
import { APP_LINKS_LIVE, APP_STORE_URL, GOOGLE_PLAY_URL } from "@/config/appLaunch";

export function DownloadSection() {
  return (
    <div>
      {/* Desktop/tablet: the Figma-designed download card (QR + copy + badges, all
          baked in) — a QR code reads better than tappable badges here anyway. */}
      <div className="hidden md:block">
        <Image
          src="/images/download-card.svg"
          alt="Scan to download DiveBubble, or get it on the App Store or Google Play"
          width={7138}
          height={3138}
          className="h-auto w-full max-w-md"
        />
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
