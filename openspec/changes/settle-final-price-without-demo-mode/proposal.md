# Settle a changed final price outside demo mode

## Why

Specifying the payment capability surfaced a dead end that only appears in
production. Two facts combine badly:

1. A mechanic may propose a final price that differs from the prepayment. When
   the customer approves it, the order moves to `AWAITING_PAYMENT` and an
   adjustment is created for the difference. When the approved price equals the
   prepayment, the order goes straight to `PAID` and is unaffected by any of
   this.
2. The only code that settles an adjustment is the demo settlement path, which
   refuses to run when the service is in production or when demo mode is off.
   Live mode forces demo mode off, so in production nothing can settle an
   adjustment.

The status machine allows `AWAITING_PAYMENT` to move only to `PAID`, and only
settlement performs that move. The mechanic's earnings are credited only after
the order completes. So on a live deployment:

- an order whose approved final price differs from the prepayment can never be
  completed;
- the mechanic who did that job is never credited for it;
- the customer is left owing or owed a difference the system cannot record.

The same gate sits on refunds: a prepayment paid by real bank transfer cannot be
moved to refunded at all, which is the gap recorded separately in
`add-live-refund-settlement`.

This is the most consequential gap the specification work found. It is written
down rather than fixed here because it touches the money path, where this
project requires a human decision.

## What changes

Give the settlement of a final-price difference a path that works in
production, without introducing any automatic outbound transfer.

- A charge adjustment, where the customer owes more, is settled by the same
  mechanism that settles the prepayment: instructions carrying a unique payment
  code, and a verified bank-transfer notification that confirms it.
- A refund adjustment, where the customer is owed money back, is recorded as
  settled by an administrator who performed the transfer, exactly as proposed
  for refunds in `add-live-refund-settlement`.
- Settling the adjustment moves the order from `AWAITING_PAYMENT` to `PAID`, and
  completion then credits the mechanic as it does today.
- The provider credit stops requiring the adjustment to be a simulated one, and
  instead requires it to be settled.

## Out of scope

- Any automatic transfer of money out of the account. Outbound money stays
  manual and human-approved.
- Changing who may propose or approve a final price, or the dispute flow.
- Partial settlement of an adjustment.

## Money impact

This changes which payments can be received and which orders can complete. It
adds an inbound settlement path for an amount the customer already approved, and
a recorded, manual outbound one. It must not be implemented without reviewing
the webhook matching rules alongside it, since a second payable amount per order
is new: the existing rules assume one prepayment per order.
