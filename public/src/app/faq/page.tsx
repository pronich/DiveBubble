import { BubbleBackground } from "@/components/BubbleBackground";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { SUPPORT_EMAIL } from "@/lib/constants";

const FAQ_ITEMS = [
  {
    q: "What is DiveBubble?",
    a: "DiveBubble is a mobile app for divers to discover trips, meet buddies, and coordinate everything in one place — plus a web workspace for dive centers to run their trips.",
  },
  {
    q: "Is DiveBubble free?",
    a: "Yes — DiveBubble is free for divers, and free for dive centers during beta. We're not charging anything, and we don't process any payments on the app.",
  },
  {
    q: "Which certifications do I need?",
    a: "It depends on the trip. Organizers can set a minimum certification level, and many casual local dives don't require one at all. You're responsible for diving within your own training.",
  },
  {
    q: "How do trips work?",
    a: "Anyone can post a trip — a local diver organizing a weekend dive, or a dive center publishing their schedule. Joining a trip opens its group chat, where you coordinate timing, meeting point, and transport.",
  },
  {
    q: "Do you support cold-water diving?",
    a: "Yes. DiveBubble isn't tied to any one region or water temperature — trips range from tropical reef dives to cold-water wrecks.",
  },
  {
    q: "How do dive centers get started?",
    a: "Dive centers get their own dedicated workspace, DiveBubble Business, to publish trips and manage staff. Sign-up isn't open yet — leave your email on the Business page and we'll let you know when it is.",
  },
  {
    q: "Where is my data stored, and is it GDPR-compliant?",
    a: `Yes. We're a Danish company, and DiveBubble is built and operated to comply with the GDPR. Your data is stored on managed cloud infrastructure with encryption in transit, and we never sell it or use it for advertising. See our Privacy Policy for the full details, including your rights.`,
  },
  {
    q: "How do I delete my account or exercise my privacy rights?",
    a: `You can delete your account and most of your data directly from the app. For anything else — access, correction, or questions about your data — email ${SUPPORT_EMAIL} and we'll respond within a month.`,
  },
  {
    q: "How can I contact support?",
    a: `Email us at ${SUPPORT_EMAIL} and we'll get back to you.`,
  },
];

export default function FaqPage() {
  return (
    <>
      <BubbleBackground />
      <Header />
      <main className="relative flex-1">
        <section className="mx-auto max-w-4xl px-6 pt-16 pb-24">
          <span className="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-white/70">
            Help
          </span>
          <h1 className="mt-6 font-serif text-5xl font-semibold">Questions, answered.</h1>
          <p className="mt-4 max-w-xl text-white/75">
            Everything you might want to know about DiveBubble. Still stuck? Reach us at{" "}
            <a href={`mailto:${SUPPORT_EMAIL}`} className="underline underline-offset-2 hover:text-white">
              {SUPPORT_EMAIL}
            </a>
            .
          </p>

          <div className="mt-10 overflow-hidden rounded-2xl bg-white text-brand-blue">
            {FAQ_ITEMS.map((item, i) => (
              <details
                key={item.q}
                className={`group px-6 py-5 ${i > 0 ? "border-t border-brand-blue/10" : ""}`}
                open={i === 0}
              >
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-serif text-lg font-semibold">
                  {item.q}
                  <span className="flex h-6 w-6 flex-none items-center justify-center rounded-full bg-brand-blue/10 text-sm group-open:rotate-45">
                    +
                  </span>
                </summary>
                <p className="mt-3 text-sm text-brand-blue/70">{item.a}</p>
              </details>
            ))}
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
