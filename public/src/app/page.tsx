import Link from "next/link";
import { BubbleBackground } from "@/components/BubbleBackground";
import { DownloadSection } from "@/components/DownloadSection";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";

const FEATURES = [
  {
    title: "Discover",
    body: "Weekend shore dives, cold-water wrecks, and reef trips near you.",
  },
  {
    title: "Coordinate",
    body: "Share rides, gear, and the plan — right in the trip chat.",
  },
  {
    title: "Meet buddies",
    body: "See who's diving, their certs, and their experience before you go.",
  },
];

export default function IndividualsPage() {
  return (
    <>
      <BubbleBackground />
      <Header />
      <main className="relative flex-1">
        <section className="mx-auto max-w-6xl px-6 pt-16 pb-20">
          <div className="grid gap-12 lg:grid-cols-2 lg:items-center">
            <div>
              <span className="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-white/70">
                For divers
              </span>
              <h1 className="mt-6 font-serif text-5xl font-semibold leading-tight sm:text-6xl">
                Every dive is better with a buddy.
              </h1>
              <p className="mt-6 max-w-md text-white/75">
                DiveBubble is the simplest way to discover local dive trips, meet the group, and coordinate
                everything from rides to surface intervals — all in one calm little app.
              </p>
              <div className="mt-8">
                <DownloadSection />
              </div>
            </div>

            <div className="rounded-2xl bg-white p-6 text-brand-blue shadow-xl">
              <span className="text-xs font-semibold uppercase tracking-wide text-brand-blue/60">This weekend</span>
              <h2 className="mt-2 font-serif text-2xl font-semibold">Kelp Forest · Monterey</h2>
              <p className="mt-1 text-sm text-brand-blue/70">Sat 8:00 · 4 divers going</p>
              <div className="mt-4 flex gap-2">
                {["A", "M", "J", "S"].map((letter) => (
                  <div
                    key={letter}
                    className="flex h-9 w-9 items-center justify-center rounded-full bg-brand-blue/10 text-sm font-semibold"
                  >
                    {letter}
                  </div>
                ))}
              </div>
              <div className="mt-4 rounded-xl bg-brand-blue/5 px-4 py-3 text-sm">
                <span className="font-semibold">Alex</span> offered 2 seats from Frederiksberg.
              </div>
              <button
                type="button"
                disabled
                className="mt-4 w-full rounded-full bg-brand-blue py-3 text-sm font-semibold text-white opacity-60"
              >
                Join dive
              </button>
            </div>
          </div>

          <div className="mt-16 grid gap-4 sm:grid-cols-3">
            {FEATURES.map((f) => (
              <div key={f.title} className="rounded-2xl bg-white/10 p-6">
                <h3 className="font-serif text-lg font-semibold">{f.title}</h3>
                <p className="mt-2 text-sm text-white/70">{f.body}</p>
              </div>
            ))}
          </div>

          <div className="mt-6 flex flex-col items-start justify-between gap-4 rounded-2xl bg-white p-6 text-brand-blue sm:flex-row sm:items-center">
            <div>
              <h3 className="font-serif text-xl font-semibold">Running a dive center?</h3>
              <p className="mt-1 text-sm text-brand-blue/70">DiveBubble has a dedicated workspace for organizations.</p>
            </div>
            <Link
              href="/business"
              className="rounded-full bg-brand-blue px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-navy"
            >
              Explore Business
            </Link>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
