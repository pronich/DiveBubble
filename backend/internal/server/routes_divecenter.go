package server

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"divebubble_be/internal/auth"
	"divebubble_be/internal/divecenter"
	"divebubble_be/internal/email"
	"divebubble_be/internal/profile"

	"github.com/google/uuid"
)

func registerDiveCenterRoutes(
	mux *http.ServeMux,
	svc *divecenter.Service,
	identityRepo *auth.IdentityRepository,
	profileSvc *profile.Service,
	authIssuer *auth.TokenIssuer,
	emailSvc *email.Service,
) {
	mux.HandleFunc("POST /dive-centers", withAuth(authIssuer, handleCreateDiveCenter(svc)))
	mux.HandleFunc("GET /dive-centers/mine", withAuth(authIssuer, handleListMyDiveCenters(svc)))
	mux.HandleFunc("GET /dive-centers/{id}", withAuth(authIssuer, handleGetDiveCenter(svc)))
	mux.HandleFunc("GET /dive-centers/{id}/membership", withAuth(authIssuer, handleGetDiveCenterMembership(svc)))
	mux.HandleFunc("PATCH /dive-centers/{id}", withAuth(authIssuer, handleUpdateDiveCenter(svc)))
	mux.HandleFunc("GET /dive-centers/{id}/members", withAuth(authIssuer, handleListDiveCenterMembers(svc)))
	mux.HandleFunc("GET /dive-centers/{id}/members/search", withAuth(authIssuer, handleSearchDiveCenterMember(svc, identityRepo, profileSvc)))
	mux.HandleFunc("POST /dive-centers/{id}/members", withAuth(authIssuer, handleAddDiveCenterMember(svc)))
	mux.HandleFunc("DELETE /dive-centers/{id}/members/{userId}", withAuth(authIssuer, handleRemoveDiveCenterMember(svc)))
	mux.HandleFunc("POST /dive-centers/{id}/invitations", withAuth(authIssuer, handleInviteDiveCenterMember(svc, emailSvc)))
}

type diveCenterResponse struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	Location     *string   `json:"location,omitempty"`
	Description  *string   `json:"description,omitempty"`
	LogoURL      *string   `json:"logoUrl,omitempty"`
	Agency       *string   `json:"agency,omitempty"`
	AgencyDetail *string   `json:"agencyDetail,omitempty"`
	Languages    string    `json:"languages"`
	Website      *string   `json:"website,omitempty"`
	Phone        *string   `json:"phone,omitempty"`
	Email        *string   `json:"email,omitempty"`
	CreatedAt    time.Time `json:"createdAt"`
	Role         string    `json:"role,omitempty"`
}

func toDiveCenterResponse(dc divecenter.DiveCenter) diveCenterResponse {
	return diveCenterResponse{
		ID:           dc.ID,
		Name:         dc.Name,
		Location:     nullStringPtr(dc.Location),
		Description:  nullStringPtr(dc.Description),
		LogoURL:      nullStringPtr(dc.LogoURL),
		Agency:       nullStringPtr(dc.Agency),
		AgencyDetail: nullStringPtr(dc.AgencyDetail),
		Languages:    dc.Languages,
		Website:      nullStringPtr(dc.Website),
		Phone:        nullStringPtr(dc.Phone),
		Email:        nullStringPtr(dc.Email),
		CreatedAt:    dc.CreatedAt,
	}
}

type memberResponse struct {
	UserID             uuid.UUID `json:"userId"`
	Role               string    `json:"role"`
	JoinedAt           time.Time `json:"joinedAt"`
	DisplayName        *string   `json:"displayName,omitempty"`
	AvatarURL          *string   `json:"avatarUrl,omitempty"`
	CertificationLevel *string   `json:"certificationLevel,omitempty"`
	Email              *string   `json:"email,omitempty"`
}

func toMemberResponse(m divecenter.MemberView) memberResponse {
	return memberResponse{
		UserID:             m.UserID,
		Role:               m.Role,
		JoinedAt:           m.JoinedAt,
		DisplayName:        nullStringPtr(m.DisplayName),
		AvatarURL:          nullStringPtr(m.AvatarURL),
		CertificationLevel: nullStringPtr(m.CertificationLevel),
		Email:              nullStringPtr(m.Email),
	}
}

