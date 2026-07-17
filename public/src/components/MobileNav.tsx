"use client";

import Link from "next/link";
import { useState } from "react";

// Header's own nav links are hidden below sm: (no room for three text links next to the
// logo and the Dive-in slot on a phone width) — without this, scrolling to the bottom CTA
// was the only way to reach /business on mobile at all. A hamburger + dropdown, not a
// full-screen drawer, since three short links don't need one.
export function MobileNav() {
  const [open, setOpen] = useState(false);

  return (
    <div className="sm:hidden">
      <button
        type="button"
        aria-label={open ? "Close menu" : "Open menu"}
        onClick={() => setOpen((v) => !v)}
        className="flex h-9 w-9 items-center justify-center rounded-full hover:bg-white/10"
      >
        {open ? (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
            <path d="M6 6l12 12M18 6L6 18" stroke="white" strokeWidth={2} strokeLinecap="round" />
          </svg>
        ) : (
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
            <path d="M4 7h16M4 12h16M4 17h16" stroke="white" strokeWidth={2} strokeLinecap="round" />
          </svg>
        )}
      </button>

      {open && (
        <div className="absolute inset-x-0 top-full border-b border-white/10 bg-brand-blue px-6 py-4">
          <nav className="flex flex-col gap-4 text-sm text-white/85">
            <Link href="/" onClick={() => setOpen(false)} className="hover:text-white">
              Individuals
            </Link>
            <Link href="/business" onClick={() => setOpen(false)} className="hover:text-white">
              Business
            </Link>
            <Link href="/faq" onClick={() => setOpen(false)} className="hover:text-white">
              FAQ
            </Link>
          </nav>
        </div>
      )}
    </div>
  );
}
