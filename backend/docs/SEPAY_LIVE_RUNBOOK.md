# SePay Live collection runbook

Live mode accepts real bank transfers. It is intentionally disabled until every
production safeguard and external SePay prerequisite is present.

## Supported boundary

- Generate an exact-amount VietQR instruction for an order prepayment.
- Receive SePay HMAC-SHA256 webhooks over the raw request body.
- Reject stale, forged, duplicate, wrong-account, wrong-code and wrong-amount events.
- Mark one pending prepayment paid exactly once and start provider matching.

This does **not** claim bank escrow. Funds arrive in the configured bank account.
Automated refunds, outgoing provider payouts and periodic SePay API reconciliation
are not enabled by this switch. Keep those Admin workflows manual and audited until
the bank account is eligible and their separate adapters are implemented.

## External prerequisites

1. Link the project bank account at `my.sepay.vn`.
2. Expose the API through a stable public HTTPS URL.
3. Create a money-in webhook for
   `https://<public-origin>/payments/webhooks/sepay`.
4. Select HMAC-SHA256, copy the secret once into the untracked server `.env`,
   enable payment-code filtering for the configured prefix, and enable retries/alerts.
5. Never paste the bank account, HMAC secret or API token into chat, issues or Git.

## Required production environment

```dotenv
NODE_ENV=production
DEMO_MODE=false
PUBLIC_BASE_URL=https://<public-origin>
SEPAY_ENABLED=true
SEPAY_MODE=live
SEPAY_BANK=<official-bank-short-name>
SEPAY_ACCOUNT_NUMBER=<linked-bank-account>
SEPAY_ACCOUNT_HOLDER=<account-holder>
SEPAY_PAYMENT_CODE_PREFIX=MC
SEPAY_TRANSFER_MEMO_PREFIX=
SEPAY_WEBHOOK_SECRET=<random-secret-configured-in-sepay>
SEPAY_WEBHOOK_MAX_AGE_SECONDS=300
SEPAY_LIVE_CONFIRMATION=I_UNDERSTAND_THIS_ACCEPTS_REAL_MONEY
```

Production also requires the database, JWT, order-start and password-reset secrets
defined in `.env.example`. Startup fails when the Live safeguards are incomplete.

## Go-live verification

1. Back up the production database and verify `/health/ready` over HTTPS.
2. Create a low-value order owned by a dedicated test customer.
3. Confirm the QR account, exact amount and `MC<paymentId>` content before paying.
4. Transfer once and verify one webhook audit row, one paid payment and one matching transition.
5. Replay the same webhook and verify it does not apply money twice.
6. Send a signed wrong-amount fixture and verify the order remains unpaid.
7. Revert to `SEPAY_ENABLED=false` immediately if any account/code/amount differs.

Official references:

- https://developer.sepay.vn/en/sepay-webhooks/xac-thuc
- https://developer.sepay.vn/en/sepay-webhooks/bao-mat
- https://developer.sepay.vn/en/sepay-webhooks/tao-qr-va-form-thanh-toan