type createDiveCenterRequest struct {
	Name         string  `json:"name"`
	Location     *string `json:"location"`
	Description  *string `json:"description"`
	LogoURL      *string `json:"logoUrl"`
	Agency       *string `json:"agency"`
	AgencyDetail *string `json:"agencyDetail"`
	Languages    *string `json:"languages"`
	Website      *string `json:"website"`
	Phone        *string `json:"phone"`
}

func handleCreateDiveCenter(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		var req createDiveCenterRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		dc, err := svc.Create(r.Context(), divecenter.CreateParams{
			Name:         req.Name,
			Location:     req.Location,
			Description:  req.Description,
			LogoURL:      req.LogoURL,
			Agency:       req.Agency,
			AgencyDetail: req.AgencyDetail,
			Languages:    req.Languages,
			Website:      req.Website,
			Phone:        req.Phone,
		}, userID)
		if err != nil {
			if errors.Is(err, divecenter.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "name is required")
				return
			}
			log.Printf("create dive center failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not create dive center")
			return
		}

		resp := toDiveCenterResponse(dc)
		resp.Role = "owner"
		writeJSON(w, http.StatusCreated, resp)
	}
}

func handleListMyDiveCenters(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		views, err := svc.ListMine(r.Context(), userID)
		if err != nil {
			log.Printf("list my dive centers failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not list dive centers")
			return
		}
		out := make([]diveCenterResponse, 0, len(views))
		for _, v := range views {
			resp := toDiveCenterResponse(v.DiveCenter)
			resp.Role = v.Role
			out = append(out, resp)
		}
		writeJSON(w, http.StatusOK, out)
	}
}

// handleGetDiveCenter is deliberately not member-gated (unlike ListMembers) — every field
// a dive center's profile carries (name, location, agency, logo, contacts) was collected
// specifically to be shown to divers considering a trip (see CLAUDE.md's onboarding-fields
// note), so this is the same "any signed-in user" posture as GET /users/{id}'s public
// profile projection, not membership-gated the way roster/management endpoints are.
func handleGetDiveCenter(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		dc, err := svc.Get(r.Context(), id)
		if err != nil {
			if errors.Is(err, divecenter.ErrNotFound) {
				writeError(w, http.StatusNotFound, "dive center not found")
				return
			}
			log.Printf("get dive center failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not get dive center")
			return
		}
		writeJSON(w, http.StatusOK, toDiveCenterResponse(dc))
	}
}

type membershipResponse struct {
	IsMember bool   `json:"isMember"`
	Role     string `json:"role,omitempty"`
}

// handleGetDiveCenterMembership is the caller-scoped counterpart to the now-public
// GET /dive-centers/{id}: since that endpoint stopped implying membership (see its own
// comment), any client that needs to know "am I actually staff here" — e.g. app/'s Trip
// Page deciding whether to show organizer-only actions to a dive-center employee who
// didn't personally create the trip — needs an explicit check instead of inferring it.
// Scoped to the caller only, not a member-lookup-by-id, so it can't be used to probe
// anyone else's membership.
func handleGetDiveCenterMembership(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		isMember, err := svc.IsMember(r.Context(), id, userID)
		if err != nil {
			log.Printf("check dive center membership failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not check membership")
			return
		}
		if !isMember {
			writeJSON(w, http.StatusOK, membershipResponse{IsMember: false})
			return
		}
		isOwner, err := svc.IsOwner(r.Context(), id, userID)
		if err != nil {
			log.Printf("check dive center ownership failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not check membership")
			return
		}
		role := "staff"
		if isOwner {
			role = "owner"
		}
		writeJSON(w, http.StatusOK, membershipResponse{IsMember: true, Role: role})
	}
}

