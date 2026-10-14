# Flutter Admin integration

This document is the UI handoff contract for the Admin role. The Flutter layer
does not calculate financial totals or infer a successful decision. PostgreSQL
data returned by the backend is the source of truth.

## Entry points

- `adminDashboardControllerProvider`: analytics and reconciliation.
- `adminOperationsControllerProvider`: operational queues and decisions.
- `adminRepositoryProvider`: typed REST adapter used by both controllers.

Widgets should watch controller state and invoke controller methods. They must
not call Dio, construct endpoint paths, parse JSON, or store access tokens.

## Dashboard and reconciliation

`AdminDashboardState` exposes:

- `summary`: user/provider/order counts and current financial totals.
- `timeseries`: daily created/completed orders, collections, provider
  settlements, refunds, and withdrawals.
- `reconciliation`: paginated order/payment/wallet comparison rows.
- `paymentFilter`: the active server-side payment-status filter.
- `action`, `isBusy`, and `lastFailure`: UI progress and safe error display.

Use `changePeriod(from:, to:)` for an inclusive UI date selection converted to
an exact UTC interval by the caller. A period must be ordered and no longer than
366 days. Use `changeReconciliation(paymentStatus:, page:)` for payment filters
and pagination. Passing `null` clears the payment filter.

All money values are `MoneyAmount` decimal strings. Do not convert them to
`double`. `sandboxOnly=true` must remain visible on demo finance screens.

### Reconciliation flags

Each row can include one or more typed flags:

- completed order without a paid payment;
- payment/final-price mismatch;
- provider wallet-credit mismatch;
- order/payment refund-status mismatch;
- refunded order that still has wallet credit;
- multiple payments for one order;
- adjustment-status mismatch.

Show these as warning chips and provide order/payment details. A warning is not
itself permission to mutate data; an Admin must use the matching operation.

## Operational queues

`AdminOperationsState` exposes recent orders and five pending queues:

1. Provider applications.
2. Full sandbox refunds.
3. Final-price disputes.
4. Sandbox refund adjustments.
5. Provider withdrawals.

Supported controller actions:

- `reviewProvider`: approve or reject a provider.
- `refundFullOrder`: complete a full demo refund.
- `resolvePriceDispute`: approve or reject a disputed final price with reason.
- `refundAdjustment`: settle a pending demo refund adjustment.
- `resolveWithdrawal`: approve or reject a sandbox withdrawal.

`actionTargetId` identifies the row currently being processed. Disable both
decision buttons for that row while busy and require a confirmation dialog for
all financial actions.

## Safety rules for UI

- These decisions are not automatically retried. On timeout or disconnect,
  refresh the queue before the Admin acts again.
- Rejection reasons are required for withdrawals; price-dispute reasons are
  always required. The repository trims and validates them.
- Never optimistically remove a queue row before the server succeeds.
- Never display raw backend exceptions, access tokens, webhook secrets, email
  credentials, or request bodies.
- Provider documents and chat images may require authenticated download; do not
  place JWT values in URLs.
- The current payment/refund/withdrawal implementation is sandbox-only. Do not
  label it as bank settlement or production SePay.

## Suggested Admin navigation

1. Overview: KPI cards and daily chart.
2. Orders: recent orders and status filters.
3. Reconciliation: paginated rows and anomaly flags.
4. Provider approvals.
5. Price disputes and refunds.
6. Withdrawal approvals.

The UX/UI team may change layout and visual design, but should preserve these
controller boundaries and confirmation/error behavior.

## Test handoff

Before merging Admin UI:

1. Test empty, loading, error, and populated states for every queue.
2. Verify repeated taps cannot send duplicate decisions.
3. Verify a timeout leads to refresh, not automatic retry.
4. Verify decimal money formatting and the sandbox label.
5. Run three-role E2E against an isolated demo database before release APK.
