import { BubbleBackground } from "@/components/BubbleBackground";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { LegalSection } from "@/components/LegalSection";
import { COMPANY, SUPPORT_EMAIL } from "@/lib/constants";

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
          <p className="mt-4 text-white/60">Effective date: 19 July 2026</p>
          <p className="text-white/60">Last updated: 19 July 2026</p>

          <div className="mt-10 space-y-8 rounded-2xl bg-white p-8 text-brand-blue sm:p-10">
            <LegalSection
              title="1. Who we are"
              paragraphs={[
                { text: "DiveBubble (“DiveBubble”, “we”, “us”) is operated by:" },
                {
                  items: [
                    `Legal name: ${COMPANY.legalName}, ${COMPANY.legalForm}`,
                    `CVR: ${COMPANY.cvr}`,
                    `Address: ${COMPANY.address}`,
                    `Email: ${SUPPORT_EMAIL}`,
                    `Website: ${COMPANY.website}`,
                  ],
                },
                {
                  text: `${COMPANY.legalName} is the data controller for the personal data described in this Privacy Policy under the EU General Data Protection Regulation (“GDPR”).`,
                },
                {
                  text: "This policy applies to the DiveBubble mobile and web app, the DiveBubble Business workspace, and related pages on divebubble.io.",
                },
              ]}
            />

            <LegalSection
              title="2. Data we collect"
              paragraphs={[
                { text: "Account data" },
                { text: "When you create an account using Google or Apple, we may receive:" },
                {
                  items: [
                    "an authentication identifier",
                    "your name",
                    "your email address and its verification status",
                    "your profile photo, where provided by the authentication provider",
                  ],
                },
                {
                  text: "We also maintain authentication sessions needed to keep you signed in and protect your account.",
                },
                { text: "Profile data" },
                { text: "You may add information to your DiveBubble profile, including:" },
                {
                  items: [
                    "a profile photo",
                    "a bio",
                    "your city",
                    "languages",
                    "diving certifications and certification numbers",
                    "diving experience and number of dives",
                    "equipment you own or rent",
                  ],
                },
                {
                  text: "Most profile information is private to you. People who participate in the same Bubble as you, including relevant dive center staff, may see your name, profile photo, certification level, number of dives, bio, languages, and the year you joined DiveBubble. Certification numbers are visible only to you unless you choose to disclose them separately.",
                },
                { text: "Location" },
                {
                  text: "With your permission, DiveBubble may use your device's location to determine your city and show relevant trips. Precise location is not stored by DiveBubble for this purpose. You may enter or change your city manually, and DiveBubble does not access your location in the background.",
                },
                { text: "Trips and Bubbles" },
                { text: "When you create or participate in a trip, we process information such as:" },
                {
                  items: [
                    "trip name, location and description",
                    "dates, times and meeting place",
                    "trip photos",
                    "required certification level and diving experience",
                    "expected depth and number of available places",
                    "trip membership and organiser information",
                    "booking codes for dive center trips",
                    "messages sent within the trip's Bubble",
                  ],
                },
                {
                  text: "Published trip information may appear in Explore, including to people who are not signed in. Participant information, Bubble messages, transport coordination and restricted trip content are visible only to authorised participants and, for dive center trips, relevant dive center staff. Dive center staff may access messages within Bubbles connected to their dive center for trip coordination and management.",
                },
                { text: "Transport data" },
                { text: "If you offer or request transport, we may process:" },
                {
                  items: [
                    "number of available or requested places",
                    "vehicle type",
                    "an optional meeting location",
                    "your participation in a transport arrangement",
                  ],
                },
                {
                  text: "Transport information is visible only to members of the relevant Bubble and applicable dive center staff.",
                },
                { text: "DiveBubble Business data" },
                { text: "If you use DiveBubble Business, we may process:" },
                {
                  items: [
                    "your name and email address",
                    "your staff membership and role",
                    "the dive center's name, logo, description and location",
                    "agency affiliation and business contact details",
                    "trips and Bubbles managed through the workspace",
                  ],
                },
                {
                  text: "Information relating solely to a company is not always personal data, but this policy applies where business information identifies a person.",
                },
                { text: "Technical data" },
                {
                  text: "We process limited technical information needed to operate and secure DiveBubble, including authentication sessions and application or server error logs. Our infrastructure providers may process IP addresses, request timestamps and related network information when delivering and protecting the service.",
                },
              ]}
            />

            <LegalSection
              title="3. Why we use your data"
              paragraphs={[
                { text: "We process personal data for the following purposes and legal bases:" },
                { text: "Performance of our contract" },
                { text: "We process data necessary to:" },
                {
                  items: [
                    "create and maintain your account",
                    "provide your profile",
                    "display and manage trips",
                    "allow you to join Bubbles",
                    "deliver chat and transport features",
                    "provide DiveBubble Business",
                  ],
                },
                { text: "The legal basis is GDPR Article 6(1)(b)." },
                { text: "Legitimate interests" },
                { text: "We process limited data where necessary to:" },
                {
                  items: [
                    "secure and maintain DiveBubble",
                    "diagnose technical problems",
                    "prevent misuse",
                    "enforce our Terms",
                    "respond to complaints and legal claims",
                  ],
                },
                {
                  text: "The legal basis is GDPR Article 6(1)(f). Our legitimate interests are operating a reliable service and protecting DiveBubble and its users.",
                },
                { text: "Consent" },
                {
                  text: "With your permission, we may access your device's location to determine your city. You can withdraw this permission through your device settings and enter your city manually. The legal basis is GDPR Article 6(1)(a).",
                },
                { text: "Legal obligations" },
                {
                  text: "We may process or retain information where required by applicable law or a binding request from a competent authority. The legal basis is GDPR Article 6(1)(c).",
                },
              ]}
            />

            <LegalSection
              title="4. Who can see your information"
              paragraphs={[
                { text: "Depending on how you use DiveBubble, personal data may be visible to:" },
                {
                  items: [
                    "members of a Bubble you join",
                    "the organiser of a trip",
                    "relevant staff of a dive center organising the trip",
                    "people viewing trip information published in Explore",
                    "service providers helping us operate DiveBubble",
                  ],
                },
                {
                  text: "Dive centers are responsible for personal data they collect and use independently outside DiveBubble, including information used for external bookings, payments or customer administration. Their own privacy policies may apply to that processing.",
                },
              ]}
            />

            <LegalSection
              title="5. Service providers"
              paragraphs={[
                { text: "We use a limited number of providers to operate DiveBubble:" },
                {
                  items: [
                    "DigitalOcean — EU hosting, database and file storage",
                    "Cloudflare — DNS, network delivery and security",
                    "Vercel — hosting for the DiveBubble Business workspace and divebubble.io website",
                    "Google — Google Sign-In",
                    "Apple — Sign in with Apple and Apple platform services",
                  ],
                },
                {
                  text: "Centrifugo is self-hosted within our infrastructure and is used to deliver realtime messages. These providers process information only as needed to provide their services and subject to their applicable data protection terms.",
                },
                { text: "We do not sell personal data and do not share it for third-party advertising." },
              ]}
            />

            <LegalSection
              title="6. International transfers"
              paragraphs={[
                { text: "We primarily host DiveBubble data in the European Union." },
                {
                  text: "Some providers, including Google, Apple, Vercel and Cloudflare, may process limited information outside the European Economic Area. Where required, such transfers are protected by an applicable adequacy decision, the European Commission's Standard Contractual Clauses, or another lawful transfer mechanism.",
                },
                { text: "You may contact us for more information about the safeguards applicable to your data." },
              ]}
            />

            <LegalSection
              title="7. Data retention and account deletion"
              paragraphs={[
                { text: "We retain personal data only for as long as reasonably necessary to:" },
                {
                  items: [
                    "provide DiveBubble",
                    "maintain trip and conversation history",
                    "protect the service",
                    "resolve disputes",
                    "meet legal obligations",
                  ],
                },
                {
                  text: `You can delete your account through the app or request deletion by contacting ${SUPPORT_EMAIL}.`,
                },
                {
                  text: "When an account is deleted, we delete or anonymise associated personal data without undue delay unless continued retention is necessary for legal, security or dispute-resolution purposes.",
                },
                {
                  text: "Some messages may remain in anonymised form where necessary to preserve a conversation for other Bubble participants. Residual copies may remain temporarily in system backups until those backups are overwritten or deleted.",
                },
                { text: "Deleting the DiveBubble app from your device does not by itself delete your account." },
              ]}
            />

            <LegalSection
              title="8. Your rights"
              paragraphs={[
                { text: "Under the GDPR, you may have the right to:" },
                {
                  items: [
                    "access your personal data",
                    "correct inaccurate or incomplete data",
                    "request deletion",
                    "restrict certain processing",
                    "object to processing based on legitimate interests",
                    "receive certain data in a portable format",
                    "withdraw consent at any time where processing is based on consent",
                    "lodge a complaint with a supervisory authority",
                  ],
                },
                {
                  text: `You can edit certain information and delete your account from the app. You may also exercise your rights by emailing ${SUPPORT_EMAIL}.`,
                },
                {
                  text: "We normally respond within one month. This period may be extended where permitted by law, in which case we will inform you.",
                },
                {
                  text: "You may lodge a complaint with the data protection supervisory authority in your country of residence, place of work, or the place of an alleged infringement.",
                },
              ]}
            />

            <LegalSection
              title="9. Age requirement"
              paragraphs={[
                { text: "DiveBubble accounts are available only to people aged 18 or older." },
                {
                  text: "Minors may participate in a trip through and under the responsibility of a parent or legal guardian, where permitted by the trip organiser or dive center. A parent or guardian must use their own DiveBubble account and must not create an account in the minor's name.",
                },
                {
                  text: `We do not knowingly allow minors to create DiveBubble accounts. If you believe that a minor has created an account or provided personal data directly to us, contact ${SUPPORT_EMAIL}.`,
                },
              ]}
            />

            <LegalSection
              title="10. Security"
              paragraphs={[
                {
                  text: "We use reasonable technical and organisational measures designed to protect personal data, including access controls and encryption in transit.",
                },
                {
                  text: "No service can guarantee absolute security. You should contact us if you believe your account or personal data has been compromised.",
                },
              ]}
            />

            <LegalSection
              title="11. Changes to this policy"
              paragraphs={[
                { text: "We may update this Privacy Policy as DiveBubble develops or legal requirements change." },
                {
                  text: "We will update the effective date and notify users of material changes through the app, website or another appropriate method where required. If a change requires consent, we will request it separately.",
                },
              ]}
            />

            <div>
              <h2 className="font-serif text-xl font-semibold">12. Contact</h2>
              <p className="mt-2 text-sm text-brand-blue/70">
                For questions, requests or complaints concerning personal data, contact{" "}
                <a href={`mailto:${SUPPORT_EMAIL}`} className="underline underline-offset-2">
                  {SUPPORT_EMAIL}
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
