# Supabase Edge Functions: HitPay online payments

| Function | Called by | Purpose |
| --- | --- | --- |
| `hitpay-create-payment` | the app (customer) | Creates (or reuses) a HitPay hosted-checkout link for an order and returns its URL. The amount is read from the database, never from the app. |
| `hitpay-webhook` | HitPay | Verifies the signed event, checks the amount, and marks the payment `success` / `failed`. |

Cash on Delivery and Cash on Counter Pickup do not use these functions.

## 1. Apply the database migration

Run `supabase/migrations/20261007010000_cod_and_hitpay.sql` (it is idempotent) with `supabase db push` or the SQL editor.

## 2. HitPay account (sandbox first)

1. Create a sandbox account at https://dashboard.sandbox.hit-pay.com (the live one is https://dashboard.hit-pay.com).
2. Set the business currency/country to the Philippines (PHP) and, under Payment Methods, enable what your account offers (GCash, Maya, cards). The hosted page shows only the methods enabled on the account; the sandbox may offer fewer methods than live.
3. Developers > API Keys: copy the **API Key**.
4. Developers > Webhook Endpoints > add an endpoint:
   - URL: `https://<project-ref>.supabase.co/functions/v1/hitpay-webhook`
   - Events: `payment_request.completed` and `payment_request.failed`
   - Copy that endpoint's **Salt**. It is the webhook's own salt, not the API-key salt.

## 3. Secrets and deploy

```bash
supabase secrets set \
  HITPAY_API_KEY=<api key> \
  HITPAY_SALT=<webhook endpoint salt> \
  HITPAY_ENV=sandbox \
  HITPAY_REDIRECT_URL=<page shown after paying, https only>

supabase functions deploy hitpay-webhook --no-verify-jwt
supabase functions deploy hitpay-create-payment --no-verify-jwt
```

- `HITPAY_ENV=live` switches to `https://api.hit-pay.com`; anything else uses the sandbox. Use the API key and webhook salt of the same environment.
- `hitpay-webhook` must use `--no-verify-jwt` because HitPay sends no Supabase token; the `Hitpay-Signature` check is its authentication.
- `hitpay-create-payment` is deployed with `--no-verify-jwt` too because the app signs in with Firebase tokens. The function still authenticates the caller itself: it reads the order with the caller's token, so only the order's owner can get a link.
- `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are provided by Supabase automatically.

## 4. Test the flow

1. In the app, add items, choose **Online Payment (GCash, Maya, Card)**, and place the order. The HitPay page opens in the browser.
2. Pay with a HitPay sandbox test method (see HitPay's sandbox docs for test card numbers).
3. Return to the app. The payment screen should change to **Paid** within a few seconds.
4. If it stays on "Waiting for payment", check the webhook delivery log in the HitPay dashboard and `supabase functions logs hitpay-webhook`. A `401` means the salt is wrong.
5. Also test **Cash on Delivery** (only offered for delivery) and **Cash on Counter Pickup** (only offered for pickup); neither opens HitPay.
