package email

// Resend template aliases + their variable keys, configured in Resend's own dashboard —
// this package only ever refers to them by these constants, never builds the email content
// itself (see Service.SendTemplate's own doc comment). TemplateInvitation isn't wired up to
// any handler yet — staff invitation by email (for someone who doesn't have a DiveBubble
// account yet) is still deferred past MVP, same as CLAUDE.md's Membership API notes — the
// alias is just reserved here ahead of that round.
const (
	TemplateMagicLink = "divebubble-signin"
	TemplateOTP       = "divebubble-mobile-signin"
	// TemplateInvitation fires when a dive-center owner invites an email with no DiveBubble
	// account yet (see divecenter.Service.InviteMember) — no invite-specific link/token, the
	// CTA is a static link to admin.divebubble.io, since a normal sign-in with the invited
	// email is itself the proof needed (see divecenter.Service.AcceptInvitations).
	TemplateInvitation = "invitation-divebubble"
	// TemplateWelcome fires once, right after a brand-new account's very first sign-in
	// (isNewUser == true) — regardless of which of the three providers created it. No
	// variables: unlike TemplateInvitation, there's no name to interpolate reliably across
	// all three providers (email/OTP sign-up never has one), so the template stays generic.
	TemplateWelcome = "divebubble-welcome"

	VarMagicLink      = "magic_link"
	VarOTPCode        = "signin_code"
	VarDiveCenterName = "dive_center_name"
)
