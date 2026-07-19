import { BubbleBackground } from "@/components/BubbleBackground";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { LegalSection } from "@/components/LegalSection";
import { COMPANY, SUPPORT_EMAIL } from "@/lib/constants";

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
          <p className="mt-4 text-white/60">Effective date: 19 July 2026</p>
          <p className="text-white/60">Last updated: 19 July 2026</p>

          <div className="mt-10 space-y-8 rounded-2xl bg-white p-8 text-brand-blue sm:p-10">
            <LegalSection
              title="1. Agreement"
              paragraphs={[
                { text: "These Terms of Use (“Terms”) form an agreement between you and:" },
                {
                  items: [
                    `Legal name: ${COMPANY.legalName}, ${COMPANY.legalForm}`,
                    `CVR: ${COMPANY.cvr}`,
                    `Address: ${COMPANY.address}`,
                    `Email: ${SUPPORT_EMAIL}`,
                    `Website: ${COMPANY.website}`,
                  ],
                },
                { text: "These Terms apply to the DiveBubble mobile and web app and the DiveBubble Business workspace." },
                {
                  text: "By creating an account or using DiveBubble, you agree to these Terms. If you are an EU consumer, these Terms do not limit statutory rights that cannot legally be excluded or waived.",
                },
                { text: "Our Privacy Policy explains how we process personal data." },
              ]}
            />

            <LegalSection
              title="2. The service"
              paragraphs={[
                {
                  text: "DiveBubble helps divers discover and organise dive trips, communicate with other participants, coordinate transport and connect with dive centers.",
                },
                { text: "DiveBubble includes:" },
                {
                  items: [
                    "an Explore marketplace containing trips created by divers and dive centers",
                    "Bubbles for trip participants, including group chat and transport coordination",
                    "profiles containing diving experience and certifications",
                    "DiveBubble Business, through which dive centers can manage staff, trips and Bubbles",
                  ],
                },
                {
                  text: "A “Trip” is a published dive activity. A “Bubble” is the participant area connected to that Trip.",
                },
                { text: "Features may change as DiveBubble develops." },
              ]}
            />

            <LegalSection
              title="3. Eligibility and accounts"
              paragraphs={[
                {
                  text: "You must be at least 18 years old to create or use a DiveBubble account. By creating an account, you confirm that you meet this requirement.",
                },
                {
                  text: "Minors may participate in trips when represented or accompanied by a parent or legal guardian and where permitted by the trip organiser or dive center. The parent or guardian must coordinate through their own DiveBubble account.",
                },
                {
                  text: "You may sign in using a supported authentication provider, such as Google or Apple. You are responsible for maintaining access to your authentication account and for activity conducted through your DiveBubble account.",
                },
                { text: "You must provide accurate information and must not impersonate another person." },
              ]}
            />

            <LegalSection
              title="4. Diving and safety"
              paragraphs={[
                { text: "Diving involves inherent risks. DiveBubble is a coordination platform and is not:" },
                {
                  items: [
                    "a dive operator",
                    "a certifying agency",
                    "a dive instructor",
                    "a medical professional",
                    "an emergency or rescue service",
                  ],
                },
                { text: "You are responsible for:" },
                {
                  items: [
                    "diving within your training and experience",
                    "verifying conditions, equipment and safety arrangements",
                    "assessing your medical fitness",
                    "following applicable laws and safety procedures",
                    "complying with the organiser's or dive center's requirements",
                    "verifying that a trip is suitable for you",
                  ],
                },
                {
                  text: "Information shown in a DiveBubble profile, including certifications and experience, is self-reported unless expressly stated otherwise. DiveBubble does not verify certifications, medical fitness, parental authority or eligibility to participate.",
                },
                { text: "In an emergency, contact the appropriate emergency services directly." },
              ]}
            />

            <LegalSection
              title="5. Trips and organisers"
              paragraphs={[
                { text: "Trips may be created by individual divers or dive centers." },
                { text: "Organisers are responsible for the information they publish and for establishing trip requirements, including:" },
                {
                  items: [
                    "qualifications and experience",
                    "equipment",
                    "capacity",
                    "meeting arrangements",
                    "safety rules",
                    "whether minors may participate",
                  ],
                },
                {
                  text: "Creating or joining a Trip through DiveBubble does not guarantee that the trip will take place or that a participant will be accepted by the organiser.",
                },
                { text: "You must independently assess an organiser, dive center and trip before participating." },
              ]}
            />

            <LegalSection
              title="6. Dive centers and external bookings"
              paragraphs={[
                { text: "Dive centers using DiveBubble Business are responsible for their own:" },
                {
                  items: [
                    "trips and services",
                    "staff",
                    "prices",
                    "bookings",
                    "cancellations and refunds",
                    "customer communications",
                    "safety and regulatory obligations",
                  ],
                },
                {
                  text: "DiveBubble may provide a booking code that allows a diver to join a Bubble after booking externally.",
                },
                {
                  text: "Unless expressly stated otherwise, DiveBubble does not process trip payments or bookings and is not a party to a transaction between a diver and a dive center. Any external booking or payment is governed by the dive center's own terms and policies.",
                },
                {
                  text: "DiveBubble does not guarantee the identity, qualifications, quality, conduct or safety of a dive center or individual organiser.",
                },
              ]}
            />

            <LegalSection
              title="7. Bubbles, chat and transport"
              paragraphs={[
                {
                  text: "Joining a Bubble allows you to communicate with its participants. Relevant staff of a dive center may access Bubbles associated with that dive center.",
                },
                {
                  text: "Messages and transport information are intended for trip coordination. You must not rely on DiveBubble as an emergency communication service.",
                },
                {
                  text: "Transport arrangements are made directly between users. DiveBubble does not provide transport and is not responsible for drivers, vehicles, insurance, routes, costs, delays or passenger safety.",
                },
                { text: "Use reasonable care before sharing a meeting place or other personal information." },
              ]}
            />

            <LegalSection
              title="8. Your content"
              paragraphs={[
                {
                  text: "You retain ownership of content you submit, including profile information, trip details, messages and photos.",
                },
                {
                  text: `You grant ${COMPANY.legalName} a non-exclusive, worldwide, royalty-free licence to host, store, reproduce, display and transmit that content only as necessary to:`,
                },
                {
                  items: [
                    "operate and provide DiveBubble",
                    "display it to the audiences you selected",
                    "maintain and secure the service",
                    "comply with legal obligations",
                    "enforce these Terms",
                  ],
                },
                {
                  text: "This licence ends when the content is deleted, except where limited retention is technically or legally necessary or where content has been anonymised.",
                },
                {
                  text: "You are responsible for your content and must have the rights and permissions necessary to share it. This includes permission to upload photographs of other identifiable people.",
                },
              ]}
            />

            <LegalSection
              title="9. Acceptable use"
              paragraphs={[
                { text: "You must not:" },
                {
                  items: [
                    "use DiveBubble for an unlawful or fraudulent purpose",
                    "harass, threaten, exploit or endanger another person",
                    "impersonate another person or misrepresent your qualifications",
                    "publish illegal, defamatory, infringing or deceptive content",
                    "upload content without the necessary rights or permission",
                    "expose another person's private information without permission",
                    "send spam or unsolicited advertising",
                    "interfere with the operation or security of DiveBubble",
                    "attempt to gain unauthorised access to accounts or systems",
                    "scrape, reverse engineer or overload the service, except where applicable law expressly permits an activity that cannot be restricted by contract",
                    "use DiveBubble to arrange unsafe or unlawful activities",
                  ],
                },
              ]}
            />

            <LegalSection
              title="10. Reporting and enforcement"
              paragraphs={[
                {
                  text: `If you believe content or conduct is illegal, unsafe or violates these Terms, contact ${SUPPORT_EMAIL} and provide enough information for us to identify and review it.`,
                },
                { text: "Where available, you may also use reporting or blocking tools within DiveBubble." },
                { text: "We may review reports and take proportionate action, including:" },
                {
                  items: [
                    "removing content",
                    "limiting access to a feature",
                    "suspending or terminating an account",
                    "preserving information where necessary for a legal claim",
                    "notifying competent authorities where required by law",
                  ],
                },
                { text: "We are not required to monitor every private message or verify all user-submitted information." },
              ]}
            />

            <LegalSection
              title="11. Intellectual property"
              paragraphs={[
                {
                  text: `DiveBubble, its software, design, branding and other materials provided by ${COMPANY.legalName} are owned by ${COMPANY.legalName} or its licensors.`,
                },
                {
                  text: "These Terms give you a limited, personal, non-exclusive and revocable right to use DiveBubble for its intended purpose. They do not transfer ownership of DiveBubble or its intellectual property to you.",
                },
              ]}
            />

            <LegalSection
              title="12. Availability and changes to the service"
              paragraphs={[
                {
                  text: "We aim to provide a reliable service but do not guarantee that DiveBubble will always be available, uninterrupted or error-free.",
                },
                {
                  text: "We may modify, suspend or discontinue features for operational, security, legal or business reasons. Where reasonably possible, we will provide notice if a change materially affects active users.",
                },
                { text: "Nothing in this section limits rights or remedies that cannot be excluded under consumer law." },
              ]}
            />

            <LegalSection
              title="13. Suspension, termination and account deletion"
              paragraphs={[
                { text: "You may stop using DiveBubble at any time. Deleting the app does not delete your account." },
                {
                  text: "You may delete your account through the app or contact us for assistance. Account deletion is handled in accordance with our Privacy Policy.",
                },
                { text: "We may suspend or terminate an account where we reasonably believe that:" },
                {
                  items: [
                    "these Terms have been materially or repeatedly violated",
                    "the account creates a safety or security risk",
                    "continued access may harm another person or DiveBubble",
                    "suspension or termination is required by law",
                  ],
                },
                { text: "Where appropriate and legally permitted, we will provide notice or an opportunity to address the issue." },
              ]}
            />

            <LegalSection
              title="14. Liability"
              paragraphs={[
                {
                  text: `DiveBubble provides tools for discovery and coordination. ${COMPANY.legalName} does not organise or operate trips unless expressly stated otherwise.`,
                },
                { text: `To the extent permitted by law, ${COMPANY.legalName} is not responsible for:` },
                {
                  items: [
                    "the acts or omissions of users, organisers or dive centers",
                    "the safety, quality or cancellation of a trip",
                    "external bookings, payments or refunds",
                    "transport arrangements between users",
                    "inaccurate user-submitted information",
                    "indirect or consequential losses that were not reasonably foreseeable",
                  ],
                },
                {
                  text: "Nothing in these Terms excludes or limits liability where doing so would be unlawful, including liability for fraud or for death or personal injury caused by our negligence.",
                },
                { text: "Your mandatory consumer rights remain unaffected." },
              ]}
            />

            <LegalSection
              title="15. Changes to these Terms"
              paragraphs={[
                { text: "We may update these Terms to reflect changes to DiveBubble, our business or applicable law." },
                {
                  text: "We will publish the updated Terms and revise the effective date. We will notify users of material changes through the app, website or another appropriate method before they take effect where reasonably required.",
                },
                { text: "If you do not agree to material changes, you may stop using DiveBubble and delete your account." },
              ]}
            />

            <LegalSection
              title="16. Governing law and disputes"
              paragraphs={[
                { text: "These Terms are governed by Danish law." },
                {
                  text: "If you are a consumer residing in the EU or EEA, this choice does not deprive you of mandatory protections provided by the law of your country of residence or any courts available to you under applicable consumer law.",
                },
                {
                  text: `Before starting formal proceedings, you may contact ${SUPPORT_EMAIL} so that we can try to resolve the matter.`,
                },
              ]}
            />

            <LegalSection
              title="17. Severability"
              paragraphs={[
                { text: "If any provision of these Terms is found invalid or unenforceable, the remaining provisions remain in effect." },
              ]}
            />

            <div>
              <h2 className="font-serif text-xl font-semibold">18. Contact</h2>
              <p className="mt-2 text-sm text-brand-blue/70">
                For questions concerning these Terms, contact{" "}
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
