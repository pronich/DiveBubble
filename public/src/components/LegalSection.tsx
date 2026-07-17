// Shared section renderer for /privacy and /terms — a title, one or more paragraphs, and an
// optional bullet list per paragraph. Kept generic rather than one component per page since
// both pages have the exact same "heading + prose + occasional list" shape.
type Paragraph = { text?: string; items?: string[] };

export function LegalSection({ title, paragraphs }: { title: string; paragraphs: Paragraph[] }) {
  return (
    <div>
      <h2 className="font-serif text-xl font-semibold">{title}</h2>
      <div className="mt-2 space-y-2 text-sm text-brand-blue/70">
        {paragraphs.map((p, i) => (
          <div key={i}>
            {p.text ? <p>{p.text}</p> : null}
            {p.items ? (
              <ul className="ml-4 list-disc space-y-1">
                {p.items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            ) : null}
          </div>
        ))}
      </div>
    </div>
  );
}
