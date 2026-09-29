import { ImageResponse } from "next/og";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

// Link-preview card for LinkedIn/Slack/iMessage etc. — root segment, so every page inherits it.
export const alt = "DiveBubble: every dive is better with a buddy";
export const size = { width: 1200, height: 630 };
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
          padding: "80px 96px",
          background: "linear-gradient(135deg, #0b3d91 0%, #0a2e6e 100%)",
          color: "white",
          fontFamily: "Inter",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 28 }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={logoSrc} width={112} height={112} style={{ borderRadius: 26 }} alt="" />
          <span style={{ fontFamily: "Fraunces", fontSize: 64 }}>DiveBubble</span>
        </div>
        <div style={{ marginTop: 56, fontFamily: "Fraunces", fontSize: 76, lineHeight: 1.1 }}>
          Every dive is better with a buddy.
        </div>
        <div style={{ marginTop: 28, fontSize: 32, color: "rgba(255,255,255,0.75)" }}>
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
