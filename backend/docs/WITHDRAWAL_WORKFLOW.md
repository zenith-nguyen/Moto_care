# Revo — withdrawal and payout workflow

Updated: 2026-10-18.

The wallet ledger, withdrawal approval and bank payout reconciliation are separate
states. `APPROVED` means Revo approved and debited the provider wallet; only payout
status `RECONCILED` means an Admin verified the external bank transfer.

## Provider flow

1. `GET /wallets/me` returns wallet balance, locked balance and available balance.
2. `POST /withdrawals` with `{ "amount": "50000.00" }` reserves available funds.
3. `GET /withdrawals/me` returns the request plus its payout status when approved.

The database locks the provider wallet, permits only one pending request per provider,
and prevents more than one debit for a withdrawal.

## Admin approval

1. `GET /admin/withdrawals/pending` lists pending requests FIFO.
2. `PATCH /admin/withdrawals/:requestId/resolve` approves or rejects.
3. Approval releases the reservation, debits the wallet once, and creates payout code
   `RP<withdrawalId>` in `AWAITING_TRANSFER`.
4. Rejection releases the reservation without a debit.

Approval does not call a bank and must not be displayed as “money transferred”.

## Real manual bank transfer

1. Admin opens `GET /admin/withdrawal-payouts/pending`.
2. Admin transfers the exact amount in the banking app and includes the `RP...` code.
3. Admin verifies recipient name/account and bank receipt.
4. Admin calls `PATCH /admin/withdrawal-payouts/:payoutId/reconcile`:

```json
{
  "decision": "CONFIRM",
  "externalTransactionId": "bank-transaction-id",
  "referenceCode": "bank-reference",
  "observedAmount": "50000.00",
  "reason": "Recipient and bank receipt verified"
}
```

A mismatched amount is rejected. Suspicious payouts use `decision=FLAG` with a reason.
All confirmations are idempotent and retain the Admin ID and timestamp.

## Optional outgoing webhook

`POST /payments/webhooks/sepay/payouts` has a separate HMAC secret and audit table.
It can record an eligible bank’s outgoing transaction, but always leaves it in
`MANUAL_REVIEW` because SePay’s payload does not prove the intended recipient.

The linked MBBank account does not support SePay outgoing webhooks. Keep the payout
webhook disabled and use manual bank transfer reconciliation. See
[PAYOUT_RECONCILIATION.md](PAYOUT_RECONCILIATION.md).
