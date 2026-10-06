/**
 * Firebase Auth blocking functions — required for Supabase RLS to work.
 *
 * Supabase reads the `role` claim of the Firebase ID token to choose the
 * Postgres role for each request. Firebase tokens have NO `role` claim, so
 * without this every request runs as `anon` and the customer RPCs
 * (place_order, sync_customer_cart, request_refund, ...) are refused.
 *
 * SECURITY NOTES
 *  - `role: 'authenticated'` is a *Postgres* role only. It is NOT the app role
 *    (customer/staff/owner/delivery): that lives in Firestore `users/{uid}` and
 *    is enforced by firestore.rules. Never put an app role in this claim.
 *  - A client cannot set its own custom claims; only these functions / the
 *    Admin SDK can.
 *  - Staff/owner/delivery accounts also receive it. That is harmless: every
 *    customer policy is scoped to the caller's own firebase_uid.
 *
 * Requires: Firebase Authentication upgraded to Identity Platform (blocking
 * functions are not available otherwise) and the Blaze plan.
 *
 * Deploy:  cd functions && npm install && cd .. && firebase deploy --only functions
 * Then run functions/backfill-role-claim.js ONCE for users created earlier.
 */
const { beforeUserCreated, beforeUserSignedIn } = require('firebase-functions/v2/identity');

const claims = { role: 'authenticated' };

exports.supabaseRoleOnCreate = beforeUserCreated(() => ({ customClaims: claims }));
exports.supabaseRoleOnSignIn = beforeUserSignedIn(() => ({ customClaims: claims }));