type updateDiveCenterRequest struct {
	Name         *string `json:"name"`
	Location     *string `json:"location"`
	Description  *string `json:"description"`
	Agency       *string `json:"agency"`
	AgencyDetail *string `json:"agencyDetail"`
	Languages    *string `json:"languages"`
	Website      *string `json:"website"`
	Phone        *string `json:"phone"`
	Email        *string `json:"email"`
}

// handleUpdateDiveCenter is owner-only (enforced inside svc.Update) — every field optional,
// a nil pointer leaves that column untouched (see divecenter.UpdateParams). Logo has its
// own dedicated upload endpoint (POST /dive-centers/{id}/logo) rather than a field here,
// same split as trip photo vs. trip field edits.
func handleUpdateDiveCenter(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		var req updateDiveCenterRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}

		dc, err := svc.Update(r.Context(), id, userID, divecenter.UpdateParams{
			Name:         req.Name,
			Location:     req.Location,
			Description:  req.Description,
			Agency:       req.Agency,
			AgencyDetail: req.AgencyDetail,
			Languages:    req.Languages,
			Website:      req.Website,
			Phone:        req.Phone,
			Email:        req.Email,
		})
		if err != nil {
			if errors.Is(err, divecenter.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "name cannot be blank")
				return
			}
			if errors.Is(err, divecenter.ErrOnlyOwner) {
				writeError(w, http.StatusForbidden, "only an owner can edit the company profile")
				return
			}
			log.Printf("update dive center failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not update dive center")
			return
		}
		writeJSON(w, http.StatusOK, toDiveCenterResponse(dc))
	}
}

// handleListDiveCenterMembers is member-gated (any role) — staff can see their own
// roster, not just owners (enforced inside svc.ListMembers).
func handleListDiveCenterMembers(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		members, err := svc.ListMembers(r.Context(), id, userID)
		if err != nil {
			if errors.Is(err, divecenter.ErrNotAMember) {
				writeError(w, http.StatusForbidden, "not a member of this dive center")
				return
			}
			log.Printf("list dive center members failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not list members")
			return
		}
		out := make([]memberResponse, 0, len(members))
		for _, m := range members {
			out = append(out, toMemberResponse(m))
		}
		writeJSON(w, http.StatusOK, out)
	}
}

type memberPreviewResponse struct {
	UserID      uuid.UUID `json:"userId"`
	DisplayName *string   `json:"displayName,omitempty"`
	AvatarURL   *string   `json:"avatarUrl,omitempty"`
}

// handleSearchDiveCenterMember is a deliberately narrow prefix-email lookup (see
// auth.IdentityRepository.FindUserIDByEmail), not a user directory — owner-only, and returns
// just enough (name/avatar) to confirm "is this the right person" before actually adding
// them via handleAddDiveCenterMember.
func handleSearchDiveCenterMember(svc *divecenter.Service, identityRepo *auth.IdentityRepository, profileSvc *profile.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		isOwner, err := svc.IsOwner(r.Context(), id, userID)
		if err != nil {
			log.Printf("verify dive center ownership failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not verify membership")
			return
		}
		if !isOwner {
			writeError(w, http.StatusForbidden, "only an owner can search for members")
			return
		}

		email := strings.TrimSpace(r.URL.Query().Get("email"))
		if email == "" {
			writeError(w, http.StatusBadRequest, "email query parameter is required")
			return
		}

		targetID, err := identityRepo.FindUserIDByEmail(r.Context(), email)
		if err != nil {
			if errors.Is(err, auth.ErrIdentityNotFound) {
				writeError(w, http.StatusNotFound, "no account found for that email")
				return
			}
			if errors.Is(err, auth.ErrIdentityAmbiguous) {
				writeError(w, http.StatusConflict, "more than one account matches that email — type more of it")
				return
			}
			log.Printf("search dive center member failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not search for member")
			return
		}

		p, err := profileSvc.Get(r.Context(), targetID)
		if err != nil {
			log.Printf("load profile for dive center member search failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not load profile")
			return
		}
		writeJSON(w, http.StatusOK, memberPreviewResponse{
			UserID:      targetID,
			DisplayName: nullStringPtr(p.DisplayName),
			AvatarURL:   nullStringPtr(p.AvatarURL),
		})
	}
}

