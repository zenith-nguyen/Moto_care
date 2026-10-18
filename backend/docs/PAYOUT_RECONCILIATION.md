# Provider payout reconciliation

Updated: 2026-10-18.

This workflow records and audits real manual bank transfers to providers. It does not
initiate a transfer, store banking credentials, or treat a SePay outgoing webhook as
proof that the intended recipient was paid.

## State model

1. A provider submits `POST /withdrawals`; wallet funds are reserved.
2. Admin approves through `PATCH /admin/withdrawals/:requestId/resolve`.
3. The wallet is debited once and one payout is created with code `RP<withdrawalId>`
   and status `AWAITING_TRANSFER`.
4. Admin transfers the exact amount in the banking app using the payout code.
5. If an eligible bank sends an outgoing webhook, the backend authenticates it with a
   separate HMAC secret and records it as `MANUAL_REVIEW`. It does not auto-confirm.
6. Admin checks recipient, amount, payout code and bank receipt, then calls
   `PATCH /admin/withdrawal-payouts/:payoutId/reconcile` with `decision=CONFIRM`.
7. Only an exact amount can become `RECONCILED`. A suspicious transaction is flagged
   with `decision=FLAG` and remains in manual review.

## API boundary

- `GET /admin/withdrawal-payouts/pending`: FIFO payout review queue.
- `PATCH /admin/withdrawal-payouts/:payoutId/reconcile`: Admin confirmation/flag.
- `POST /payments/webhooks/sepay/payouts`: optional outgoing webhook, separate HMAC.

The payout webhook has its own unique external transaction ID table and payload hash.
Replays are idempotent. Wrong account, direction, code and amount are audited. This
endpoint never reads or updates an order or customer payment.

## MBBank limitation

The linked Revo account is MBBank. SePay currently lists MBBank for incoming webhooks,
not outgoing webhooks. Keep this disabled:

```dotenv
SEPAY_PAYOUT_RECONCILIATION_ENABLED=false
```

Use the Admin manual transfer and confirmation flow. If the project later moves payouts
to a supported bank/account mode, use a different secret from `SEPAY_WEBHOOK_SECRET`:

```dotenv
SEPAY_PAYOUT_RECONCILIATION_ENABLED=true
SEPAY_PAYOUT_SOURCE_ACCOUNT=<source-account>
SEPAY_PAYOUT_CODE_PREFIX=RP
SEPAY_PAYOUT_WEBHOOK_SECRET=<separate-random-secret>
SEPAY_PAYOUT_WEBHOOK_MAX_AGE_SECONDS=300
```

Official references:

- https://developer.sepay.vn/vi/sepay-webhooks/tai-khoan-ngan-hang
- https://developer.sepay.vn/vi/sepay-webhooks/tao-webhook
- https://developer.sepay.vn/vi/sepay-webhooks/xac-thuc
- https://developer.sepay.vn/vi/sepay-webhooks/tich-hop-webhook
