/// Canonical list, same reasoning as app/'s kCertificationLevels — free text can't be
/// compared/filtered later ("PADI" vs "padi" vs "P.A.D.I."), so this stays a fixed list
/// validated client-side, not a DB enum (see migration 000024's own comment).
const kDiveCenterAgencies = ['PADI', 'SSI', 'NAUI', 'CMAS', 'Other'];
