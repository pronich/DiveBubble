import Image from "next/image";
import Link from "next/link";
import { ADMIN_URL } from "@/lib/constants";
import { MobileNav } from "@/components/MobileNav";

// "Dive in" only ever appears here on the Business page (see its own page.tsx) — every other
// page has no login affordance at all, per product decision: individuals never sign in from
// the marketing site, only from the app itself.
export function Header({ showDiveIn = false }: { showDiveIn?: boolean }) {
  return (
    // z-40: every page's <main> is also `position: relative` (for its own absolutely
    // positioned children), and with both header and main "positioned" but neither having an
    // explicit z-index, they'd stack in DOM order — main comes after header and would paint
    // over the mobile dropdown otherwise. An explicit z-index settles it unambiguously.
    <header className="relative z-40 border-b border-white/10">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link href="/" className="flex items-center gap-2.5">
          <Image src="/images/logo.png" alt="" width={32} height={32} className="rounded-lg" />
          <span className="font-serif text-lg font-semibold">DiveBubble</span>
        </Link>
        <nav className="hidden items-center gap-8 text-sm text-white/85 sm:flex">
          <Link href="/" className="hover:text-white">
            Individuals
          </Link>
          <Link href="/business" className="hover:text-white">
            Business
          </Link>
          <Link href="/faq" className="hover:text-white">
            FAQ
          </Link>
        </nav>
        <div className="flex items-center gap-3">
          <MobileNav />
          {showDiveIn ? (
            <a
              href={ADMIN_URL}
              className="rounded-full bg-white px-5 py-2 text-sm font-semibold text-brand-blue hover:bg-white/90"
            >
              Dive in
            </a>
          ) : (
            <span className="hidden w-0 sm:inline-block sm:w-[92px]" aria-hidden />
          )}
        </div>
      </div>
    </header>
  );
}
