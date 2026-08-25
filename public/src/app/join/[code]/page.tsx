import Image from "next/image";
import type { Metadata } from "next";
import { BubbleBackground } from "@/components/BubbleBackground";
import { AppQrCode } from "@/components/AppQrCode";
import { StoreBadge } from "@/components/StoreBadge";
import { APP_LINKS_LIVE, APP_STORE_URL, GOOGLE_PLAY_URL } from "@/config/appLaunch";

export const metadata: Metadata = {
  title: "Trip Invite",
};

// Reached via a trip's own "Copy invite link" (see app/'s TripPage _BookingCodeRow) — the
// code itself is what actually gets you in (trip.Service.JoinByCode), this page is just a
// friendlier landing spot than handing someone a bare code over text. No trip lookup here —
// deliberately static, no backend call — the code is unambiguous enough to read off a screen
// and type by hand (see backend's bookingCodeAlphabet comment), so that's the fallback for
// anyone who lands here without the app installed yet.
export default async function JoinPage({ params }: { params: Promise<{ code: string }> }) {
  const { code } = await params;

  return (
    <>
      <BubbleBackground />
      <main className="relative flex flex-1 items-center justify-center px-6 py-20">
        <div className="flex w-full max-w-sm flex-col items-center text-center">
          <Image src="/images/logo.png" alt="" width={72} height={72} className="rounded-2xl shadow-lg" />
          <h1 className="mt-6 font-serif text-3xl font-semibold">You&apos;re invited</h1>
          <p className="mt-3 text-white/75">
            Open DiveBubble, tap &ldquo;Join by code&rdquo;, and enter:
          </p>

          <p className="mt-6 rounded-2xl bg-white/10 px-6 py-3 font-mono text-2xl font-semibold tracking-[0.3em]">
            {code.toUpperCase()}
          </p>

          <div className="mt-10 hidden flex-col items-center gap-3 md:flex">
            <div className="rounded-2xl bg-white p-3">
              <AppQrCode size={140} />
            </div>
            <p className="text-sm text-white/60">Don&apos;t have the app yet? Scan to get it</p>
          </div>

          <div className="mt-10 flex items-center justify-center gap-3 md:hidden">
            <StoreBadge
              href={APP_STORE_URL}
              live={APP_LINKS_LIVE}
              src="/images/app-store-badge.svg"
              alt="Download on the App Store"
              width={150}
              height={50}
            />
            <StoreBadge
              href={GOOGLE_PLAY_URL}
              live={APP_LINKS_LIVE}
              src="/images/google-play-badge.svg"
              alt="Get it on Google Play"
              width={169}
              height={50}
              tag="Beta"
            />
          </div>
        </div>
      </main>
    </>
  );
}
