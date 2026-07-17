import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-white/10">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 py-8 text-sm text-white/70 sm:flex-row">
        <span className="font-serif text-base font-semibold text-white">DiveBubble</span>
        <nav className="flex items-center gap-6">
          <Link href="/faq" className="hover:text-white">
            FAQ
          </Link>
          <Link href="/privacy" className="hover:text-white">
            Privacy
          </Link>
          <Link href="/terms" className="hover:text-white">
            Terms &amp; Conditions
          </Link>
          <Link href="/business" className="hover:text-white">
            Business
          </Link>
        </nav>
        <span>&copy; {new Date().getFullYear()} DiveBubble</span>
      </div>
    </footer>
  );
}
