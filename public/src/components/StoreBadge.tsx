import Image from "next/image";

function Tag({ children }: { children: React.ReactNode }) {
  return (
    <span className="absolute -right-2 -top-2 rounded-full bg-white px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-brand-blue shadow">
      {children}
    </span>
  );
}

// Renders as a plain (non-clickable) image while APP_LINKS_LIVE is off — see
// src/config/appLaunch.ts — and becomes a real link the moment it flips on.
export function StoreBadge({
  href,
  live,
  src,
  alt,
  width,
  height,
  tag,
}: {
  href: string;
  live: boolean;
  src: string;
  alt: string;
  width: number;
  height: number;
  tag?: string;
}) {
  const badge = (
    <div className="relative inline-block">
      <Image src={src} alt={alt} width={width} height={height} />
      {tag && <Tag>{tag}</Tag>}
    </div>
  );

  if (!live) return badge;

  return (
    <a href={href} target="_blank" rel="noopener noreferrer">
      {badge}
    </a>
  );
}
