import { ImageResponse } from "next/og";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

// Link-preview card for LinkedIn/Slack/iMessage etc. — root segment, so every page inherits it.
export const alt = "DiveBubble: every dive is better with a buddy";
// Rendered at 2x: LinkedIn blurs a 1200x630 source badly when it recompresses the thumbnail.
export const size = { width: 2400, height: 1260 };
export const contentType = "image/png";

export default async function Image() {
  const [fraunces, inter, logo] = await Promise.all([
    readFile(join(process.cwd(), "src/assets/Fraunces-SemiBold.ttf")),
    readFile(join(process.cwd(), "src/assets/Inter-Regular.ttf")),
    readFile(join(process.cwd(), "public/images/logo.png")),
  ]);
  const logoSrc = `data:image/png;base64,${logo.toString("base64")}`;

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "160px 192px",
          background: "linear-gradient(135deg, #0b3d91 0%, #0a2e6e 100%)",
          color: "white",
          fontFamily: "Inter",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 56 }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={logoSrc} width={224} height={224} style={{ borderRadius: 52 }} alt="" />
          <span style={{ fontFamily: "Fraunces", fontSize: 128 }}>DiveBubble</span>
        </div>
        <div style={{ marginTop: 112, fontFamily: "Fraunces", fontSize: 152, lineHeight: 1.1 }}>
          Every dive is better with a buddy.
        </div>
        <div style={{ marginTop: 56, fontSize: 64, color: "rgba(255,255,255,0.75)" }}>
          Organize dive trips, find your buddy, and split the costs.
        </div>
      </div>
    ),
    {
      ...size,
      fonts: [
        { name: "Fraunces", data: fraunces, weight: 600, style: "normal" },
        { name: "Inter", data: inter, weight: 400, style: "normal" },
      ],
    },
  );
}
