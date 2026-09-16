import Image from "next/image";
import Link from "next/link";
import { ADMIN_URL } from "@/lib/constants";
import { MobileNav } from "@/components/MobileNav";

// "Dive in" only shows on the (currently unlinked, kept for reactivation) Business page — individuals only ever sign in from the app itself.
export function Header({ showDiveIn = false }: { showDiveIn?: boolean }) {
  return (
    // z-40 so header wins DOM-order stacking against <main>'s own position:relative and covers the mobile dropdown.
    <header className="relative z-40 border-b border-white/10">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
        <Link href="/" className="flex items-center gap-2.5">
          <Image src="/images/logo.png" alt="" width={32} height={32} className="rounded-lg" />
          <span className="font-serif text-lg font-semibold">DiveBubble</span>
        </Link>
        <div className="flex items-center gap-5">
          <Link href="/faq" className="hidden text-sm text-white/85 hover:text-white sm:inline-block">
            FAQ
          </Link>
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
