# Tasks

## 1. Record the settlement

- [ ] 1.1 Add a bank reference and a settled-at column to the payment record, with a unique constraint on the reference so the same transfer cannot be recorded twice. Write the migration; do not change existing rows.
- [ ] 1.2 Add an administrator-only endpoint that settles one payment in `REFUND_PENDING`, taking the bank reference and an optional note.
- [ ] 1.3 In one transaction: set the payment to `REFUNDED` with its reference and time, then move the order to `REFUNDED` through the existing transition guard. If the guard refuses, fail the whole request.
- [ ] 1.4 Return the unchanged current state when the same payment and reference arrive again, and 409 when the reference belongs to another payment or the payment is in any other state.

## 2. Keep the queue and the figures honest

- [ ] 2.1 Confirm the pending refund queue reads only `REFUND_PENDING`, so a settled refund leaves it without further change.
- [ ] 2.2 Confirm the reconciliation refund figures and the "payment refund pending but order is not" flag clear once both rows are `REFUNDED`.
- [ ] 2.3 Notify the customer on settlement, reusing the existing order-status notification rather than adding a channel.

## 3. Admin surface

- [ ] 3.1 In the admin refund queue, let an administrator enter the bank reference and settle the refund.
- [ ] 3.2 Show the reference and the settlement time on a refund that is already settled, so the screen is a record and not only an action.

## 4. Verification

- [ ] 4.1 Database test: pay, cancel, settle, and assert both payment and order reach `REFUNDED` and the queue is empty.
- [ ] 4.2 Database test: settling twice with the same reference changes nothing and returns the same state; a reference already used by another payment is rejected with 409.
- [ ] 4.3 Database test: settling a payment that is not `REFUND_PENDING` is rejected with 409.
- [ ] 4.4 Test that a non-administrator cannot reach the endpoint.
- [ ] 4.5 Run `npm run lint`, `npm run typecheck`, `npm test`, `npm run test:db` and `flutter test` before opening the pull request.

## 5. Close the change

- [ ] 5.1 Fold the delta in `specs/payments/spec.md` into `openspec/specs/payments/spec.md` and archive this change.
- [ ] 5.2 Note in the payments spec that outbound transfers remain manual, so the next reader does not mistake settlement for an automated payout.
