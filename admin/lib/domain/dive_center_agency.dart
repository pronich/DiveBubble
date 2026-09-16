/// A fixed, client-validated list rather than free text, so values can't drift ("PADI" vs "padi" vs "P.A.D.I.") and break later comparisons/filters.
const kDiveCenterAgencies = ['PADI', 'SSI', 'NAUI', 'CMAS', 'Other'];
