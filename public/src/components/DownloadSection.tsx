import Image from "next/image";
import { QRCodeSVG } from "qrcode.react";

// Neither store listing exists yet — both the QR target and the badges are non-functional
// "Soon" stubs (see CLAUDE.md: Apple Sign-In/App Store submission are both still blocked on
// external setup). The QR encodes the site itself for now so scanning it isn't a dead end,
// and gets swapped for the real store link once one exists.
const PLACEHOLDER_TARGET = "https://divebubble.io";

function SoonTag() {
  return (
    <span className="absolute -right-2 -top-2 rounded-full bg-white px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-brand-blue shadow">
      Soon
    </span>
  );
}

export function DownloadSection() {
  return (
    <div>
      {/* Desktop/tablet: a QR code reads better than store badges when you can't tap them
          straight from your phone anyway. */}
      <div className="hidden items-center gap-4 md:flex">
        <div className="relative rounded-2xl bg-white p-3">
          <QRCodeSVG value={PLACEHOLDER_TARGET} size={96} />
          <SoonTag />
        </div>
        <p className="max-w-[14rem] text-sm text-white/70">Scan with your phone to get DiveBubble once it&apos;s live.</p>
      </div>

      {/* Mobile browser: badges are the useful affordance here, a QR code pointing at the
          same page you're already on isn't. */}
      <div className="flex items-center gap-3 md:hidden">
        <div className="relative">
          <Image src="/images/app-store-badge.svg" alt="Download on the App Store" width={120} height={40} />
          <SoonTag />
        </div>
        <div className="relative">
          <Image src="/images/google-play-badge.svg" alt="Get it on Google Play" width={135} height={40} />
          <SoonTag />
        </div>
      </div>
    </div>
  );
}
