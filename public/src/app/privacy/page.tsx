import { BubbleBackground } from "@/components/BubbleBackground";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { LegalSection } from "@/components/LegalSection";
import { COMPANY, PRIVACY_EMAIL } from "@/lib/constants";

export default function PrivacyPage() {
  return (
    <>
      <BubbleBackground />
      <Header />
      <main className="relative flex-1">
        <section className="mx-auto max-w-4xl px-6 pt-16 pb-24">
          <span className="rounded-full bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-white/70">
            Legal
          </span>
          <h1 className="mt-6 font-serif text-5xl font-semibold">Privacy Policy</h1>
          <p className="mt-4 text-white/60">Last updated: January 2026</p>

          <div className="mt-10 space-y-8 rounded-2xl bg-white p-8 text-brand-blue sm:p-10">
            <LegalSection
              title="Overview"
              paragraphs={[
                { text: "DiveBubble (“the app”) is developed by:" },
                {
                  items: [
                    `Legal name: ${COMPANY.legalName}`,
                    `CVR: ${COMPANY.cvr}`,
                    `Address: ${COMPANY.address}`,
                    `Email: ${PRIVACY_EMAIL}`,
                  ],
                },
                { text: "This Privacy Policy explains how we handle your data in the DiveBubble mobile app and the DiveBubble Business web workspace." },
              ]}
            />

            <LegalSection
              title="Data we collect"
              paragraphs={[
                { text: "Account data — collected when you sign in with Google:" },
                { items: ["your name, email, and profile photo", "self-reported certifications, languages, and gear you add to your profile"] },
                { text: "Content you create:" },
                { items: ["trips you post or join, and trip details (location, dates, description)", "chat messages sent within a trip", "transport offers and gear/certification entries you add"] },
                { text: "Usage and device data — basic technical information (e.g. app version, device type) needed to run the service." },
              ]}
            />

            <LegalSection
              title="How we use data"
              paragraphs={[
                { text: "We use your data to:" },
                {
                  items: [
                    "show you relevant dive trips",
                    "deliver chat messages and notifications within a trip",
                    "let dive centers coordinate trips and staff",
                    "operate, secure, and maintain the service",
                  ],
                },
                { text: "We do not use your data for advertising or tracking across other apps." },
              ]}
            />

            <LegalSection
              title="Sharing"
              paragraphs={[
                { text: "Other participants on a trip can see information you share on it — your name, avatar, and certifications. A dive center you join a trip with can see your roster details for that trip. We do not sell your personal data to third parties." },
              ]}
            />

            <LegalSection
              title="Data storage"
              paragraphs={[
                { text: "Your data is stored on managed cloud infrastructure. We apply standard access controls and encrypt data in transit." },
              ]}
            />

            <LegalSection
              title="Third-party services"
              paragraphs={[
                { text: "We use Google Sign-In to authenticate accounts. Realtime chat delivery runs on infrastructure we operate ourselves, not a third party. These services process data only as needed to deliver the app's functionality." },
              ]}
            />

            <LegalSection
              title="Your rights"
              paragraphs={[
                { text: "If you are located in the EU, you have the right to access your data, request deletion, and restrict processing. You can update your profile, leave trips, or request account deletion at any time from the app, or by emailing us below." },
              ]}
            />

            <LegalSection
              title="Security"
              paragraphs={[{ text: "We take reasonable measures to protect your data, but no system is completely secure." }]}
            />

            <LegalSection
              title="Changes"
              paragraphs={[{ text: "We may update this Privacy Policy. Continued use of DiveBubble means you accept the updated version." }]}
            />

            <div>
              <h2 className="font-serif text-xl font-semibold">Contact</h2>
              <p className="mt-2 text-sm text-brand-blue/70">
                Questions about this policy or your data? Email{" "}
                <a href={`mailto:${PRIVACY_EMAIL}`} className="underline underline-offset-2">
                  {PRIVACY_EMAIL}
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
