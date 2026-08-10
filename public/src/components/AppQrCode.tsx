import { buildAppQrSvg } from "@/lib/qr";

export async function AppQrCode({ size = 96, className }: { size?: number; className?: string }) {
  const { dim, markup } = await buildAppQrSvg();

  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${dim} ${dim}`}
      role="img"
      aria-label="QR code to download DiveBubble"
      className={className}
      dangerouslySetInnerHTML={{ __html: markup }}
    />
  );
}
