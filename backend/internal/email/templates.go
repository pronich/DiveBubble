package email

// Resend template aliases and their variable keys, referenced only by these constants (see Service.SendTemplate); TemplateInvitation is reserved but not yet wired to any handler since staff invitation by email is deferred past MVP.
const (
	TemplateMagicLink = "divebubble-signin"
	TemplateOTP       = "divebubble-mobile-signin"
	// TemplateInvitation fires when a dive-center owner invites an email with no DiveBubble account yet; its CTA is a static admin.divebubble.io link since a normal sign-in with that email is itself the proof (see divecenter.Service.AcceptInvitations).
	TemplateInvitation = "invitation-divebubble"
	// TemplateWelcome fires once on a brand-new account's first sign-in (isNewUser == true) regardless of provider, with no variables since email/OTP sign-up never has a reliable name to interpolate.
	TemplateWelcome = "divebubble-welcome"

	VarMagicLink      = "magic_link"
	VarOTPCode        = "signin_code"
	VarDiveCenterName = "dive_center_name"
)
