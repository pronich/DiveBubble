// admin/ has no business sign-up open yet — deliberately, see CLAUDE.md's Product context
// (individual app launches first). "Dive in" collects an email instead of linking here for
// now (see DiveInButton) — kept as a constant for whenever sign-up actually opens.
export const ADMIN_URL = "https://admin.divebubble.io";

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "https://api.divebubble.io";

export const SUPPORT_EMAIL = "support@divebubble.io";

// Same legal entity as foreignreader_public's Privacy/Terms pages — one person operates
// both, no separate company set up for DiveBubble yet.
export const COMPANY = {
  legalName: "NP Platforms",
  legalForm: "a Danish sole proprietorship",
  cvr: "44888548",
  address: "Martha Christensens Vej 29, 6. tv., 2300 Copenhagen S, Denmark",
  website: "divebubble.io",
};
