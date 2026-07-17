// Decorative floating bubbles over the brand-blue background — the same motif as app/'s logo
// mark (logo_bubbles.dart) and intro animation, just static and scattered rather than
// assembled into the "B" shape. Purely visual: aria-hidden, pointer-events-none, and fixed so
// it doesn't affect page layout or scroll with content.
//
// Each bubble is a radial gradient (light near one edge, fading to transparent) plus a thin
// rim and a small blurred specular highlight offset toward the light — a flat single-opacity
// circle reads as a plain dot, this reads as an actual sphere, same "glossy highlight arc"
// idea the real logo uses (see logo_bubbles.dart's own highlight paths).
export function BubbleBackground() {
  const bubbles = [
    { top: "6%", left: "80%", size: 220, opacity: 0.16 },
    { top: "14%", left: "2%", size: 300, opacity: 0.13 },
    { top: "44%", left: "90%", size: 140, opacity: 0.18 },
    { top: "62%", left: "8%", size: 380, opacity: 0.1 },
    { top: "78%", left: "68%", size: 200, opacity: 0.14 },
    { top: "2%", left: "42%", size: 110, opacity: 0.16 },
    { top: "88%", left: "30%", size: 90, opacity: 0.15 },
  ];

  return (
    <div aria-hidden className="pointer-events-none fixed inset-0 overflow-hidden">
      {bubbles.map((b, i) => (
        <div
          key={i}
          className="absolute rounded-full"
          style={{
            top: b.top,
            left: b.left,
            width: b.size,
            height: b.size,
            opacity: b.opacity,
            background:
              "radial-gradient(circle at 32% 28%, rgba(255,255,255,0.9), rgba(255,255,255,0.25) 45%, rgba(255,255,255,0.02) 75%)",
            boxShadow: "inset -8px -8px 24px rgba(255,255,255,0.04), inset 6px 6px 18px rgba(6,31,74,0.25)",
            border: "1px solid rgba(255,255,255,0.12)",
          }}
        >
          <div
            className="absolute rounded-full bg-white blur-[2px]"
            style={{
              top: "18%",
              left: "22%",
              width: b.size * 0.22,
              height: b.size * 0.12,
              opacity: 0.5,
              transform: "rotate(-25deg)",
            }}
          />
        </div>
      ))}
    </div>
  );
}
