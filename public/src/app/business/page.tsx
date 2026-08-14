import Link from "next/link";
import { BubbleBackground } from "@/components/BubbleBackground";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { ADMIN_URL } from "@/lib/constants";

const ACTIVE_TRIPS = [
  { title: "Kelp Forest · Sat", subtitle: "12 divers" },
  { title: "Wreck Dive · Sun", subtitle: "8 divers" },
  { title: "Night Reef · Fri", subtitle: "6 divers" },
];

const FEATURES = [
  {
    title: "Publish trips in seconds",
    body: "Create, schedule, and update dives. Divers see them the moment you publish.",
  },
  {
    title: "One chat per trip",
    body: "Talk to the whole roster in a single thread. No more scattered WhatsApp groups.",
  },
  {
    title: "Manage your team",
    body: "Invite instructors and staff, assign roles, and keep everyone on the same schedule.",
  },
  {
    title: "Company profile",
    body: "A polished page for your center — logo, story, and every upcoming trip.",
  },
  {
    title: "Reach more divers",
    body: "Your trips show up in the same place divers already browse for their next dive — not just people who already know you.",
  },
  {
    title: "Built for the water",
    body: "Same calm design as the diver app. Nothing to learn — just log in and go.",
  },
];

export default function BusinessPage() {
  return (
    <>
      <BubbleBackground />
      <Header showDiveIn />
      <main className="relative flex-1">
        <section className="mx-auto max-w-6xl px-6 pt-16 pb-20">
          <div className="grid gap-12 lg:grid-cols-2 lg:items-center">
            <div>
              <span className="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-white/70">
                For dive centers
              </span>
              <h1 className="mt-6 font-serif text-5xl font-semibold leading-tight sm:text-6xl">
                Run every trip from one calm place.
              </h1>
              <p className="mt-6 max-w-md text-white/75">
                DiveBubble Business gives your center a dedicated workspace to publish trips, chat with each
                roster, manage your team, and get discovered by divers browsing DiveBubble.
              </p>
              <div className="mt-8 flex flex-wrap items-center gap-3">
                <a
                  href={ADMIN_URL}
                  className="rounded-full bg-white px-6 py-3 text-sm font-semibold text-brand-blue hover:bg-white/90"
                >
                  Dive in
                </a>
                <Link
                  href="/faq"
                  className="rounded-full border border-white/30 px-6 py-3 text-sm font-semibold text-white hover:bg-white/10"
                >
                  Questions?
                </Link>
              </div>
              <p className="mt-4 text-sm text-white/60">Set up in under 5 minutes</p>
            </div>

            <div className="rounded-2xl bg-white p-6 text-brand-blue shadow-xl">
              <span className="text-xs font-semibold uppercase tracking-wide text-brand-blue/60">Active trips</span>
              <div className="mt-3 space-y-2">
                {ACTIVE_TRIPS.map((trip) => (
                  <div key={trip.title} className="flex items-center justify-between rounded-xl bg-brand-blue/5 px-4 py-3">
                    <div>
                      <p className="text-sm font-semibold">{trip.title}</p>
                      <p className="text-xs text-brand-blue/60">{trip.subtitle}</p>
                    </div>
                    <span className="rounded-full bg-brand-blue/10 px-3 py-1 text-xs font-semibold">Live</span>
                  </div>
                ))}
              </div>
              <div className="mt-3 rounded-xl border border-brand-blue/10 px-4 py-3">
                <span className="text-xs font-semibold uppercase tracking-wide text-brand-blue/50">Unread messages</span>
                <p className="mt-1 font-serif text-xl font-semibold">3 trips</p>
              </div>
            </div>
          </div>

          <h2 className="mt-20 font-serif text-3xl font-semibold">What you get</h2>
          <div className="mt-6 grid gap-4 sm:grid-cols-3">
            {FEATURES.map((f) => (
              <div key={f.title} className="rounded-2xl bg-white/10 p-6">
                <h3 className="font-serif text-lg font-semibold">{f.title}</h3>
                <p className="mt-2 text-sm text-white/70">{f.body}</p>
              </div>
            ))}
          </div>

          <div className="mt-6 flex flex-col items-start justify-between gap-4 rounded-2xl bg-white p-6 text-brand-blue sm:flex-row sm:items-center">
            <div>
              <h3 className="font-serif text-xl font-semibold">Ready to get your center on DiveBubble?</h3>
              <p className="mt-1 text-sm text-brand-blue/70">Open the workspace and start with your first trip.</p>
            </div>
            <a
              href={ADMIN_URL}
              className="rounded-full bg-brand-blue px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-navy"
            >
              Dive in
            </a>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
