package email

// Resend template aliases + their variable keys, configured in Resend's own dashboard —
// this package only ever refers to them by these constants, never builds the email content
// itself (see Service.SendTemplate's own doc comment). TemplateInvitation isn't wired up to
// any handler yet — staff invitation by email (for someone who doesn't have a DiveBubble
// account yet) is still deferred past MVP, same as CLAUDE.md's Membership API notes — the
// alias is just reserved here ahead of that round.
const (
	TemplateMagicLink  = "divebubble-signin"
	TemplateOTP        = "divebubble-mobile-signin"
	TemplateInvitation = "invitation-divebubble"

	VarMagicLink   = "magic_link"
	VarOTPCode     = "signin_code"
	VarInviteeName = "invitee_name"
)
