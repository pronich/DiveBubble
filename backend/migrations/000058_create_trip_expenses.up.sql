-- Splitwise-style shared expenses, scoped to a trip. amount_minor/currency follow the trip's
-- own price_minor convention (no per-expense currency — expenses just use whatever unit the
-- trip is already priced in).
CREATE TABLE trip_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    payer_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount_minor BIGINT NOT NULL,
    split_type TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX trip_expenses_trip_id_idx ON trip_expenses (trip_id);

-- One row per participant in the split. shares is only meaningful for split_type = 'shares'
-- (kept alongside amount_minor so re-opening an expense for edit can show the diver's original
-- 1/2/3 share counts, not just the derived amount) — amount_minor is always populated
-- regardless of split_type, so balance math never needs to re-derive the split.
CREATE TABLE trip_expense_shares (
    expense_id UUID NOT NULL REFERENCES trip_expenses (id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    shares INTEGER,
    amount_minor BIGINT NOT NULL,
    PRIMARY KEY (expense_id, user_id)
);

-- A recorded "I paid you back" — modeled as its own ledger entry (not a flag on an expense)
-- so the balance computation is always just SUM(expenses) - SUM(settlements), same idea
-- Splitwise itself uses internally for payments.
CREATE TABLE trip_expense_settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    from_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    amount_minor BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX trip_expense_settlements_trip_id_idx ON trip_expense_settlements (trip_id);
