# melai_nuts

A Prototype

## Setup: Firebase keys (required)

Firebase API keys are **not committed**. Before running:

```bash
cp env/firebase.example.json env/firebase.json          # then fill in your keys
cp android/app/google-services.json.example android/app/google-services.json  # Android only

flutter run --dart-define-from-file=env/firebase.json --dart-define-from-file=env/supabase.json
flutter build apk --dart-define-from-file=env/firebase.json --dart-define-from-file=env/supabase.json
```

`env/firebase.json` and `android/app/google-services.json` are git-ignored.
See [SECURITY.md](SECURITY.md) for key restriction and rotation.

## Setup: Supabase backend (required)

The app stores all business data (catalog, cart, orders, loyalty, payments,
refunds, notifications, addresses) in Supabase. Firebase remains the identity
provider. The app will not start without these values.

1. In the Supabase dashboard enable **Authentication > Sign In / Providers >
   Third Party Auth > Firebase** and paste your Firebase **Project ID**.
2. Run the SQL in this order (SQL Editor or `psql`):
   1. `supabase/schema.sql`
   2. `supabase/migrations/20260928000000_customer_security_hardening.sql`
   3. `supabase/migrations/20260928010000_order_integrity.sql`
   4. `supabase/migrations/20260929000000_customer_product_search.sql`
   5. `supabase/migrations/20260929010000_customer_realtime.sql`
   6. `supabase/migrations/20260930000000_staff_backend.sql` (staff side, see below)
   7. `supabase/migrations/20260930010000_staff_foundation.sql` (staff foundation: account status, permissions, audit log)
3. Copy `env/supabase.example.json` to `env/supabase.json` and fill in the
   project URL and **anon** key (never the `service_role` key).
4. Run with both files:

```bash
flutter run \
  --dart-define-from-file=env/firebase.json \
  --dart-define-from-file=env/supabase.json
```

`env/supabase.json` is git-ignored. Verify a dev/staging database with the
suites in `supabase/tests/` (dev only; each rolls back its own data).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Staff backend setup (migration `20260930000000_staff_backend.sql`)

Run it after the earlier migrations (Supabase SQL editor). It adds the staff
registry (`staff_members`), branch inventory batches (FEFO), stock transfers,
walk-in POS sales, staff notifications, the dashboard function and the
row-level-security policies that enforce staff access in the database.

1. Register the first owner once, in the SQL editor:
   `insert into public.staff_members (firebase_uid, full_name, email, role)
    values ('<owner firebase uid>', '<name>', '<email>', 'owner');`
2. Staff created from the app (Owner → User Management) are registered
   automatically. Staff that already existed must be inserted the same way
   with `role = 'staff'` and a `branch_id`.
3. Stock that existed before this migration has no batch: staff give it one
   from a product's page (Receive Stock → "Units already counted in stock").
4. Staff identity is one thing end to end: Firebase UID → `staff_members` row →
   branch + permission flags. After sign-in the app makes a single call,
   `get_my_staff_context()`, which answers `active`, `inactive` or
   `not_provisioned`. Staff screens stay locked (fail closed) until the server
   has confirmed an active row for exactly the signed-in account, and every
   staff store is wiped on sign-out or account switch. The database re-checks
   the same rules on every request, so a modified client gains nothing.
5. The app refuses to start with a `service_role` / `sb_secret_` key in
   `env/supabase.json` (only the anon / publishable key belongs in the app).
6. Verify on a dev database with `psql -v ON_ERROR_STOP=1 -f supabase/tests/staff_identity_test.sql`
   and `psql -v ON_ERROR_STOP=1 -f supabase/tests/staff_foundation_test.sql`.

### Staff foundation (migration `20260930010000_staff_foundation.sql`)

Run it right after the staff backend migration (it is idempotent).

- **Account status** is now `active | inactive | suspended`
  (`staff_members.account_status`); `is_active` became a generated column, so
  the two can never disagree. Owners suspend/restore with
  `owner_set_staff_status(uid, status)`; `owner_set_staff_active` still works.
  Re-provisioning a suspended account does **not** lift the suspension.
- **Profile fields**: `phone`, `profile_image`. `email` is kept in step with the
  verified Firebase token by `staff_sync_my_identity()` (the value comes from the
  JWT on the server, never from the client).
- **Permissions**: `staff_permission_catalog()` lists the permission keys,
  `staff_permission_grants` holds explicit grants, and `staff_permission_keys()`
  is the one function that decides what a caller holds (owner = everything;
  active staff = baseline + their two legacy flags + grants; anyone else =
  nothing). `get_my_staff_context()` returns that list plus
  `authorized_branches`, so the app displays exactly what the server computed.
- **Audit log**: `staff_audit_logs` is append-only (no client INSERT/UPDATE/DELETE,
  and a trigger blocks changes even for privileged roles). Rows arrive through
  `staff_log_audit(...)`, which derives the actor and branch from the verified
  token. Server RPCs written in later batches call the internal `_write_audit`.
- **Local SQLite** (`melai_staff.db`, `lib/core/services/sqlite_service.dart`)
  holds the offline staff context cache and the sync queue. It is a cache, never
  an authority. On Linux/Windows desktop it needs the platform `sqlite3`
  library; Android/iOS use the sqflite plugin; on web it is unavailable and the
  app simply has no offline staff cache.

## Payments (COD + HitPay)

Checkout offers, depending on the fulfillment method:

- **Online Payment (GCash, Maya, Card)**: always available. The order is placed first, then the customer pays on HitPay's hosted checkout (PHP). The payment becomes `success` only when HitPay's signed webhook reaches the `hitpay-webhook` Edge Function; the app just shows the live status.
- **Cash on Delivery**: delivery orders only. The customer pays the rider; staff press "Confirm Cash Received".
- **Cash on Counter Pickup**: pickup orders only; staff confirm the cash at the counter.

Setup: apply `supabase/migrations/20261007010000_cod_and_hitpay.sql`, then follow
[`supabase/functions/README.md`](supabase/functions/README.md) to create the HitPay
account, set the secrets (`HITPAY_API_KEY`, `HITPAY_SALT`, `HITPAY_ENV`,
`HITPAY_REDIRECT_URL`) and deploy `hitpay-create-payment` and `hitpay-webhook`.
No payment secrets are ever stored in the app.
