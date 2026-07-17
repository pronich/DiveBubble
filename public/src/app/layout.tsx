import type { Metadata } from "next";
import { Fraunces, Inter } from "next/font/google";
import "./globals.css";

// Same pairing as app/'s AppTextTheme and admin/'s AdminTheme — Fraunces for
// headings (brand warmth), Inter for everything else (legibility at small sizes).
const fraunces = Fraunces({
  variable: "--font-fraunces",
  subsets: ["latin"],
  display: "swap",
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://divebubble.io"),
  title: {
    default: "DiveBubble",
    template: "%s — DiveBubble",
  },
  description:
    "DiveBubble is the simplest way to discover local dive trips, meet the group, and coordinate everything from rides to surface intervals.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${fraunces.variable} ${inter.variable} h-full antialiased`}>
      {/* suppressHydrationWarning: the Grammarly browser extension injects
          data-gr-ext-installed/data-new-gr-c-s-check-loaded onto <body> before React
          hydrates — a false-positive mismatch Next.js itself calls out as a known
          extension-caused case, not a real rendering bug. */}
      <body className="min-h-full flex flex-col bg-[#0b3d91] text-white font-sans" suppressHydrationWarning>
        {children}
      </body>
    </html>
  );
}
