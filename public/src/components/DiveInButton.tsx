"use client";

import { useState } from "react";
import { API_URL } from "@/lib/constants";

// Business sign-up on admin/ isn't open yet — deliberately (see CLAUDE.md's Product
// context: the individual app launches first). Every "Dive in" on this page renders one of
// these instead of linking straight to ADMIN_URL, so each click opens its own self-contained
// popup rather than needing shared state across the header pill and the two page CTAs.
export function DiveInButton({ className, children }: { className: string; children: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "done" | "error">("idle");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setStatus("loading");
    try {
      const res = await fetch(`${API_URL}/waitlist`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      setStatus(res.ok ? "done" : "error");
    } catch {
      setStatus("error");
    }
  }

  function close() {
    setOpen(false);
    setStatus("idle");
    setEmail("");
  }

  return (
    <>
      <button type="button" className={className} onClick={() => setOpen(true)}>
        {children}
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4"
          onClick={close}
        >
          <div
            className="w-full max-w-sm rounded-2xl bg-white p-6 text-brand-blue shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            {status === "done" ? (
              <>
                <h2 className="font-serif text-xl font-semibold">You&apos;re on the list</h2>
                <p className="mt-2 text-sm text-brand-blue/70">
                  We&apos;ll email you the moment DiveBubble Business opens up.
                </p>
                <button
                  type="button"
                  onClick={close}
                  className="mt-6 w-full rounded-full bg-brand-blue py-2.5 text-sm font-semibold text-white hover:bg-brand-navy"
                >
                  Close
                </button>
              </>
            ) : (
              <>
                <h2 className="font-serif text-xl font-semibold">Not open just yet</h2>
                <p className="mt-2 text-sm text-brand-blue/70">
                  DiveBubble Business opens once the diver app is live. Leave your email and we&apos;ll let you know
                  — totally optional.
                </p>
                <form onSubmit={submit} className="mt-4 space-y-3">
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@divecenter.com"
                    className="w-full rounded-full border border-brand-blue/20 px-4 py-2.5 text-sm outline-none focus:border-brand-blue"
                  />
                  {status === "error" && (
                    <p className="text-xs text-red-600">Something went wrong — try again in a moment.</p>
                  )}
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={close}
                      className="flex-1 rounded-full border border-brand-blue/20 py-2.5 text-sm font-semibold hover:bg-brand-blue/5"
                    >
                      Maybe later
                    </button>
                    <button
                      type="submit"
                      disabled={status === "loading"}
                      className="flex-1 rounded-full bg-brand-blue py-2.5 text-sm font-semibold text-white hover:bg-brand-navy disabled:opacity-60"
                    >
                      Notify me
                    </button>
                  </div>
                </form>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}