type addMemberRequest struct {
	UserID uuid.UUID `json:"userId"`
	Role   string    `json:"role"`
}

func handleAddDiveCenterMember(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		var req addMemberRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		if req.UserID == uuid.Nil {
			writeError(w, http.StatusBadRequest, "userId is required")
			return
		}

		m, err := svc.AddMember(r.Context(), id, userID, req.UserID, req.Role)
		if err != nil {
			if errors.Is(err, divecenter.ErrOnlyOwner) {
				writeError(w, http.StatusForbidden, "only an owner can add members")
				return
			}
			log.Printf("add dive center member failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not add member")
			return
		}
		// Bare Member, not the enriched MemberView ListMembers returns — admin/ reloads the
		// full roster right after a successful add anyway, so this response doesn't need to
		// carry name/avatar/email itself.
		writeJSON(w, http.StatusCreated, toMemberResponse(divecenter.MemberView{Member: m}))
	}
}

func handleRemoveDiveCenterMember(svc *divecenter.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		targetID, err := uuid.Parse(r.PathValue("userId"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid user id")
			return
		}

		if err := svc.RemoveMember(r.Context(), id, userID, targetID); err != nil {
			if errors.Is(err, divecenter.ErrOnlyOwner) {
				writeError(w, http.StatusForbidden, "only an owner can remove members")
				return
			}
			if errors.Is(err, divecenter.ErrCannotRemoveLastOwner) {
				writeError(w, http.StatusConflict, "cannot remove the last owner")
				return
			}
			if errors.Is(err, divecenter.ErrNotAMember) {
				writeError(w, http.StatusNotFound, "member not found")
				return
			}
			log.Printf("remove dive center member failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not remove member")
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

type inviteMemberRequest struct {
	Email string `json:"email"`
	Role  string `json:"role"`
}

type invitationResponse struct {
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"createdAt"`
}

// handleInviteDiveCenterMember is the counterpart to handleAddDiveCenterMember for an email
// with no DiveBubble account yet — admin/'s AddMemberDialog calls this when
// handleSearchDiveCenterMember 404s. Unlike most side-effect emails elsewhere in this
// codebase, the send failure here is NOT best-effort: it's the entire point of the request,
// and v1 has no pending-invitations UI that would otherwise let an owner notice a silently
// -dropped send (see CLAUDE.md).
func handleInviteDiveCenterMember(svc *divecenter.Service, emailSvc *email.Service) func(http.ResponseWriter, *http.Request, uuid.UUID) {
	return func(w http.ResponseWriter, r *http.Request, userID uuid.UUID) {
		id, err := uuid.Parse(r.PathValue("id"))
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid dive center id")
			return
		}
		var req inviteMemberRequest
		dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
		if err := dec.Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "invalid JSON body")
			return
		}
		if strings.TrimSpace(req.Email) == "" {
			writeError(w, http.StatusBadRequest, "email is required")
			return
		}

		inv, err := svc.InviteMember(r.Context(), id, userID, req.Email, req.Role)
		if err != nil {
			if errors.Is(err, divecenter.ErrOnlyOwner) {
				writeError(w, http.StatusForbidden, "only an owner can invite members")
				return
			}
			if errors.Is(err, divecenter.ErrInvalidArgument) {
				writeError(w, http.StatusBadRequest, "email is required")
				return
			}
			log.Printf("invite dive center member failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not create invitation")
			return
		}

		dc, err := svc.Get(r.Context(), id)
		if err != nil {
			log.Printf("load dive center for invitation email failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not send invitation")
			return
		}
		if err := emailSvc.SendTemplate(r.Context(), inv.Email, email.TemplateInvitation, map[string]string{
			email.VarDiveCenterName: dc.Name,
		}); err != nil {
			log.Printf("send invitation email failed: %v", err)
			writeError(w, http.StatusInternalServerError, "could not send invitation email")
			return
		}

		writeJSON(w, http.StatusCreated, invitationResponse{Email: inv.Email, Role: inv.Role, CreatedAt: inv.CreatedAt})
	}
}
