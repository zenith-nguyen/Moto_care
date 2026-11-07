# Tasks

## 1. Decide the shape first

- [ ] 1.1 Confirm with the owner that a second inbound payment per order is wanted, rather than cancelling and re-quoting.
- [ ] 1.2 Decide whether a refund adjustment is settled by hand, as in `add-live-refund-settlement`, or waits for that change to land first.

## 2. Inbound settlement of a charge adjustment

- [ ] 2.1 Issue transfer instructions for an open charge adjustment, with its own unique payment code, reusing the existing instruction and QR path.
- [ ] 2.2 Extend webhook matching so a notification can settle an adjustment as well as a prepayment, keeping every existing guard: receiving account, direction, exact amount, at-most-once per bank transaction.
- [ ] 2.3 Keep one open payable per order at a time, so a transfer can never be ambiguous between the prepayment and the adjustment.

## 3. Completion and credit

- [ ] 3.1 On settlement, move the order from `AWAITING_PAYMENT` to `PAID` through the existing transition guard.
- [ ] 3.2 Replace the provider-credit condition that requires a simulated adjustment with one that requires a settled adjustment, whatever its origin.
- [ ] 3.3 Verify the reconciliation flags still read correctly for a live-settled adjustment.

## 4. Verification

- [ ] 4.1 Database test, production-like configuration: approve a higher final price, settle it by webhook, assert the order completes and the mechanic is credited exactly once.
- [ ] 4.2 Database test: the same bank transaction cannot settle both a prepayment and an adjustment.
- [ ] 4.3 Database test: an equal final price still goes straight to paid and completes, unchanged from today.
- [ ] 4.4 Run `npm run lint`, `npm run typecheck`, `npm test`, `npm run test:db` and `flutter test`.

## 5. Close the change

- [ ] 5.1 Fold the delta into `openspec/specs/payments/spec.md` and `openspec/specs/provider-wallet/spec.md`, then archive.
