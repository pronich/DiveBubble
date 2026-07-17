import { BubbleBackground } from "@/components/BubbleBackground";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { LegalSection } from "@/components/LegalSection";
import { COMPANY, LEGAL_EMAIL } from "@/lib/constants";

export default function TermsPage() {
  return (
    <>
      <BubbleBackground />
      <Header />
      <main className="relative flex-1">
        <section className="mx-auto max-w-4xl px-6 pt-16 pb-24">
          <span className="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-white/70">
            Legal
          </span>
          <h1 className="mt-6 font-serif text-5xl font-semibold">Terms &amp; Conditions</h1>
          <p className="mt-4 text-white/60">Last updated: January 2026</p>

          <div className="mt-10 space-y-8 rounded-2xl bg-white p-8 text-brand-blue sm:p-10">
            <LegalSection
              title="Agreement"
              paragraphs={[
                { text: "These Terms of Use (“Terms”) form a legal agreement between you and:" },
                {
                  items: [
                    `Legal name: ${COMPANY.legalName}`,
                    `CVR: ${COMPANY.cvr}`,
                    `Address: ${COMPANY.address}`,
                    `Email: ${LEGAL_EMAIL}`,
                  ],
                },
                { text: "By using DiveBubble (“the app”), you agree to these Terms." },
              ]}
            />

            <LegalSection
              title="Service description"
              paragraphs={[
                {
                  text: "DiveBubble helps divers discover local dive trips, coordinate with each other, and connect with dive centers. The app provides:",
                },
                {
                  items: [
                    "a marketplace of dive trips posted by individual divers and dive centers",
                    "per-trip group chat for coordinating logistics",
                    "a dedicated workspace for dive centers to publish trips and manage staff",
                  ],
                },
              ]}
            />

            <LegalSection
              title="Accounts"
              paragraphs={[
                { text: "You sign in with a Google account. You are responsible for maintaining access to your account and for all activity under it." },
              ]}
            />

            <LegalSection
              title="Using DiveBubble and safety"
              paragraphs={[
                {
                  text: "You must be old enough to hold a diving certification in your jurisdiction to join trips that require one. You are responsible for the accuracy of information you post, including certifications and experience.",
                },
                {
                  text: "DiveBubble is a coordination tool, not a certifying body. Diving carries inherent risk. You are responsible for diving within your training, checking conditions, and following the guidance of the trip organizer.",
                },
              ]}
            />

            <LegalSection
              title="Content"
              paragraphs={[
                { text: "You keep ownership of the content you post. You grant DiveBubble a limited license to display it within the app to the people you share it with." },
              ]}
            />

            <LegalSection
              title="Dive centers and trips"
              paragraphs={[
                {
                  text: "Dive centers using DiveBubble Business are responsible for their own trips, staff, pricing, refunds, and communications with divers. DiveBubble does not process payments or bookings — any transaction happens directly between you and the dive center, outside the app.",
                },
              ]}
            />

            <LegalSection
              title="Acceptable use"
              paragraphs={[
                { text: "You agree not to:" },
                {
                  items: [
                    "use DiveBubble for unlawful purposes",
                    "attempt to reverse engineer or disrupt the app",
                    "misuse the service or overload it",
                  ],
                },
              ]}
            />

            <LegalSection
              title="Availability"
              paragraphs={[
                { text: "DiveBubble is provided “as is”. We do not guarantee uninterrupted availability, error-free operation, or permanent access to any feature. Features may change or be removed at any time." },
              ]}
            />

            <LegalSection
              title="Limitation of liability"
              paragraphs={[
                { text: "To the extent permitted by law, we are not liable for data loss, disputes between divers and dive centers, or indirect or consequential damages." },
              ]}
            />

            <LegalSection
              title="Termination"
              paragraphs={[
                { text: "You can stop using DiveBubble at any time. We may suspend accounts that violate these Terms or put other divers at risk." },
              ]}
            />

            <LegalSection
              title="Changes"
              paragraphs={[{ text: "We may update these Terms. Continued use of DiveBubble means you accept the updated Terms." }]}
            />

            <LegalSection title="Governing law" paragraphs={[{ text: "These Terms are governed by Danish law." }]} />

            <div>
              <h2 className="font-serif text-xl font-semibold">Contact</h2>
              <p className="mt-2 text-sm text-brand-blue/70">
                Questions about these terms? Email{" "}
                <a href={`mailto:${LEGAL_EMAIL}`} className="underline underline-offset-2">
                  {LEGAL_EMAIL}
                </a>
                .
              </p>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
